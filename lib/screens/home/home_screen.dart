import 'package:arcade_aura/models/app_user.dart';
import 'package:arcade_aura/screens/leaderboard/leaderboard_screen.dart';
import 'package:arcade_aura/screens/lobby/lobby_screen.dart';
import 'package:arcade_aura/screens/profile/profile_screen.dart';
import 'package:arcade_aura/services/auth_service.dart';
import 'package:arcade_aura/services/user_service.dart';
import 'package:arcade_aura/utils/game_catalog.dart';
import 'package:arcade_aura/widgets/gradient_scaffold.dart';
import 'package:arcade_aura/widgets/neon_button.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    return GradientScaffold(
      appBar: AppBar(
        title: const Text('Arcade Aura'),
        actions: [
          IconButton(onPressed: AuthService.instance.logout, icon: const Icon(Icons.logout)),
        ],
      ),
      body: StreamBuilder<AppUser>(
        stream: UserService.instance.userStream(user.uid),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final me = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Hero(
                tag: 'profile-card',
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(me.username, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(me.email),
                        const SizedBox(height: 10),
                        Text('🏆 Trophies: ${me.trophies}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: NeonButton(
                      label: 'Leaderboard',
                      icon: Icons.emoji_events,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LeaderboardScreen())),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: NeonButton(
                      label: 'Profile',
                      icon: Icons.person,
                      color: const Color(0xFFFF4DFF),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Text('Mini Games', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              for (final game in gameCatalog)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    child: Card(
                      child: ListTile(
                        title: Text(game['title']!),
                        subtitle: const Text('Play Online or with Room ID'),
                        trailing: const Icon(Icons.play_circle_fill_rounded),
                        onTap: () => Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (_, __, ___) => LobbyScreen(gameType: game['id']!, gameTitle: game['title']!),
                            transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
