import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/game_model.dart';

class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 1. Create Game (Now accepts playerName)
  Future<String> createGame(String userId, String playerName) async {
    String gameId = const Uuid().v4().substring(0, 6).toUpperCase();

    await _db.collection('games').doc(gameId).set({
      'status': 'waiting',
      'currentTurn': 0,
      'diceValue': 0,
      'diceRolledBy': '',
      'players': [
        {
          'id': userId,
          'color': 'Red',
          'name': playerName, // <--- SAVING NAME
          'isAuto': false
        }
      ],
      'tokens': {
        'Red': [0, 0, 0, 0],
        'Green': [0, 0, 0, 0],
        'Yellow': [0, 0, 0, 0],
        'Blue': [0, 0, 0, 0]
      }
    });
    return gameId;
  }

  // 2. Join Game (Now accepts playerName)
  Future<void> joinGame(String gameId, String userId, String playerName) async {
    DocumentSnapshot doc = await _db.collection('games').doc(gameId).get();

    if (!doc.exists) throw Exception("Game not found");

    List players = doc['players'];

    // Check if already joined
    bool alreadyJoined = players.any((p) => p['id'] == userId);
    if (alreadyJoined) return;

    if (players.length >= 4) throw Exception("Game is full");

    List<String> colors = ['Red', 'Green', 'Yellow', 'Blue'];
    String nextColor = colors[players.length];

    await _db.collection('games').doc(gameId).update({
      'players': FieldValue.arrayUnion([
        {
          'id': userId,
          'color': nextColor,
          'name': playerName, // <--- THIS SAVES IT TO THE CLOUD
          'isAuto': false
        }
      ])
    });
  }

  // ... (Keep streamGame and updateGameState as they were) ...
  Stream<GameModel> streamGame(String gameId) {
    return _db.collection('games').doc(gameId).snapshots().map((snapshot) {
      return GameModel.fromJson(snapshot.data()!, snapshot.id);
    });
  }

  Future<void> updateGameState(String gameId, Map<String, dynamic> data) async {
    await _db.collection('games').doc(gameId).update(data);
  }

  Future<void> leaveGame(String gameId, String userId) async {
    DocumentReference docRef = _db.collection('games').doc(gameId);

    await _db.runTransaction((transaction) async {
      DocumentSnapshot snapshot = await transaction.get(docRef);
      if (!snapshot.exists) return;

      Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
      List players = List.from(data['players']);
      Map<String, dynamic> tokens = Map.from(data['tokens']); // Get tokens
      int currentTurn = data['currentTurn'];

      // 1. Find the player
      int playerIndex = players.indexWhere((p) => p['id'] == userId);
      if (playerIndex == -1) return;

      // 2. Mark as Left
      players[playerIndex]['hasLeft'] = true;

      // 3. RESET TOKENS TO HOME (This triggers the animation)
      String color = players[playerIndex]['color'];
      tokens[color] = [0, 0, 0, 0]; // Send all 4 tokens back to start

      // 4. Pass Turn if needed
      if (currentTurn == playerIndex) {
        int nextTurn = currentTurn;
        for (int i = 0; i < players.length; i++) {
          nextTurn = (nextTurn + 1) % players.length;
          if (players[nextTurn]['hasLeft'] != true) {
            currentTurn = nextTurn;
            break;
          }
        }
      }

      // 5. Update Database
      transaction.update(docRef, {
        'players': players,
        'tokens': tokens, // Save the reset tokens
        'currentTurn': currentTurn,
        'diceValue': 0,
      });
    });
  }
}