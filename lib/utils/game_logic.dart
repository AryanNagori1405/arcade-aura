import 'dart:math';

class GameLogic {
  static String checkTicTacToeWinner(List<String> board) {
    const winLines = [
      [0, 1, 2], [3, 4, 5], [6, 7, 8],
      [0, 3, 6], [1, 4, 7], [2, 5, 8],
      [0, 4, 8], [2, 4, 6],
    ];
    for (final line in winLines) {
      final a = board[line[0]];
      if (a.isNotEmpty && a == board[line[1]] && a == board[line[2]]) {
        return a;
      }
    }
    return board.every((e) => e.isNotEmpty) ? 'draw' : '';
  }

  static String checkConnect4Winner(List<List<String>> grid) {
    const rows = 6;
    const cols = 7;
    bool eq(int r, int c, int dr, int dc) {
      final v = grid[r][c];
      if (v.isEmpty) return false;
      for (var i = 1; i < 4; i++) {
        final nr = r + dr * i;
        final nc = c + dc * i;
        if (nr < 0 || nr >= rows || nc < 0 || nc >= cols || grid[nr][nc] != v) {
          return false;
        }
      }
      return true;
    }

    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        if (eq(r, c, 0, 1) || eq(r, c, 1, 0) || eq(r, c, 1, 1) || eq(r, c, 1, -1)) {
          return grid[r][c];
        }
      }
    }

    final full = grid.expand((e) => e).every((e) => e.isNotEmpty);
    return full ? 'draw' : '';
  }

  static String rockPaperScissors(String a, String b) {
    if (a == b) return 'draw';
    if ((a == 'rock' && b == 'scissors') ||
        (a == 'paper' && b == 'rock') ||
        (a == 'scissors' && b == 'paper')) {
      return 'a';
    }
    return 'b';
  }

  static List<String> shuffledMemoryDeck() {
    final cards = <String>['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H'];
    final doubled = [...cards, ...cards]..shuffle(Random());
    return doubled;
  }

  static int snakeLadderNextPos(int current, int dice) {
    const jumps = {
      3: 22,
      5: 8,
      11: 26,
      20: 29,
      27: 1,
      21: 9,
      17: 4,
      19: 7,
    };
    final moved = (current + dice).clamp(1, 30);
    return jumps[moved] ?? moved;
  }
}
