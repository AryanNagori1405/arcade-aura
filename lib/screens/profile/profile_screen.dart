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
          final totalMatches = me.wins + me.losses + me.draws;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Hero(
                tag: 'profile-card',
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          child: Text(
                            me.username.isEmpty ? 'P' : me.username[0].toUpperCase(),
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                me.username,
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                me.email,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text('🏆 ${me.trophies}', style: const TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Performance', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _statChip('Wins', me.wins.toString(), Colors.greenAccent),
                          _statChip('Losses', me.losses.toString(), Colors.redAccent),
                          _statChip('Draws', me.draws.toString(), Colors.lightBlueAccent),
                          _statChip('Matches', totalMatches.toString(), Colors.purpleAccent),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text('Favorite game: ${gameTitle(me.favoriteGame)}'),
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
                    subtitle: Text('${m['result']} • ${m['at'] ?? ''}', maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: const Icon(Icons.chevron_right),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _statChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        border: Border.all(color: color.withOpacity(0.55)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text('$label: $value', style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}
