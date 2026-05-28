import 'package:arcade_aura/services/room_service.dart';
import 'package:arcade_aura/services/trophy_service.dart';
import 'package:arcade_aura/utils/game_logic.dart';
import 'package:arcade_aura/widgets/gradient_scaffold.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class TicTacToeScreen extends StatelessWidget {
  const TicTacToeScreen({super.key, required this.roomId});
  final String roomId;

  Future<void> _complete({required Map<String, dynamic> data, required String winnerSymbol}) async {
    final players = List<String>.from(data['players'] ?? const []);
    if (players.length < 2) return;
    final isDraw = winnerSymbol == 'draw';
    final winnerUid = isDraw ? '' : (winnerSymbol == 'X' ? players.first : players.last);
    final done = await RoomService.instance.finishRoom(roomId: roomId, winnerUid: winnerUid, isDraw: isDraw);
    if (done) {
      await TrophyService.instance.applyResult(
        roomId: roomId,
        gameType: 'tic_tac_toe',
        players: players,
        winnerUid: winnerUid,
        isDraw: isDraw,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser!.uid;
    return GradientScaffold(
      appBar: AppBar(title: Text('Tic Tac Toe • $roomId')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: RoomService.instance.roomStream(roomId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final data = snapshot.data!.data() ?? {};
          final players = List<String>.from(data['players'] ?? const []);
          if (players.length < 2) return const Center(child: Text('Waiting for second player...'));
          final me = players.indexOf(myUid);
          final symbol = me == 0 ? 'X' : 'O';
          final board = List<String>.from(data['board']?.cast<String>() ?? List.filled(9, ''));
          final turnUid = data['turnUid'] ?? players.first;
          final status = data['status'] ?? 'playing';
          final winnerUid = data['winnerUid'] ?? '';

          if (status != 'finished') {
            final winnerSymbol = GameLogic.checkTicTacToeWinner(board);
            if (winnerSymbol.isNotEmpty) {
              _complete(data: data, winnerSymbol: winnerSymbol);
            }
          }

          return Column(
            children: [
              const SizedBox(height: 12),
              Text(status == 'finished'
                  ? winnerUid.isEmpty
                      ? 'Match Draw'
                      : winnerUid == myUid
                          ? 'Victory +3 🏆'
                          : 'Defeat -3 🏆'
                  : turnUid == myUid
                      ? 'Your Turn'
                      : 'Opponent Turn'),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: 9,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
                  itemBuilder: (context, i) {
                    return GestureDetector(
                      onTap: () {
                        if (status == 'finished' || turnUid != myUid || board[i].isNotEmpty) return;
                        board[i] = symbol;
                        RoomService.instance.updateState(roomId, {
                          'board': board,
                          'moveCount': (data['moveCount'] ?? 0) + 1,
                          'turnUid': players.first == myUid ? players.last : players.first,
                          'status': 'playing',
                        });
                      },
                      child: Card(child: Center(child: Text(board[i], style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold)))),
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
