enum ConnectionMode { local, lan, internet, ai }

enum GameMode { normal, fourDirections, blocks }

enum CellContent { empty, player1, player2, block1, block2 }

enum Side { left, right, top, bottom }

class GameConfig {
  final ConnectionMode connectionMode;
  final GameMode gameMode;
  final int aiLevel;

  const GameConfig({
    required this.connectionMode,
    required this.gameMode,
    this.aiLevel = 1,
  });
}

class Move {
  final int row;
  final int col;
  final int player; // 1 or 2
  final bool isBlock;

  const Move({
    required this.row,
    required this.col,
    required this.player,
    this.isBlock = false,
  });

  Map<String, dynamic> toJson() => {
        'row': row,
        'col': col,
        'player': player,
        'isBlock': isBlock,
      };

  factory Move.fromJson(Map<String, dynamic> json) => Move(
        row: json['row'],
        col: json['col'],
        player: json['player'],
        isBlock: json['isBlock'] ?? false,
      );
}
