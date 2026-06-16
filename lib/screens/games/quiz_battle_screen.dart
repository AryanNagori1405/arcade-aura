import 'package:arcade_aura/services/room_service.dart';
import 'package:arcade_aura/services/trophy_service.dart';
import 'package:arcade_aura/widgets/gradient_scaffold.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class QuizBattleScreen extends StatefulWidget {
  const QuizBattleScreen({super.key, required this.roomId});
  final String roomId;

  @override
  State<QuizBattleScreen> createState() => _QuizBattleScreenState();
}

class _QuizBattleScreenState extends State<QuizBattleScreen> {
  bool _isInitializing = false;
  int? _lastScoredQuestion;
  bool _isFinishing = false;

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
    if (_isFinishing) return;
    _isFinishing = true;
    final players = List<String>.from(data['players'] ?? const []);
    try {
      final done = await RoomService.instance.finishRoom(roomId: widget.roomId, winnerUid: winnerUid, isDraw: draw);
      if (done) {
        await TrophyService.instance.applyResult(
          roomId: widget.roomId,
          gameType: 'quiz_battle',
          players: players,
          winnerUid: winnerUid,
          isDraw: draw,
        );
      }
    } finally {
      _isFinishing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return GradientScaffold(
      appBar: AppBar(title: const Text('Quiz Battle')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: RoomService.instance.roomStream(widget.roomId),
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

          if (md.isEmpty && !_isInitializing) {
            _isInitializing = true;
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              await RoomService.instance.initializeMatchDataIfEmpty(
                roomId: widget.roomId,
                initialMatchData: {
                  'qIndex': 0,
                  'answers': <String, int>{},
                  'scores': scores,
                  'deadlineMs': DateTime.now().millisecondsSinceEpoch + 15000,
                },
              );
              _isInitializing = false;
            });
          }

          if (status != 'finished' && qIndex >= questions.length) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final a = scores[players.first] as int;
              final b = scores[players.last] as int;
              if (a == b) {
                _finish(data, '', true);
              } else {
                _finish(data, a > b ? players.first : players.last, false);
              }
            });
          }

          if (status != 'finished' && qIndex < questions.length) {
            final timeOver = DateTime.now().millisecondsSinceEpoch > deadlineMs;
            final shouldScore = timeOver || answers.length == 2;
            if (shouldScore && _lastScoredQuestion != qIndex) {
              _lastScoredQuestion = qIndex;
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                await RoomService.instance.finalizeQuizQuestion(
                  roomId: widget.roomId,
                  questionIndex: qIndex,
                  correctAnswer: questions[qIndex]['answer'] as int,
                  nextDeadlineMs: DateTime.now().millisecondsSinceEpoch + 15000,
                );
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
                          : () => RoomService.instance.submitQuizAnswer(roomId: widget.roomId, uid: uid, answerIndex: i),
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
