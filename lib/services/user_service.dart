import 'package:arcade_aura/models/app_user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  UserService._();
  static final instance = UserService._();

  final _users = FirebaseFirestore.instance.collection('users');

  Future<void> createIfMissing({
    required String uid,
    required String username,
    required String email,
  }) async {
    final ref = _users.doc(uid);
    final doc = await ref.get();
    final resolvedUsername = _resolveUsername(username, email);
    final resolvedEmail = email.trim();

    if (!doc.exists) {
      await ref.set({
        'username': resolvedUsername,
        'email': resolvedEmail,
        'trophies': 0,
        'wins': 0,
        'losses': 0,
        'draws': 0,
        'favoriteGame': 'Tic Tac Toe',
        'matchHistory': <Map<String, dynamic>>[],
        'createdAt': FieldValue.serverTimestamp(),
      });
      return;
    }

    final data = doc.data() ?? {};
    final currentUsername = (data['username'] is String) ? (data['username'] as String).trim() : '';
    final currentEmail = (data['email'] is String) ? (data['email'] as String).trim() : '';
    final updates = <String, dynamic>{};

    if (currentUsername.isEmpty || currentUsername.toLowerCase() == 'player') {
      updates['username'] = resolvedUsername;
    }
    if (currentEmail.isEmpty && resolvedEmail.isNotEmpty) {
      updates['email'] = resolvedEmail;
    }
    if (updates.isNotEmpty) {
      await ref.update(updates);
    }
  }

  String _resolveUsername(String username, String email) {
    final trimmedUsername = username.trim();
    if (trimmedUsername.isNotEmpty) return trimmedUsername;
    final trimmedEmail = email.trim();
    if (trimmedEmail.isEmpty) return 'Player';
    return trimmedEmail.split('@').first;
  }

  Stream<AppUser> userStream(String uid) {
    return _users.doc(uid).snapshots().map((doc) => AppUser.fromMap(uid, doc.data() ?? {}));
  }

  Future<void> appendMatchHistory(String uid, Map<String, dynamic> result) {
    return _users.doc(uid).update({
      'matchHistory': FieldValue.arrayUnion([result]),
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> leaderboard() {
    return _users.orderBy('trophies', descending: true).limit(100).snapshots();
  }
}
