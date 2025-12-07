import 'package:equatable/equatable.dart';

class GameModel extends Equatable {
  final String gameId;
  final String status; // 'waiting', 'playing', 'finished'
  final int currentTurn; // Index of player in the list
  final int diceValue;
  final String? diceRolledBy; // ID of who rolled the dice
  final Map<String, List<int>> tokens; // {'Red': [0,0,0,0], 'Green': ...}
  final List<Map<String, dynamic>> players; // [{'id': '...', 'color': 'Red', ...}]

  const GameModel({
    required this.gameId,
    required this.status,
    required this.currentTurn,
    required this.diceValue,
    this.diceRolledBy,
    required this.tokens,
    required this.players,
  });

  // --- 1. FROM JSON (Fixes your Error) ---
  factory GameModel.fromJson(Map<String, dynamic> json, String id) {
    // Safely convert the 'tokens' map from dynamic to List<int>
    Map<String, List<int>> parsedTokens = {};
    if (json['tokens'] != null) {
      Map<String, dynamic> tokensMap = json['tokens'] as Map<String, dynamic>;
      tokensMap.forEach((key, value) {
        parsedTokens[key] = List<int>.from(value);
      });
    }

    return GameModel(
      gameId: id,
      status: json['status'] ?? 'waiting',
      currentTurn: json['currentTurn'] ?? 0,
      diceValue: json['diceValue'] ?? 0,
      diceRolledBy: json['diceRolledBy'],
      tokens: parsedTokens,
      players: List<Map<String, dynamic>>.from(json['players'] ?? []),
    );
  }

  // --- 2. TO JSON (Required for saving to Firebase) ---
  Map<String, dynamic> toJson() {
    return {
      'gameId': gameId,
      'status': status,
      'currentTurn': currentTurn,
      'diceValue': diceValue,
      'diceRolledBy': diceRolledBy,
      'tokens': tokens,
      'players': players,
    };
  }

  // --- 3. COPY WITH (Required for State Updates) ---
  GameModel copyWith({
    String? gameId,
    String? status,
    int? currentTurn,
    int? diceValue,
    String? diceRolledBy,
    Map<String, List<int>>? tokens,
    List<Map<String, dynamic>>? players,
  }) {
    return GameModel(
      gameId: gameId ?? this.gameId,
      status: status ?? this.status,
      currentTurn: currentTurn ?? this.currentTurn,
      diceValue: diceValue ?? this.diceValue,
      diceRolledBy: diceRolledBy ?? this.diceRolledBy,
      tokens: tokens ?? this.tokens,
      players: players ?? this.players,
    );
  }

  @override
  List<Object?> get props => [
    gameId,
    status,
    currentTurn,
    diceValue,
    diceRolledBy,
    tokens,
    players
  ];
}