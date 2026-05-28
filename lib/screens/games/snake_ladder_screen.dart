import 'dart:math';

import 'package:arcade_aura/services/room_service.dart';
import 'package:arcade_aura/services/trophy_service.dart';
import 'package:arcade_aura/utils/game_logic.dart';
import 'package:arcade_aura/widgets/gradient_scaffold.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SnakeLadderScreen extends StatelessWidget {
  const SnakeLadderScreen({super.key, required this.roomId});
  final String roomId;

  Future<void> _finish(Map<String, dynamic> data, String winnerUid) async {
    final players = List<String>.from(data['players'] ?? const []);
    final done = await RoomService.instance.finishRoom(roomId: roomId, winnerUid: winnerUid, isDraw: false);
    if (done) {
      await TrophyService.instance.applyResult(
        roomId: roomId,
        gameType: 'snake_ladder',
        players: players,
        winnerUid: winnerUid,
        isDraw: false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return GradientScaffold(
      appBar: AppBar(title: Text('Snake & Ladder • $roomId')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: RoomService.instance.roomStream(roomId),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final data = snap.data!.data() ?? {};
          final players = List<String>.from(data['players'] ?? const []);
          if (players.length < 2) return const Center(child: Text('Waiting for second player...'));
          final turnUid = data['turnUid'] ?? players.first;
          final md = Map<String, dynamic>.from(data['matchData'] ?? {});
          final positions = Map<String, dynamic>.from(md['positions'] ?? {players.first: 1, players.last: 1});
          final dice = (md['lastDice'] ?? 0) as int;
          final status = data['status'] ?? 'playing';

          if (md.isEmpty) {
            RoomService.instance.updateState(roomId, {
              'matchData': {'positions': positions, 'lastDice': 0}
            });
          }

          for (final p in players) {
            if ((positions[p] ?? 1) >= 30 && status != 'finished') {
              _finish(data, p);
            }
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Dice: $dice'),
                Text('You are at ${positions[uid]}'),
                Text('Opponent at ${positions[players.first == uid ? players.last : players.first]}'),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: status == 'finished' || turnUid != uid
                      ? null
                      : () {
                          final roll = Random().nextInt(6) + 1;
                          final next = GameLogic.snakeLadderNextPos((positions[uid] ?? 1) as int, roll);
                          positions[uid] = next;
                          RoomService.instance.updateState(roomId, {
                            'turnUid': players.first == uid ? players.last : players.first,
                            'matchData': {'positions': positions, 'lastDice': roll}
                          });
                        },
                  icon: const Icon(Icons.casino),
                  label: Text(turnUid == uid ? 'Roll Dice' : 'Opponent Turn'),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: GridView.builder(
                    itemCount: 30,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5),
                    itemBuilder: (_, i) {
                      final n = 30 - i;
                      final meHere = positions[uid] == n;
                      final oppHere = positions[players.first == uid ? players.last : players.first] == n;
                      return Card(
                        child: Center(
                          child: Text(
                            '$n${meHere ? ' 🔵' : ''}${oppHere ? ' 🔴' : ''}',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
