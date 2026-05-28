import 'package:arcade_aura/models/app_user.dart';
import 'package:arcade_aura/services/auth_service.dart';
import 'package:arcade_aura/services/user_service.dart';
import 'package:arcade_aura/utils/game_catalog.dart';
import 'package:arcade_aura/widgets/gradient_scaffold.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return GradientScaffold(
      appBar: AppBar(
        title: const Text('Profile Stats'),
        actions: [IconButton(onPressed: AuthService.instance.logout, icon: const Icon(Icons.logout))],
      ),
      body: StreamBuilder<AppUser>(
        stream: UserService.instance.userStream(uid),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final me = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Hero(
                tag: 'profile-card',
                child: Card(
                  child: ListTile(
                    title: Text(me.username),
                    subtitle: Text(me.email),
                    trailing: Text('🏆 ${me.trophies}'),
                  ),
                ),
              ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Wins: ${me.wins}'),
                      Text('Losses: ${me.losses}'),
                      Text('Draws: ${me.draws}'),
                      Text('Favorite: ${gameTitle(me.favoriteGame)}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text('Match History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              for (final m in me.matchHistory.reversed.take(20))
                Card(
                  child: ListTile(
                    title: Text(gameTitle(m['gameType'] ?? 'unknown')),
                    subtitle: Text('${m['result']} • ${m['at'] ?? ''}'),
                    trailing: Text(m['roomId'] ?? ''),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
