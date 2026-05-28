import 'package:arcade_aura/widgets/gradient_scaffold.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(title: const Text('Leaderboard')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('users').orderBy('trophies', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final d = docs[index].data();
              return ListTile(
                leading: CircleAvatar(child: Text('${index + 1}')),
                title: Text(d['username'] ?? 'Player'),
                subtitle: Text('W:${d['wins'] ?? 0} L:${d['losses'] ?? 0} D:${d['draws'] ?? 0}'),
                trailing: Text('🏆 ${d['trophies'] ?? 0}'),
              );
            },
          );
        },
      ),
    );
  }
}
