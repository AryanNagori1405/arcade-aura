import 'package:arcade_aura/services/room_service.dart';
import 'package:arcade_aura/services/trophy_service.dart';
import 'package:arcade_aura/utils/game_logic.dart';
import 'package:arcade_aura/widgets/gradient_scaffold.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class RpsScreen extends StatefulWidget {
  const RpsScreen({super.key, required this.roomId});
  final String roomId;

  @override
  State<RpsScreen> createState() => _RpsScreenState();
}

class _RpsScreenState extends State<RpsScreen> {
  String? _lastResolvedRoundKey;
  bool _isResolvingRound = false;

  Future<void> _finish(Map<String, dynamic> data, String winnerUid, bool draw) async {
    final players = List<String>.from(data['players'] ?? const []);
    final done = await RoomService.instance.finishRoom(roomId: widget.roomId, winnerUid: winnerUid, isDraw: draw);
    if (done) {
      await TrophyService.instance.applyResult(
        roomId: widget.roomId,
        gameType: 'rock_paper_scissors',
        players: players,
        winnerUid: winnerUid,
        isDraw: draw,
      );
    }
  }

  Future<void> _resolveRound({
    required Map<String, dynamic> data,
    required List<String> players,
    required Map<String, dynamic> choices,
    required Map<String, dynamic> scores,
    required int round,
    required String status,
  }) async {
    if (_isResolvingRound || status == 'finished' || choices.length != 2) return;
    final key = '$round|${choices[players.first]}|${choices[players.last]}';
    if (_lastResolvedRoundKey == key) return;
    _isResolvingRound = true;
    _lastResolvedRoundKey = key;
    final a = choices[players.first] as String;
    final b = choices[players.last] as String;
    final result = GameLogic.rockPaperScissors(a, b);
    if (result == 'a') scores[players.first] = (scores[players.first] ?? 0) + 1;
    if (result == 'b') scores[players.last] = (scores[players.last] ?? 0) + 1;

    final aScore = scores[players.first] as int;
    final bScore = scores[players.last] as int;
    if (aScore == 2 || bScore == 2 || round == 3) {
      if (aScore == bScore) {
        await _finish(data, '', true);
      } else {
        await _finish(data, aScore > bScore ? players.first : players.last, false);
      }
    } else {
      await RoomService.instance.updateState(widget.roomId, {
        'matchData': {'scores': scores, 'choices': <String, String>{}, 'round': round + 1},
      });
    }
    _isResolvingRound = false;
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return GradientScaffold(
      appBar: AppBar(title: const Text('Rock Paper Scissors')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: RoomService.instance.roomStream(widget.roomId),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final data = snap.data!.data() ?? {};
          final players = List<String>.from(data['players'] ?? const []);
          if (players.length < 2) return const Center(child: Text('Waiting for second player...'));
          final status = data['status'] ?? 'playing';
          final matchData = Map<String, dynamic>.from(data['matchData'] ?? const {});
          final scores = Map<String, dynamic>.from(matchData['scores'] ?? {players.first: 0, players.last: 0});
          final choices = Map<String, dynamic>.from(matchData['choices'] ?? {});
          final round = (matchData['round'] ?? 1) as int;

          if (status != 'finished' && choices.length == 2 && choices[players.first] is String && choices[players.last] is String) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _resolveRound(
                data: data,
                players: players,
                choices: choices,
                scores: scores,
                round: round,
                status: status,
              );
            });
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text('Best of 3 • Round $round'),
                const SizedBox(height: 10),
                Text('Score ${scores[players.first]} : ${scores[players.last]}'),
                const SizedBox(height: 16),
                Text(choices.containsKey(uid) ? 'Choice locked. Waiting...' : 'Choose secretly'),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  children: ['rock', 'paper', 'scissors']
                      .map((c) => ElevatedButton(
                            onPressed: status == 'finished' || choices.containsKey(uid)
                                ? null
                                : () => RoomService.instance.submitRpsChoice(roomId: widget.roomId, uid: uid, choice: c),
                            child: Text(c.toUpperCase()),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 16),
                if (choices.length == 2)
                  Text('Both choices submitted. Revealing result...'),
              ],
            ),
          );
        },
      ),
    );
  }
}
