import 'package:flutter/material.dart';
import 'package:fouralot/models/game_models.dart';
import 'package:fouralot/models/game_state.dart';

class GameBoard extends StatelessWidget {
  final List<List<CellContent>> board;
  final List<List<int>> winningCells;
  final void Function(int col) onColumnTap;
  final void Function(int row, int col) onCellTap;
  final bool showColumnTap;
  final bool blockMode;
  final bool useAspectRatio;

  const GameBoard({
    super.key,
    required this.board,
    required this.winningCells,
    required this.onColumnTap,
    required this.onCellTap,
    required this.showColumnTap,
    required this.blockMode,
    this.useAspectRatio = true,
  });

  bool _isWinning(int row, int col) {
    return winningCells.any((c) => c[0] == row && c[1] == col);
  }

  @override
  Widget build(BuildContext context) {
    final grid = LayoutBuilder(builder: (context, constraints) {
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E3A8A),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: List.generate(
              rows,
              (row) => Expanded(
                    child: Row(
                      children: List.generate(cols, (col) {
                        final content = board[row][col];
                        final winning = _isWinning(row, col);
                        return Expanded(
                          child: GestureDetector(
                            onTap: () {
                              if (showColumnTap && !blockMode) {
                                onColumnTap(col);
                              } else {
                                onCellTap(row, col);
                              }
                            },
                            child: _Cell(content: content, winning: winning, blockMode: blockMode && content == CellContent.empty),
                          ),
                        );
                      }),
                    ),
                  )),
        ),
      );
    });

    if (!useAspectRatio) return grid;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: AspectRatio(
        aspectRatio: cols / rows,
        child: grid,
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  final CellContent content;
  final bool winning;
  final bool blockMode;

  const _Cell({required this.content, required this.winning, required this.blockMode});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          shape: (content == CellContent.block1 || content == CellContent.block2) ? BoxShape.rectangle : BoxShape.circle,
          color: _color,
          boxShadow: winning
              ? [BoxShadow(color: _color.withValues(alpha: 0.8), blurRadius: 12, spreadRadius: 2)]
              : content != CellContent.empty
                  ? [BoxShadow(color: _color.withValues(alpha: 0.4), blurRadius: 6)]
                  : null,
          border: blockMode ? Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.4), width: 1.5) : null,
        ),
        child: winning
            ? const Center(
                child: Icon(Icons.star, color: Colors.white, size: 14),
              )
            : null,
      ),
    );
  }

  Color get _color {
    switch (content) {
      case CellContent.player1:
        return const Color(0xFFFF6B6B);
      case CellContent.player2:
        return const Color(0xFFFFD700);
      case CellContent.block1:
        return const Color(0xFFAA2222); // dark red — player 1's block
      case CellContent.block2:
        return const Color(0xFFB8860B); // dark gold — player 2's block
      case CellContent.empty:
        return const Color(0xFF0D2260);
    }
  }
}
