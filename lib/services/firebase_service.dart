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
      int currentTurn = data['currentTurn'];

      // 1. Find the player who is leaving
      int playerIndex = players.indexWhere((p) => p['id'] == userId);
      if (playerIndex == -1) return;

      // 2. Mark them as "Left" (Don't delete them, just mark flag)
      players[playerIndex]['hasLeft'] = true;

      // 3. CRITICAL: If it was their turn, pass it to the next active player
      // Ensure this block is in your leaveGame function in FirebaseService
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

      // 4. Update Database
      transaction.update(docRef, {
        'players': players,
        'currentTurn': currentTurn, // Updates turn so game continues
        'diceValue': 0, // Reset dice
      });
    });
  }
}