class AppUser {
  const AppUser({
    required this.uid,
    required this.username,
    required this.email,
    required this.trophies,
    required this.wins,
    required this.losses,
    required this.draws,
    required this.favoriteGame,
    required this.matchHistory,
  });

  final String uid;
  final String username;
  final String email;
  final int trophies;
  final int wins;
  final int losses;
  final int draws;
  final String favoriteGame;
  final List<Map<String, dynamic>> matchHistory;

  factory AppUser.fromMap(String uid, Map<String, dynamic> map) {
    return AppUser(
      uid: uid,
      username: map['username'] ?? 'Player',
      email: map['email'] ?? '',
      trophies: map['trophies'] ?? 0,
      wins: map['wins'] ?? 0,
      losses: map['losses'] ?? 0,
      draws: map['draws'] ?? 0,
      favoriteGame: map['favoriteGame'] ?? 'Tic Tac Toe',
      matchHistory: List<Map<String, dynamic>>.from(map['matchHistory'] ?? const []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'email': email,
      'trophies': trophies,
      'wins': wins,
      'losses': losses,
      'draws': draws,
      'favoriteGame': favoriteGame,
      'matchHistory': matchHistory,
    };
  }
}
