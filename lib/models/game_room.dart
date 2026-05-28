import 'package:cloud_firestore/cloud_firestore.dart';

class GameRoom {
  const GameRoom({
    required this.id,
    required this.gameType,
    required this.players,
    required this.playerNames,
    required this.status,
    required this.turnUid,
    required this.winnerUid,
    required this.board,
    required this.moveCount,
    required this.matchData,
    required this.updatedAt,
  });

  final String id;
  final String gameType;
  final List<String> players;
  final Map<String, dynamic> playerNames;
  final String status;
  final String turnUid;
  final String winnerUid;
  final List<dynamic> board;
  final int moveCount;
  final Map<String, dynamic> matchData;
  final Timestamp? updatedAt;

  factory GameRoom.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return GameRoom(
      id: doc.id,
      gameType: data['gameType'] ?? 'tic_tac_toe',
      players: List<String>.from(data['players'] ?? const []),
      playerNames: Map<String, dynamic>.from(data['playerNames'] ?? const {}),
      status: data['status'] ?? 'waiting',
      turnUid: data['turnUid'] ?? '',
      winnerUid: data['winnerUid'] ?? '',
      board: List<dynamic>.from(data['board'] ?? const []),
      moveCount: data['moveCount'] ?? 0,
      matchData: Map<String, dynamic>.from(data['matchData'] ?? const {}),
      updatedAt: data['updatedAt'],
    );
  }
}
