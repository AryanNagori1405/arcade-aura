import 'package:arcade_aura/services/room_service.dart';
import 'package:arcade_aura/services/trophy_service.dart';
import 'package:arcade_aura/widgets/gradient_scaffold.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class QuizBattleScreen extends StatelessWidget {
  const QuizBattleScreen({super.key, required this.roomId});
  final String roomId;

  static const questions = [
    {
      'q': 'Which widget is immutable in Flutter?',
      'options': ['StatefulWidget', 'StatelessWidget', 'InheritedWidget', 'RenderObject'],
      'answer': 1,
    },
    {
      'q': 'Firestore stores data as?',
      'options': ['Rows', 'Collections & Documents', 'Tables', 'Files'],
      'answer': 1,
    },
    {
      'q': 'Which language is used by Flutter?',
      'options': ['Kotlin', 'Dart', 'Swift', 'Python'],
      'answer': 1,
    },
  ];

  Future<void> _finish(Map<String, dynamic> data, String winnerUid, bool draw) async {
    final players = List<String>.from(data['players'] ?? const []);
    final done = await RoomService.instance.finishRoom(roomId: roomId, winnerUid: winnerUid, isDraw: draw);
    if (done) {
      await TrophyService.instance.applyResult(
        roomId: roomId,
        gameType: 'quiz_battle',
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
      appBar: AppBar(title: const Text('Quiz Battle')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: RoomService.instance.roomStream(roomId),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final data = snap.data!.data() ?? {};
          final players = List<String>.from(data['players'] ?? const []);
          if (players.length < 2) return const Center(child: Text('Waiting for second player...'));

          final status = data['status'] ?? 'playing';
          final md = Map<String, dynamic>.from(data['matchData'] ?? {});
          final qIndex = (md['qIndex'] ?? 0) as int;
          final answers = Map<String, dynamic>.from(md['answers'] ?? {});
          final scores = Map<String, dynamic>.from(md['scores'] ?? {players.first: 0, players.last: 0});
          final deadlineMs = (md['deadlineMs'] ?? (DateTime.now().millisecondsSinceEpoch + 15000)) as int;

          if (md.isEmpty) {
            RoomService.instance.updateState(roomId, {
              'matchData': {
                'qIndex': 0,
                'answers': <String, int>{},
                'scores': scores,
                'deadlineMs': DateTime.now().millisecondsSinceEpoch + 15000,
              }
            });
          }

          if (status != 'finished' && qIndex >= questions.length) {
            final a = scores[players.first] as int;
            final b = scores[players.last] as int;
            if (a == b) {
              _finish(data, '', true);
            } else {
              _finish(data, a > b ? players.first : players.last, false);
            }
          }

          if (status != 'finished' && qIndex < questions.length) {
            final timeOver = DateTime.now().millisecondsSinceEpoch > deadlineMs;
            if (timeOver || answers.length == 2) {
              final answer = questions[qIndex]['answer'] as int;
              for (final p in players) {
                if (answers[p] == answer) scores[p] = (scores[p] ?? 0) + 1;
              }
              RoomService.instance.updateState(roomId, {
                'matchData': {
                  'qIndex': qIndex + 1,
                  'answers': <String, int>{},
                  'scores': scores,
                  'deadlineMs': DateTime.now().millisecondsSinceEpoch + 15000,
                }
              });
            }
          }

          final left = ((deadlineMs - DateTime.now().millisecondsSinceEpoch) / 1000).ceil().clamp(0, 15);
          final q = qIndex < questions.length ? questions[qIndex] : questions.last;
          final options = List<String>.from(q['options'] as List);

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Score ${scores[players.first]} : ${scores[players.last]}'),
                const SizedBox(height: 8),
                Text('Timer: ${left}s'),
                const SizedBox(height: 12),
                Text(q['q'] as String, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                for (var i = 0; i < options.length; i++)
                  Card(
                    child: ListTile(
                      title: Text(options[i]),
                      trailing: answers[uid] == i ? const Icon(Icons.check_circle, color: Colors.greenAccent) : null,
                      onTap: status == 'finished' || answers.containsKey(uid)
                          ? null
                          : () => RoomService.instance.updateState(roomId, {
                                'matchData': {
                                  'qIndex': qIndex,
                                  'scores': scores,
                                  'deadlineMs': deadlineMs,
                                  'answers': {...answers, uid: i},
                                }
                              }),
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
