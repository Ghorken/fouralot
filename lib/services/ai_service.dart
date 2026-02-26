import 'package:fouralot/models/game_models.dart';
import 'package:fouralot/models/game_state.dart'; // for top-level rows, cols constants

/// AI service for the 4alot game.
/// - Normal mode: minimax with alpha-beta pruning (depth 6).
/// - 4 Directions / Blocks modes: one-ply lookahead with heuristic scoring.
class AiService {
  static const int _maxDepth = 6;
  static const int _win = 100000;

  /// Returns the best [Move] for [aiPlayer] (1 or 2) given the current [gs].
  /// Returns null if no move is possible.
  Move? getBestMove(GameState gs, int aiPlayer) {
    if (gs.gameOver) return null;
    final mode = gs.config?.gameMode ?? GameMode.normal;

    if (mode == GameMode.normal) {
      return _minimaxRoot(gs, aiPlayer);
    } else {
      return _heuristicRoot(gs, aiPlayer);
    }
  }

  // ─── Normal mode: minimax ─────────────────────────────────────────────────

  Move? _minimaxRoot(GameState gs, int aiPlayer) {
    final board = _cloneBoard(gs.board);
    int bestScore = -_win - 1;
    int bestCol = -1;

    // Prefer centre columns
    final colOrder = List.generate(cols, (i) => i)..sort((a, b) => (a - cols ~/ 2).abs().compareTo((b - cols ~/ 2).abs()));

    for (final col in colOrder) {
      final row = _lowestEmpty(board, col);
      if (row == -1) continue;

      board[row][col] = aiPlayer == 1 ? CellContent.player1 : CellContent.player2;
      final score = _minimax(board, _maxDepth - 1, false, aiPlayer, -_win - 1, _win + 1);
      board[row][col] = CellContent.empty;

      if (score > bestScore) {
        bestScore = score;
        bestCol = col;
      }
    }

    if (bestCol == -1) return null;
    return Move(row: -1, col: bestCol, player: aiPlayer);
  }

  int _minimax(List<List<CellContent>> board, int depth, bool isMax, int aiPlayer, int alpha, int beta) {
    final winner = _checkWinner(board);
    if (winner == aiPlayer) return _win + depth;
    if (winner != null) return -_win - depth;
    if (depth == 0 || _isFull(board)) return _scoreBoard(board, aiPlayer);

    final opponent = aiPlayer == 1 ? 2 : 1;
    final current = isMax ? aiPlayer : opponent;
    final piece = current == 1 ? CellContent.player1 : CellContent.player2;

    int best = isMax ? -_win - 1 : _win + 1;

    for (int c = 0; c < cols; c++) {
      final r = _lowestEmpty(board, c);
      if (r == -1) continue;
      board[r][c] = piece;
      final val = _minimax(board, depth - 1, !isMax, aiPlayer, alpha, beta);
      board[r][c] = CellContent.empty;

      if (isMax) {
        if (val > best) best = val;
        if (best > alpha) alpha = best;
      } else {
        if (val < best) best = val;
        if (best < beta) beta = best;
      }
      if (alpha >= beta) break;
    }
    return best;
  }

  // ─── 4 Directions / Blocks: one-ply heuristic ────────────────────────────

  Move? _heuristicRoot(GameState gs, int aiPlayer) {
    final mode = gs.config!.gameMode;
    Move? best;
    int bestScore = -_win - 1;

    void tryMove(Move m, List<List<CellContent>> resultBoard) {
      final s = _scoreBoard(resultBoard, aiPlayer);
      if (s > bestScore) {
        bestScore = s;
        best = m;
      }
    }

    // Try all 4-direction inserts
    for (final dir in Direction.values) {
      final count = (dir == Direction.left || dir == Direction.right) ? rows : cols;
      for (int i = 0; i < count; i++) {
        final board = _cloneBoard(gs.board);
        if (!_simulateInsert(board, dir, i, aiPlayer)) continue;
        tryMove(Move(row: dir.index, col: i, player: aiPlayer), board);
      }
    }

    // Try block placement (blocks mode only)
    if (mode == GameMode.blocks) {
      final blocksLeft = aiPlayer == 1 ? gs.blocksRemaining1 : gs.blocksRemaining2;
      if (blocksLeft > 0) {
        for (int r = 0; r < rows; r++) {
          for (int c = 0; c < cols; c++) {
            if (gs.board[r][c] != CellContent.empty) continue;
            final board = _cloneBoard(gs.board);
            board[r][c] = aiPlayer == 1 ? CellContent.block1 : CellContent.block2;
            final s = _scoreBoard(board, aiPlayer) - 20; // bias towards moves over blocks
            if (s > bestScore) {
              bestScore = s;
              best = Move(row: r, col: c, player: aiPlayer, isBlock: true);
            }
          }
        }
      }
    }

    return best;
  }

