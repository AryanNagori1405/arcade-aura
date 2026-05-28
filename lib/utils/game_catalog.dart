const gameCatalog = <Map<String, String>>[
  {'id': 'tic_tac_toe', 'title': 'Tic Tac Toe'},
  {'id': 'connect_4', 'title': 'Connect 4'},
  {'id': 'rock_paper_scissors', 'title': 'Rock Paper Scissors'},
  {'id': 'memory_match', 'title': 'Memory Match'},
  {'id': 'quiz_battle', 'title': 'Quiz Battle'},
  {'id': 'snake_ladder', 'title': 'Snake & Ladder'},
];

String gameTitle(String id) {
  return gameCatalog.firstWhere((g) => g['id'] == id, orElse: () => {'title': id})['title']!;
}
