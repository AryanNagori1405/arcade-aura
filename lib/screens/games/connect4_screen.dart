import 'package:arcade_aura/services/room_service.dart';
import 'package:arcade_aura/services/trophy_service.dart';
import 'package:arcade_aura/utils/game_logic.dart';
import 'package:arcade_aura/widgets/gradient_scaffold.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Connect4Screen extends StatelessWidget {
  const Connect4Screen({super.key, required this.roomId});
  final String roomId;

  List<List<String>> _gridFrom(dynamic board) {
    if (board is List && board.length == 6) {
      return board.map<List<String>>((r) => List<String>.from(r as List)).toList();
    }
    return List.generate(6, (_) => List.filled(7, ''));
  }

  Future<void> _complete(Map<String, dynamic> data, String winnerToken) async {
    final players = List<String>.from(data['players'] ?? const []);
    if (players.length < 2) return;
    final isDraw = winnerToken == 'draw';
    final winnerUid = isDraw ? '' : (winnerToken == 'R' ? players.first : players.last);
    final done = await RoomService.instance.finishRoom(roomId: roomId, winnerUid: winnerUid, isDraw: isDraw);
    if (done) {
      await TrophyService.instance.applyResult(
        roomId: roomId,
        gameType: 'connect_4',
        players: players,
        winnerUid: winnerUid,
        isDraw: isDraw,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return GradientScaffold(
      appBar: AppBar(title: Text('Connect 4 • $roomId')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: RoomService.instance.roomStream(roomId),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final data = snap.data!.data() ?? {};
          final players = List<String>.from(data['players'] ?? const []);
          if (players.length < 2) return const Center(child: Text('Waiting for second player...'));
          final myToken = players.first == uid ? 'R' : 'Y';
          final grid = _gridFrom(data['board']);
          final turnUid = data['turnUid'] ?? players.first;
          final status = data['status'] ?? 'playing';

          if (status != 'finished') {
            final result = GameLogic.checkConnect4Winner(grid);
            if (result.isNotEmpty) _complete(data, result);
          }

          return Column(
            children: [
              const SizedBox(height: 8),
              Text(status == 'finished' ? 'Game Finished' : (turnUid == uid ? 'Your Turn' : 'Opponent Turn')),
              Wrap(
                spacing: 4,
                children: List.generate(7, (col) {
                  return TextButton(
                    onPressed: status == 'finished' || turnUid != uid
                        ? null
                        : () {
                            for (var row = 5; row >= 0; row--) {
                              if (grid[row][col].isEmpty) {
                                grid[row][col] = myToken;
                                RoomService.instance.updateState(roomId, {
                                  'board': grid,
                                  'moveCount': (data['moveCount'] ?? 0) + 1,
                                  'turnUid': players.first == uid ? players.last : players.first,
                                });
                                break;
                              }
                            }
                          },
                    child: Text('${col + 1}'),
                  );
                }),
              ),
              Expanded(
                child: GridView.builder(
                  itemCount: 42,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7),
                  itemBuilder: (_, i) {
                    final r = i ~/ 7;
                    final c = i % 7;
                    final token = grid[r][c];
                    return Card(
                      child: Center(
                        child: CircleAvatar(
                          radius: 12,
                          backgroundColor: token == 'R'
                              ? Colors.redAccent
                              : token == 'Y'
                                  ? Colors.amber
                                  : Colors.white10,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