  // ─── Board simulation helpers ─────────────────────────────────────────────

  bool _simulateInsert(List<List<CellContent>> board, Direction dir, int index, int player) {
    final piece = player == 1 ? CellContent.player1 : CellContent.player2;
    int row, col, dr = 0, dc = 0;

    switch (dir) {
      case Direction.left:
        row = index;
        col = 0;
        dc = 1;
        break;
      case Direction.right:
        row = index;
        col = cols - 1;
        dc = -1;
        break;
      case Direction.top:
        col = index;
        row = 0;
        dr = 1;
        break;
      case Direction.bottom:
        col = index;
        row = rows - 1;
        dr = -1;
        break;
    }

    if (board[row][col] != CellContent.empty) return false;
    int fr = row, fc = col;
    while (true) {
      final nr = fr + dr, nc = fc + dc;
      if (nr < 0 || nr >= rows || nc < 0 || nc >= cols) break;
      if (board[nr][nc] != CellContent.empty) break;
      fr = nr;
      fc = nc;
    }
    board[fr][fc] = piece;
    return true;
  }

  // ─── Scoring heuristic ────────────────────────────────────────────────────

  int _scoreBoard(List<List<CellContent>> board, int aiPlayer) {
    final aiPiece = aiPlayer == 1 ? CellContent.player1 : CellContent.player2;
    final oppPiece = aiPlayer == 1 ? CellContent.player2 : CellContent.player1;
    int score = 0;

    // Centre column preference
    for (int r = 0; r < rows; r++) {
      if (board[r][cols ~/ 2] == aiPiece) score += 3;
    }

    // Windows of 4 in all directions
    for (final d in [
      [0, 1],
      [1, 0],
      [1, 1],
      [1, -1]
    ]) {
      for (int r = 0; r < rows; r++) {
        for (int c = 0; c < cols; c++) {
          int ai = 0, opp = 0, empty = 0;
          bool valid = true;
          for (int k = 0; k < 4; k++) {
            final nr = r + d[0] * k, nc = c + d[1] * k;
            if (nr < 0 || nr >= rows || nc < 0 || nc >= cols) {
              valid = false;
              break;
            }
            final cell = board[nr][nc];
            if (cell == aiPiece) {
              ai++;
            } else if (cell == oppPiece) {
              opp++;
            } else if (cell == CellContent.empty) {
              empty++;
            }
            // block1/block2 count as obstacles (skipped)
          }
          if (!valid) continue;
          if (opp == 0) {
            if (ai == 4) {
              score += _win;
            } else if (ai == 3 && empty == 1) {
              score += 100;
            } else if (ai == 2 && empty == 2) {
              score += 10;
            }
          }
          if (ai == 0) {
            if (opp == 4) {
              score -= _win;
            } else if (opp == 3 && empty == 1) {
              score -= 120;
            } else if (opp == 2 && empty == 2) {
              score -= 12;
            }
          }
        }
      }
    }
    return score;
  }

  // ─── Win detection ────────────────────────────────────────────────────────

  int? _checkWinner(List<List<CellContent>> board) {
    for (final d in [
      [0, 1],
      [1, 0],
      [1, 1],
      [1, -1]
    ]) {
      for (int r = 0; r < rows; r++) {
        for (int c = 0; c < cols; c++) {
          final cell = board[r][c];
          if (cell != CellContent.player1 && cell != CellContent.player2) continue;
          bool win = true;
          for (int k = 1; k < 4; k++) {
            final nr = r + d[0] * k, nc = c + d[1] * k;
            if (nr < 0 || nr >= rows || nc < 0 || nc >= cols || board[nr][nc] != cell) {
              win = false;
              break;
            }
          }
          if (win) return cell == CellContent.player1 ? 1 : 2;
        }
      }
    }
    return null;
  }

  // ─── Utility ─────────────────────────────────────────────────────────────

  int _lowestEmpty(List<List<CellContent>> board, int col) {
    for (int r = rows - 1; r >= 0; r--) {
      if (board[r][col] == CellContent.empty) return r;
    }
    return -1;
  }

  bool _isFull(List<List<CellContent>> board) => board.every((row) => row.every((c) => c != CellContent.empty));

  List<List<CellContent>> _cloneBoard(List<List<CellContent>> board) => board.map((r) => List<CellContent>.from(r)).toList();
}
