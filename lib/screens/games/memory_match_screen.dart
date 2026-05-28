import 'package:arcade_aura/services/room_service.dart';
import 'package:arcade_aura/services/trophy_service.dart';
import 'package:arcade_aura/utils/game_logic.dart';
import 'package:arcade_aura/widgets/gradient_scaffold.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MemoryMatchScreen extends StatelessWidget {
  const MemoryMatchScreen({super.key, required this.roomId});
  final String roomId;

  Future<void> _finish(Map<String, dynamic> data, String winnerUid, bool draw) async {
    final players = List<String>.from(data['players'] ?? const []);
    final done = await RoomService.instance.finishRoom(roomId: roomId, winnerUid: winnerUid, isDraw: draw);
    if (done) {
      await TrophyService.instance.applyResult(
        roomId: roomId,
        gameType: 'memory_match',
        players: players,
        winnerUid: winnerUid,
        isDraw: draw,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return GradientScaffold(
      appBar: AppBar(title: const Text('Memory Match')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: RoomService.instance.roomStream(roomId),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final data = snap.data!.data() ?? {};
          final players = List<String>.from(data['players'] ?? const []);
          if (players.length < 2) return const Center(child: Text('Waiting for second player...'));
          final turnUid = data['turnUid'] ?? players.first;
          final status = data['status'] ?? 'playing';
          final md = Map<String, dynamic>.from(data['matchData'] ?? {});
          final deck = List<String>.from(md['deck'] ?? GameLogic.shuffledMemoryDeck());
          final revealed = List<int>.from(md['revealed'] ?? []);
          final matched = List<int>.from(md['matched'] ?? []);
          final picks = List<int>.from(md['picks'] ?? []);
          final scores = Map<String, dynamic>.from(md['scores'] ?? {players.first: 0, players.last: 0});
          final deadline = (md['deadlineMs'] ?? DateTime.now().millisecondsSinceEpoch + 30000) as int;

          if (md.isEmpty) {
            RoomService.instance.updateState(roomId, {
              'matchData': {
                'deck': deck,
                'revealed': <int>[],
                'matched': <int>[],
                'picks': <int>[],
                'scores': scores,
                'deadlineMs': deadline,
              },
            });
          }

          if (status != 'finished' && matched.length == deck.length) {
            final a = scores[players.first] as int;
            final b = scores[players.last] as int;
            if (a == b) {
              _finish(data, '', true);
            } else {
              _finish(data, a > b ? players.first : players.last, false);
            }
          }

          return Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Text('Turn: ${turnUid == uid ? 'You' : 'Opponent'} • Time: ${((deadline - DateTime.now().millisecondsSinceEpoch) / 1000).ceil().clamp(0, 30)}s'),
                const SizedBox(height: 8),
                Text('Score ${scores[players.first]} : ${scores[players.last]}'),
                const SizedBox(height: 8),
                Expanded(
                  child: GridView.builder(
                    itemCount: deck.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4),
                    itemBuilder: (_, i) {
                      final open = revealed.contains(i) || matched.contains(i) || picks.contains(i);
                      return GestureDetector(
                        onTap: () async {
                          if (status == 'finished' || turnUid != uid || open || picks.length >= 2) return;
                          final newPicks = [...picks, i];
                          if (newPicks.length == 2) {
                            final first = newPicks.first;
                            final second = newPicks.last;
                            if (deck[first] == deck[second]) {
                              scores[uid] = (scores[uid] ?? 0) + 1;
                              await RoomService.instance.updateState(roomId, {
                                'matchData': {
                                  'deck': deck,
                                  'revealed': revealed,
                                  'matched': [...matched, first, second],
                                  'picks': <int>[],
                                  'scores': scores,
                                  'deadlineMs': DateTime.now().millisecondsSinceEpoch + 30000,
                                }
                              });
                            } else {
                              await RoomService.instance.updateState(roomId, {
                                'turnUid': players.first == uid ? players.last : players.first,
                                'matchData': {
                                  'deck': deck,
                                  'revealed': revealed,
                                  'matched': matched,
                                  'picks': <int>[],
                                  'scores': scores,
                                  'deadlineMs': DateTime.now().millisecondsSinceEpoch + 30000,
                                }
                              });
                            }
                          } else {
                            await RoomService.instance.updateState(roomId, {
                              'matchData': {
                                'deck': deck,
                                'revealed': revealed,
                                'matched': matched,
                                'picks': newPicks,
                                'scores': scores,
                                'deadlineMs': deadline,
                              }
                            });
                          }
                        },
                        child: Card(
                          child: Center(
                            child: Text(open ? deck[i] : '?', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
