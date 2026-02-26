import 'package:flutter/foundation.dart';
import 'package:fouralot/models/game_models.dart';

const int rows = 6;
const int cols = 7;

class GameState extends ChangeNotifier {
  List<List<CellContent>> board = List.generate(
    rows,
    (_) => List.filled(cols, CellContent.empty),
  );

  int currentPlayer = 1;
  int? winner; // null = in corso, 0 = pareggio
  bool gameOver = false;
  GameConfig? config;
  int blocksRemaining1 = 3;
  int blocksRemaining2 = 3;
  List<List<int>> winningCells = [];
  final Map<GameMode, int> _aiLevels = {
    GameMode.normal: 1,
    GameMode.fourDirections: 1,
    GameMode.blocks: 1,
  };

  int get currentPlayerBlocks =>
      currentPlayer == 1 ? blocksRemaining1 : blocksRemaining2;
  int aiLevelForMode(GameMode mode) => _aiLevels[mode] ?? 1;

  void increaseAiLevel(GameMode mode) {
    _aiLevels[mode] = aiLevelForMode(mode) + 1;
    notifyListeners();
  }

  void startGame(GameConfig cfg) {
    config = cfg;
    notifyListeners();
  }

  void abandonGame() {
    winner = currentPlayer == 1 ? 2 : 1;
    gameOver = true;
    notifyListeners();
  }

  void resetBoard() {
    board = List.generate(rows, (_) => List.filled(cols, CellContent.empty));
    currentPlayer = 1;
    winner = null;
    gameOver = false;
    blocksRemaining1 = 3;
    blocksRemaining2 = 3;
    winningCells = [];
    notifyListeners();
  }

  /// Normal mode: drop in column (gravity from bottom)
  bool dropInColumn(int col) {
    if (gameOver) return false;
    int row = _findLowestEmpty(col);
    if (row == -1) return false;
    _placeCell(row, col,
        currentPlayer == 1 ? CellContent.player1 : CellContent.player2);
    return true;
  }

  /// 4 directions and blocks: insert from any side, piece slides until it hits a wall or another piece/block
  List<int>? insertFromSide(Side side, int index) {
    if (gameOver) return null;

    int row = -1, col = -1;
    int slideRowDirection = 0, slideColDirection = 0;

    switch (side) {
      case Side.left: // from left, slides right
        row = index;
        col = 0;
        slideColDirection = 1;
        break;
      case Side.right: // from right, slides left
        row = index;
        col = cols - 1;
        slideColDirection = -1;
        break;
      case Side.top: // from top, slides down
        col = index;
        row = 0;
        slideRowDirection = 1;
        break;
      case Side.bottom: // from bottom, slides up
        col = index;
        row = rows - 1;
        slideRowDirection = -1;
        break;
    }

    // Find where to insert (entry must be empty)
    if (board[row][col] != CellContent.empty) return null;

    // Slide until we hit wall or occupied cell
    int finalRow = row, finalCol = col;
    while (true) {
      int nextRow = finalRow + slideRowDirection;
      int nextCol = finalCol + slideColDirection;
      if (nextRow < 0 || nextRow >= rows || nextCol < 0 || nextCol >= cols) {
        break;
      }
      if (board[nextRow][nextCol] != CellContent.empty) break;
      finalRow = nextRow;
      finalCol = nextCol;
    }

    _placeCell(finalRow, finalCol,
        currentPlayer == 1 ? CellContent.player1 : CellContent.player2);
    return [finalRow, finalCol];
  }

  /// Place a block on a specific cell
  bool placeBlock(int row, int col) {
    if (gameOver) return false;
    if (board[row][col] != CellContent.empty) return false;
    if (config?.gameMode != GameMode.blocks) return false;

    int blocks = currentPlayer == 1 ? blocksRemaining1 : blocksRemaining2;
    if (blocks <= 0) return false;

    if (currentPlayer == 1) {
      blocksRemaining1--;
    } else {
      blocksRemaining2--;
    }

    board[row][col] =
        currentPlayer == 1 ? CellContent.block1 : CellContent.block2;
    _checkAfterMove();
    return true;
  }

  int _findLowestEmpty(int col) {
    for (int r = rows - 1; r >= 0; r--) {
      if (board[r][col] == CellContent.empty) return r;
    }
    return -1;
  }

  void _placeCell(int row, int col, CellContent content) {
    board[row][col] = content;
    _checkAfterMove();
  }

  void _checkAfterMove() {
    // Check win
    List<List<int>>? win = _findWinningCells();
    if (win != null) {
      winner = currentPlayer;
      gameOver = true;
      winningCells = win;
      notifyListeners();
      return;
    }

    // Check draw
    bool full =
        board.every((row) => row.every((cell) => cell != CellContent.empty));
    if (full) {
      winner = 0;
      gameOver = true;
      notifyListeners();
      return;
    }

    currentPlayer = currentPlayer == 1 ? 2 : 1;
    notifyListeners();
  }

  List<List<int>>? _findWinningCells() {
    const target1 = CellContent.player1;
    const target2 = CellContent.player2;

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        CellContent cell = board[r][c];
        if (cell != target1 && cell != target2) continue;

        // Check 4 directions
        for (var d in [
          [0, 1],
          [1, 0],
          [1, 1],
          [1, -1]
        ]) {
          List<List<int>> cells = [
            [r, c]
          ];
          for (int k = 1; k < 4; k++) {
            int nr = r + d[0] * k;
            int nc = c + d[1] * k;
            if (nr < 0 || nr >= rows || nc < 0 || nc >= cols) break;
            if (board[nr][nc] == cell) {
              cells.add([nr, nc]);
            } else {
              break;
            }
          }
          if (cells.length == 4) return cells;
        }
      }
    }
    return null;
  }

  bool isWinningCell(int row, int col) {
    return winningCells.any((c) => c[0] == row && c[1] == col);
  }

  /// Apply an opponent's move (for online)
  void applyRemoteMove(Move move) {
    if (move.isBlock) {
      board[move.row][move.col] =
          move.player == 1 ? CellContent.block1 : CellContent.block2;
      if (move.player == 1) {
        blocksRemaining1--;
      } else {
        blocksRemaining2--;
      }
      _checkAfterMove();
    } else {
      _placeCell(move.row, move.col,
          move.player == 1 ? CellContent.player1 : CellContent.player2);
    }
  }
}
