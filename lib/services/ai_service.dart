import 'dart:math';
import 'package:fouralot/models/game_models.dart';
import 'package:fouralot/models/game_state.dart';

class AiService {
  final int level;
  static const int _win = 1000000;

  AiService({required this.level});

  // ─────────────────────────────────────────────────────────────
  // Difficulty Scaling
  // ─────────────────────────────────────────────────────────────

  int get _maxDepth {
    // crescita logaritmica infinita ma controllata
    return min(8, 2 + (log(level + 1) / log(2)).floor());
  }

  bool get _shouldBlunder {
    if (level > 15) return false;
    final mistakeChance = 0.45 * (1 / (level + 1));
    return Random().nextDouble() < mistakeChance;
  }

  int get _threeWeight => 80 + level * 4;
  int get _twoWeight => 8 + level;
  int get _blockBias => max(0, 25 - level);

  // ─────────────────────────────────────────────────────────────

  Move? getBestMove(GameState gs, int aiPlayer) {
    if (gs.gameOver) return null;

    final mode = gs.config?.gameMode ?? GameMode.normal;

    if (mode == GameMode.normal) {
      return _minimaxRoot(gs, aiPlayer);
    } else {
      return _progressiveHeuristic(gs, aiPlayer);
    }
  }

  // ─────────────────────────────────────────────────────────────
  // NORMAL MODE → Progressive Minimax
  // ─────────────────────────────────────────────────────────────

  Move? _minimaxRoot(GameState gs, int aiPlayer) {
    final board = _cloneBoard(gs.board);
    final moves = <MapEntry<int, int>>[];

    for (int c = 0; c < cols; c++) {
      final r = _lowestEmpty(board, c);
      if (r == -1) continue;

      board[r][c] = _piece(aiPlayer);
      final score = _minimax(board, _maxDepth - 1, false, aiPlayer, -_win, _win);
      board[r][c] = CellContent.empty;

      moves.add(MapEntry(c, score));
    }

    if (moves.isEmpty) return null;

    moves.sort((a, b) => b.value.compareTo(a.value));

    int chosenIndex = 0;

    if (_shouldBlunder && moves.length > 1) {
      chosenIndex = min(1 + Random().nextInt(min(2, moves.length - 1)), moves.length - 1);
    }

    return Move(row: -1, col: moves[chosenIndex].key, player: aiPlayer);
  }

  int _minimax(List<List<CellContent>> board, int depth, bool isMax, int aiPlayer, int alpha, int beta) {
    final winner = _checkWinner(board);
    if (winner == aiPlayer) return _win + depth;
    if (winner != null) return -_win - depth;

    if (depth == 0 || _isFull(board)) {
      return _scoreBoard(board, aiPlayer);
    }

    final opponent = aiPlayer == 1 ? 2 : 1;
    final current = isMax ? aiPlayer : opponent;
    final piece = _piece(current);

    int best = isMax ? -_win : _win;

    for (int c = 0; c < cols; c++) {
      final r = _lowestEmpty(board, c);
      if (r == -1) continue;

      board[r][c] = piece;
      final val = _minimax(board, depth - 1, !isMax, aiPlayer, alpha, beta);
      board[r][c] = CellContent.empty;

      if (isMax) {
        best = max(best, val);
        alpha = max(alpha, best);
      } else {
        best = min(best, val);
        beta = min(beta, best);
      }

      if (alpha >= beta) break;
    }

    return best;
  }

  // ─────────────────────────────────────────────────────────────
  // 4 Directions & Blocks → Progressive Lookahead
  // ─────────────────────────────────────────────────────────────

