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
    if ((await ref.get()).exists) return;
    await ref.set({
      'username': username,
      'email': email,
      'trophies': 0,
      'wins': 0,
      'losses': 0,
      'draws': 0,
      'favoriteGame': 'Tic Tac Toe',
      'matchHistory': <Map<String, dynamic>>[],
      'createdAt': FieldValue.serverTimestamp(),
    });
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
