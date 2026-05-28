import 'package:arcade_aura/screens/games/connect4_screen.dart';
import 'package:arcade_aura/screens/games/memory_match_screen.dart';
import 'package:arcade_aura/screens/games/quiz_battle_screen.dart';
import 'package:arcade_aura/screens/games/rps_screen.dart';
import 'package:arcade_aura/screens/games/snake_ladder_screen.dart';
import 'package:arcade_aura/screens/games/tic_tac_toe_screen.dart';
import 'package:arcade_aura/services/room_service.dart';
import 'package:arcade_aura/services/user_service.dart';
import 'package:arcade_aura/widgets/gradient_scaffold.dart';
import 'package:arcade_aura/widgets/neon_button.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LobbyScreen extends StatefulWidget {
  const LobbyScreen({super.key, required this.gameType, required this.gameTitle});

  final String gameType;
  final String gameTitle;

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  final _roomIdController = TextEditingController();
  bool _loading = false;

  Future<void> _goToGame(String roomId) async {
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _screenForGame(widget.gameType, roomId)),
    );
  }

  Widget _screenForGame(String gameType, String roomId) {
    switch (gameType) {
      case 'connect_4':
        return Connect4Screen(roomId: roomId);
      case 'rock_paper_scissors':
        return RpsScreen(roomId: roomId);
      case 'memory_match':
        return MemoryMatchScreen(roomId: roomId);
      case 'quiz_battle':
        return QuizBattleScreen(roomId: roomId);
      case 'snake_ladder':
        return SnakeLadderScreen(roomId: roomId);
      default:
        return TicTacToeScreen(roomId: roomId);
    }
  }

  Future<void> _createRoom() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final user = await UserService.instance.userStream(uid).first;
    setState(() => _loading = true);
    final roomId = await RoomService.instance.createRoom(
      gameType: widget.gameType,
      uid: uid,
      username: user.username,
    );
    setState(() => _loading = false);
    await _goToGame(roomId);
  }

  Future<void> _joinRoom() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final user = await UserService.instance.userStream(uid).first;
    setState(() => _loading = true);
    final ok = await RoomService.instance.joinRoom(
      roomId: _roomIdController.text.trim(),
      uid: uid,
      username: user.username,
    );
    setState(() => _loading = false);
    if (ok) {
      await _goToGame(_roomIdController.text.trim());
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to join room')));
    }
  }

  Future<void> _randomMatch() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final user = await UserService.instance.userStream(uid).first;
    setState(() => _loading = true);
    final roomId = await RoomService.instance.joinRandom(
      gameType: widget.gameType,
      uid: uid,
      username: user.username,
    );
    setState(() => _loading = false);
    await _goToGame(roomId!);
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(title: Text('${widget.gameTitle} Lobby')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _roomIdController,
              decoration: const InputDecoration(labelText: 'Room ID'),
            ),
            const SizedBox(height: 14),
            if (_loading)
              const CircularProgressIndicator()
            else ...[
              NeonButton(label: 'Create Room', icon: Icons.add, onTap: _createRoom),
              const SizedBox(height: 10),
              NeonButton(label: 'Join with Room ID', icon: Icons.group_add, onTap: _joinRoom),
              const SizedBox(height: 10),
              NeonButton(label: 'Play Online (Random)', icon: Icons.bolt, onTap: _randomMatch),
            ],
          ],
        ),
      ),
    );
  }
}