  Move? _progressiveHeuristic(GameState gs, int aiPlayer) {
    final mode = gs.config!.gameMode;
    final opponent = aiPlayer == 1 ? 2 : 1;

    Move? best;
    int bestScore = -_win;

    void evaluateMove(Move m, List<List<CellContent>> board) {
      // Immediate win
      if (_checkWinner(board) == aiPlayer) {
        best = m;
        bestScore = _win;
        return;
      }

      int score;

      if (level >= 4) {
        score = _lookahead(board, aiPlayer);
      } else {
        score = _scoreBoard(board, aiPlayer);
      }

      if (score > bestScore) {
        bestScore = score;
        best = m;
      }
    }

    // Insert moves
    for (final side in Side.values) {
      final count = (side == Side.left || side == Side.right) ? rows : cols;

      for (int i = 0; i < count; i++) {
        final board = _cloneBoard(gs.board);
        if (!_simulateInsert(board, side, i, aiPlayer)) continue;

        evaluateMove(Move(row: side.index, col: i, player: aiPlayer), board);
      }
    }

    // Blocks mode
    if (mode == GameMode.blocks) {
      final blocksLeft = aiPlayer == 1 ? gs.blocksRemaining1 : gs.blocksRemaining2;

      if (blocksLeft > 0) {
        for (int r = 0; r < rows; r++) {
          for (int c = 0; c < cols; c++) {
            if (gs.board[r][c] != CellContent.empty) continue;

            final board = _cloneBoard(gs.board);
            board[r][c] = aiPlayer == 1 ? CellContent.block1 : CellContent.block2;

            int score = _scoreBoard(board, aiPlayer) - _blockBias;

            // bonus difensivo forte
            if (_scoreBoard(board, opponent) < -_threeWeight) {
              score += 200;
            }

            if (score > bestScore) {
              bestScore = score;
              best = Move(row: r, col: c, player: aiPlayer, isBlock: true);
            }
          }
        }
      }
    }

    return best;
  }

  int _lookahead(List<List<CellContent>> board, int aiPlayer) {
    final opponent = aiPlayer == 1 ? 2 : 1;
    int worstReply = _win;

    for (final side in Side.values) {
      final count = (side == Side.left || side == Side.right) ? rows : cols;

      for (int i = 0; i < count; i++) {
        final temp = _cloneBoard(board);
        if (!_simulateInsert(temp, side, i, opponent)) continue;

        final s = _scoreBoard(temp, aiPlayer);
        worstReply = min(worstReply, s);
      }
    }

    return worstReply == _win ? _scoreBoard(board, aiPlayer) : worstReply;
  }

  // ─────────────────────────────────────────────────────────────
  // Heuristic
  // ─────────────────────────────────────────────────────────────

  int _scoreBoard(List<List<CellContent>> board, int aiPlayer) {
    final aiPiece = _piece(aiPlayer);
    final oppPiece = _piece(aiPlayer == 1 ? 2 : 1);

    int score = 0;

    for (int r = 0; r < rows; r++) {
      if (board[r][cols ~/ 2] == aiPiece) score += 3;
    }

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
            final nr = r + d[0] * k;
            final nc = c + d[1] * k;

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
          }

          if (!valid) continue;

          if (opp == 0) {
            if (ai == 4) {
              score += _win;
            } else if (ai == 3 && empty == 1) {
              score += _threeWeight;
            } else if (ai == 2 && empty == 2) {
              score += _twoWeight;
            }
          }

          if (ai == 0) {
            if (opp == 4) {
              score -= _win;
            } else if (opp == 3 && empty == 1) {
              score -= _threeWeight + 20;
            } else if (opp == 2 && empty == 2) {
              score -= _twoWeight + 5;
            }
          }
        }
      }
    }

    return score;
  }

  // ─────────────────────────────────────────────────────────────

  CellContent _piece(int player) => player == 1 ? CellContent.player1 : CellContent.player2;

  int _lowestEmpty(List<List<CellContent>> board, int col) {
    for (int r = rows - 1; r >= 0; r--) {
      if (board[r][col] == CellContent.empty) return r;
    }
    return -1;
  }

  bool _isFull(List<List<CellContent>> board) => board.every((row) => row.every((c) => c != CellContent.empty));

  List<List<CellContent>> _cloneBoard(List<List<CellContent>> board) => board.map((r) => List<CellContent>.from(r)).toList();

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
          if (cell != CellContent.player1 && cell != CellContent.player2) {
            continue;
          }

          bool win = true;

          for (int k = 1; k < 4; k++) {
            final nr = r + d[0] * k;
            final nc = c + d[1] * k;

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

  // ─── Board simulation helpers ─────────────────────────────────────────────

  bool _simulateInsert(List<List<CellContent>> board, Side side, int index, int player) {
    final piece = player == 1 ? CellContent.player1 : CellContent.player2;
    int row, col, dr = 0, dc = 0;

    switch (side) {
      case Side.left:
        row = index;
        col = 0;
        dc = 1;
        break;
      case Side.right:
        row = index;
        col = cols - 1;
        dc = -1;
        break;
      case Side.top:
        col = index;
        row = 0;
        dr = 1;
        break;
      case Side.bottom:
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
}
