import 'package:cloud_firestore/cloud_firestore.dart';

class TrophyService {
  TrophyService._();
  static final instance = TrophyService._();

  final _db = FirebaseFirestore.instance;

  Future<void> applyResult({
    required String roomId,
    required String gameType,
    required List<String> players,
    required String winnerUid,
    required bool isDraw,
  }) async {
    await _db.runTransaction((tx) async {
      final roomRef = _db.collection('rooms').doc(roomId);
      final roomSnap = await tx.get(roomRef);
      if (!roomSnap.exists) return;

      final roomData = roomSnap.data()!;
      if (roomData['status'] != 'finished') return;

      final matchData = Map<String, dynamic>.from(roomData['matchData'] ?? const {});
      if (matchData['resultApplied'] == true) return;

      final roomPlayers = List<String>.from(roomData['players'] ?? players);
      if (roomPlayers.isEmpty) return;
      final resolvedGameType = (roomData['gameType'] ?? gameType) as String;
      final resolvedWinnerUid = (roomData['winnerUid'] ?? winnerUid) as String;
      final resolvedIsDraw = matchData['isDraw'] == true || isDraw;
      if (!resolvedIsDraw && !roomPlayers.contains(resolvedWinnerUid)) return;

      for (final uid in roomPlayers) {
        final ref = _db.collection('users').doc(uid);
        final snap = await tx.get(ref);
        if (!snap.exists) continue;
        final data = snap.data()!;
        int trophies = (data['trophies'] ?? 0) as int;
        int wins = (data['wins'] ?? 0) as int;
        int losses = (data['losses'] ?? 0) as int;
        int draws = (data['draws'] ?? 0) as int;

        String result;
        if (resolvedIsDraw) {
          trophies += 1;
          draws += 1;
          result = 'draw';
        } else if (uid == resolvedWinnerUid) {
          trophies += 3;
          wins += 1;
          result = 'win';
        } else {
          trophies -= 3;
          losses += 1;
          result = 'loss';
        }

        tx.update(ref, {
          'trophies': trophies,
          'wins': wins,
          'losses': losses,
          'draws': draws,
          'favoriteGame': resolvedGameType,
          'matchHistory': FieldValue.arrayUnion([
            {
              'gameType': resolvedGameType,
              'result': result,
              'roomId': roomId,
              'at': DateTime.now().toIso8601String(),
            }
          ]),
        });
      }

      tx.update(roomRef, {
        'matchData.resultApplied': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
