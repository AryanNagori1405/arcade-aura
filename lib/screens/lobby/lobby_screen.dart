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
import 'package:flutter/services.dart';

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
  bool _isMatchmaking = false;

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
    if (_loading) return;
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final user = await UserService.instance.userStream(uid).first;
    setState(() => _loading = true);
    final roomId = await RoomService.instance.createRoom(
      gameType: widget.gameType,
      uid: uid,
      username: user.username,
    );
    if (!mounted) return;
    setState(() => _loading = false);
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Room Created'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Share this Room ID with your friend:'),
            const SizedBox(height: 8),
            SelectableText(roomId, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: roomId));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Room ID copied')),
              );
            },
            child: const Text('Copy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    await _goToGame(roomId);
  }

  Future<void> _joinRoom() async {
    if (_loading) return;
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
    if (_loading) return;
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final user = await UserService.instance.userStream(uid).first;
    setState(() {
      _loading = true;
      _isMatchmaking = true;
    });
    final roomId = await RoomService.instance.joinRandom(
      gameType: widget.gameType,
      uid: uid,
      username: user.username,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      _isMatchmaking = false;
    });
    await _goToGame(roomId!);
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(title: Text('${widget.gameTitle} Lobby')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Private Room', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _roomIdController,
                      decoration: const InputDecoration(labelText: 'Room ID'),
                    ),
                    const SizedBox(height: 10),
                    if (_loading)
                      const Center(child: CircularProgressIndicator())
                    else ...[
                      NeonButton(label: 'Create Room', icon: Icons.add, onTap: _createRoom),
                      const SizedBox(height: 10),
                      NeonButton(label: 'Join with Room ID', icon: Icons.group_add, onTap: _joinRoom),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.public, color: Theme.of(context).colorScheme.secondary),
                        const SizedBox(width: 8),
                        const Text('Play Online', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text('No Room ID needed. We will match you automatically.'),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('• Fast matchmaking'),
                          SizedBox(height: 4),
                          Text('• Auto joins available players'),
                          SizedBox(height: 4),
                          Text('• Starts as soon as room is ready'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (_isMatchmaking)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 10),
                            Expanded(child: Text('Matchmaking... finding an opponent')),
                          ),
                        ),
                      )
                    else
                      NeonButton(
                        label: 'Start Online Match',
                        icon: Icons.bolt,
                        onTap: _randomMatch,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
