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

  Future<void> initializeMatchDataIfEmpty({
    required String roomId,
    required Map<String, dynamic> initialMatchData,
  }) async {
    final ref = _rooms.doc(roomId);
    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;
      final data = snap.data()!;
      final matchData = Map<String, dynamic>.from(data['matchData'] ?? const {});
      if (matchData.isNotEmpty) return;
      tx.update(ref, {
        'matchData': initialMatchData,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> submitRpsChoice({
    required String roomId,
    required String uid,
    required String choice,
  }) async {
    final ref = _rooms.doc(roomId);
    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;
      final data = snap.data()!;
      if (data['status'] == 'finished') return;
      final players = List<String>.from(data['players'] ?? const []);
      if (!players.contains(uid)) return;
      final matchData = Map<String, dynamic>.from(data['matchData'] ?? const {});
      final choices = Map<String, dynamic>.from(matchData['choices'] ?? const {});
      if (choices.containsKey(uid)) return;
      final round = (matchData['round'] ?? 1) as int;
      final scores = Map<String, dynamic>.from(
        matchData['scores'] ?? {if (players.isNotEmpty) players.first: 0, if (players.length > 1) players.last: 0},
      );
      tx.update(ref, {
        'matchData.round': round,
        'matchData.scores': scores,
        'matchData.choices.$uid': choice,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> submitQuizAnswer({
    required String roomId,
    required String uid,
    required int answerIndex,
  }) async {
    final ref = _rooms.doc(roomId);
    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;
      final data = snap.data()!;
      if (data['status'] == 'finished') return;
      final players = List<String>.from(data['players'] ?? const []);
      if (!players.contains(uid)) return;
      final matchData = Map<String, dynamic>.from(data['matchData'] ?? const {});
      final answers = Map<String, dynamic>.from(matchData['answers'] ?? const {});
      if (answers.containsKey(uid)) return;
      tx.update(ref, {
        'matchData.answers.$uid': answerIndex,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> finalizeQuizQuestion({
    required String roomId,
    required int questionIndex,
    required int correctAnswer,
    required int nextDeadlineMs,
  }) async {
    final ref = _rooms.doc(roomId);
    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;
      final data = snap.data()!;
      if (data['status'] == 'finished') return;
      final players = List<String>.from(data['players'] ?? const []);
      if (players.length < 2) return;
      final matchData = Map<String, dynamic>.from(data['matchData'] ?? const {});
      final qIndex = (matchData['qIndex'] ?? 0) as int;
      if (qIndex != questionIndex) return;
      final answers = Map<String, dynamic>.from(matchData['answers'] ?? const {});
      final deadlineMs = (matchData['deadlineMs'] ?? 0) as int;
      final timeOver = DateTime.now().millisecondsSinceEpoch > deadlineMs;
      if (!timeOver && answers.length < 2) return;
      final scores = Map<String, dynamic>.from(matchData['scores'] ?? {players.first: 0, players.last: 0});
      for (final p in players) {
        if (answers[p] == correctAnswer) {
          scores[p] = (scores[p] ?? 0) + 1;
        }
      }
      tx.update(ref, {
        'matchData.qIndex': qIndex + 1,
        'matchData.answers': <String, int>{},
        'matchData.scores': scores,
        'matchData.deadlineMs': nextDeadlineMs,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
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
      final players = List<String>.from(data['players'] ?? const []);
      if (players.isEmpty) return false;
      if (!isDraw && !players.contains(winnerUid)) return false;
      tx.update(ref, {
        'status': 'finished',
        'winnerUid': isDraw ? '' : winnerUid,
        'matchData.isDraw': isDraw,
        'matchData.resultApplied': false,
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
