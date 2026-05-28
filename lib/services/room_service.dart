import 'package:cloud_firestore/cloud_firestore.dart';

class RoomService {
  RoomService._();
  static final instance = RoomService._();

  final _rooms = FirebaseFirestore.instance.collection('rooms');

  Future<String> createRoom({
    required String gameType,
    required String uid,
    required String username,
  }) async {
    final ref = _rooms.doc();
    await ref.set({
      'gameType': gameType,
      'status': 'waiting',
      'players': [uid],
      'playerNames': {uid: username},
      'turnUid': uid,
      'winnerUid': '',
      'board': [],
      'moveCount': 0,
      'matchData': {},
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<bool> joinRoom({
    required String roomId,
    required String uid,
    required String username,
  }) async {
    final ref = _rooms.doc(roomId);
    return FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return false;
      final data = snap.data()!;
      final players = List<String>.from(data['players'] ?? const []);
      final names = Map<String, dynamic>.from(data['playerNames'] ?? const {});
      if (players.contains(uid)) return true;
      if (players.length >= 2 || data['status'] == 'finished') return false;
      players.add(uid);
      names[uid] = username;
      tx.update(ref, {
        'players': players,
        'playerNames': names,
        'status': 'playing',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    });
  }

  Future<String?> joinRandom({
    required String gameType,
    required String uid,
    required String username,
  }) async {
    final waiting = await _rooms
        .where('gameType', isEqualTo: gameType)
        .where('status', isEqualTo: 'waiting')
        .limit(10)
        .get();
    for (final doc in waiting.docs) {
      final joined = await joinRoom(roomId: doc.id, uid: uid, username: username);
      if (joined) return doc.id;
    }
    final room = await createRoom(gameType: gameType, uid: uid, username: username);
    return room;
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> roomStream(String roomId) {
    return _rooms.doc(roomId).snapshots();
  }

  Future<void> updateState(String roomId, Map<String, dynamic> data) {
    return _rooms.doc(roomId).update({...data, 'updatedAt': FieldValue.serverTimestamp()});
  }


  Future<bool> finishRoom({
    required String roomId,
    required String winnerUid,
    required bool isDraw,
  }) async {
    final ref = _rooms.doc(roomId);
    return FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return false;
      final data = snap.data()!;
      if (data['status'] == 'finished') return false;
      tx.update(ref, {
        'status': 'finished',
        'winnerUid': isDraw ? '' : winnerUid,
        'matchData.isDraw': isDraw,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    });
  }

  Future<void> resetForNextRound(String roomId, Map<String, dynamic> initialState) {
    return updateState(roomId, {
      'winnerUid': '',
      'status': 'playing',
      'moveCount': 0,
      'board': [],
      'matchData': initialState,
    });
  }
}
