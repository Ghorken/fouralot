import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import 'package:fouralot/models/game_models.dart';
import 'package:fouralot/models/game_state.dart';
import 'package:fouralot/services/network_service.dart';
import 'package:fouralot/services/ai_service.dart';
import 'package:fouralot/widgets/game_board.dart';
import 'package:fouralot/l10n/app_localizations.dart';

class GameScreen extends StatefulWidget {
  final GameConfig config;
  final int playerNumber;
  final NetworkService? networkService;
  const GameScreen({
    super.key,
    required this.config,
    required this.playerNumber,
    this.networkService,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  StreamSubscription<Move>? _moveSub;
  StreamSubscription<void>? _surrenderSub;
  bool _blockMode = false; // true when player wants to place a block
  bool _aiLevelAwarded = false;
  late GameState _gameState;

  bool get _isMyTurn {
    final gs = context.read<GameState>();
    if (widget.config.connectionMode == ConnectionMode.local) return true;
    if (widget.config.connectionMode == ConnectionMode.ai) {
      return gs.currentPlayer == 1;
    }
    return gs.currentPlayer == widget.playerNumber;
  }

  bool get _isMultiplayer =>
      widget.config.connectionMode == ConnectionMode.lan ||
      widget.config.connectionMode == ConnectionMode.internet;
  bool get _isAiMode => widget.config.connectionMode == ConnectionMode.ai;

  Future<void> _showExitDialog(GameState gs) async {
    final l10n = context.l10n;
    await showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1A1A3E), Color(0xFF0F0C29)],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFFFD700).withValues(alpha: 0.45),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD700).withValues(alpha: 0.12),
                blurRadius: 24,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.exitDialogTitle,
                style: GoogleFonts.orbitron(
                  color: const Color(0xFFFFD700),
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.exitDialogMessage,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                        foregroundColor: Colors.white70,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        l10n.cancel,
                        style: GoogleFonts.orbitron(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (_isMultiplayer) {
                          widget.networkService?.sendSurrender();
                        }
                        gs.abandonGame();
                        Navigator.pop(dialogContext);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6B6B),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        l10n.exit,
                        style: GoogleFonts.orbitron(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.8,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _gameState = context.read<GameState>();
      _gameState.startGame(widget.config);
      _initCoinFlip();
    });

    // Listen for remote moves
    if (widget.networkService != null) {
      _moveSub = widget.networkService!.onMove.listen(_applyRemote);
      _surrenderSub = widget.networkService!.onSurrender.listen((_) {
        _applyRemoteSurrender();
      });
    }
  }

  void _applyRemote(Move move) {
    if (!mounted) return;
    context.read<GameState>().applyRemoteMove(move);
  }

  void _applyRemoteSurrender() {
    final l10n = context.l10n;
    if (!mounted) return;
    final gs = context.read<GameState>();
    if (!gs.gameOver) {
      gs.opponentRetired(widget.playerNumber);
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(l10n.opponentRetiredVictory),
          duration: const Duration(milliseconds: 1800),
        ),
      );
  }

  @override
  void dispose() {
    _moveSub?.cancel();
    _surrenderSub?.cancel();
    // Defer reset to next frame: notifyListeners() cannot fire while the tree is locked
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _gameState.resetBoard();
    });
    super.dispose();
  }

  void _sendMove(Move move) {
    widget.networkService?.sendMove(move);
  }

  void _handleColumnTap(int col) {
    final l10n = context.l10n;
    if (!_isMyTurn) return;
    final gs = context.read<GameState>();
    if (gs.gameOver) return;

    if (_blockMode) return;

    if (gs.dropInColumn(col)) {
      final move = Move(row: -1, col: col, player: widget.playerNumber);
      _sendMove(move);
      setState(() => _blockMode = false);
      if (_isAiMode) _scheduleAiMove();
    } else {
      _showInvalidMoveToast(l10n.invalidColumn);
    }
  }

  void _handleCellTap(int row, int col) {
    final l10n = context.l10n;
    if (!_isMyTurn) return;
    final gs = context.read<GameState>();
    if (gs.gameOver) return;

    if (_blockMode) {
      if (gs.placeBlock(row, col)) {
        _sendMove(Move(
            row: row, col: col, player: widget.playerNumber, isBlock: true));
        setState(() => _blockMode = false);
        if (_isAiMode) _scheduleAiMove();
      } else {
        _showInvalidMoveToast(l10n.invalidBlockPlacement);
      }
      return;
    }
  }

  void _showInvalidMoveToast(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            msg,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600),
          ),
          backgroundColor: const Color(0xFFFF6B6B).withValues(alpha: 0.9),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(milliseconds: 1500),
        ),
      );
  }

  void _handleSidedInsert(Side side, int index) {
    final l10n = context.l10n;
    if (!_isMyTurn) return;
    final gs = context.read<GameState>();
    if (gs.gameOver) return;

    final pos = gs.insertFromSide(side, index);
    if (pos != null) {
      _sendMove(Move(row: pos[0], col: pos[1], player: widget.playerNumber));
      if (_isAiMode) _scheduleAiMove();
    } else {
      _showInvalidMoveToast(l10n.invalidSideMove);
    }
  }

  Future<void> _initCoinFlip() async {
    if (!mounted) return;
    final int winner;
    if (_isMultiplayer) {
      if (widget.networkService!.isHost) {
        // Give the client time to start listening before sending
        await Future.delayed(const Duration(milliseconds: 500));
        if (!mounted) return;
        winner = Random().nextInt(2) + 1;
        _gameState.setStartingPlayer(winner);
        widget.networkService!.sendCoinFlip(winner);
      } else {
        winner = await widget.networkService!.onCoinFlip.first;
        if (!mounted) return;
        _gameState.setStartingPlayer(winner);
      }
    } else {
      winner = Random().nextInt(2) + 1;
      _gameState.setStartingPlayer(winner);
    }
    await _showCoinFlipDialog(winner);
    if (_isAiMode && winner == 2) _scheduleAiMove();
  }

  Future<void> _showCoinFlipDialog(int winner) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (_) => _CoinFlipDialog(
        winner: winner,
        playerNumber: widget.playerNumber,
        isMultiplayer: _isMultiplayer,
        isAiMode: _isAiMode,
      ),
    );
  }

  Future<void> _doLocalRematch(GameState gs) async {
    gs.resetBoard();
    final winner = Random().nextInt(2) + 1;
    gs.setStartingPlayer(winner);
    await _showCoinFlipDialog(winner);
  }

  /// Schedules the AI move after a short delay for a natural feel.
  void _scheduleAiMove() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      _doAiMove();
    });
  }

  /// Executes the AI's best move.
  void _doAiMove() {
    final gs = context.read<GameState>();
    if (gs.gameOver || gs.currentPlayer != 2) return;

    final move = AiService(level: widget.config.aiLevel).getBestMove(gs, 2);
    if (move == null) return;

    if (move.isBlock) {
      gs.placeBlock(move.row, move.col);
    } else if (widget.config.gameMode == GameMode.normal) {
      gs.dropInColumn(move.col);
    } else {
      // For 4-directions: move.row = side.index, move.col = index
      gs.insertFromSide(Side.values[move.row], move.col);
    }
  }

  /// Builds the board area. Uses [LayoutBuilder] to compute exact per-cell dimensions so arrows are pixel-aligned.
  Widget _buildBoardArea(GameState gs) {
    final bool isNormal = widget.config.gameMode == GameMode.normal;
    final bool enabled = _isMyTurn && !gs.gameOver;

    if (isNormal) {
      return LayoutBuilder(builder: (context, constraints) {
        const double sideH = _kSideButtonHeight;
        const double sideW = _kSideButtonWidth;
        final double availW = constraints.maxWidth;
        final double availH = constraints.maxHeight;

        final double innerW = availW - 2 * sideW;
        final double innerH = availH - 2 * sideH;

        double boardW, boardH;
        if (innerH > 0 && innerW / innerH >= cols / rows) {
          boardH = innerH;
          boardW = boardH * cols / rows;
        } else {
          boardW = innerW;
          boardH = innerW > 0 ? boardW * rows / cols : 0;
        }

        return Center(
          child: SizedBox(
            width: boardW,
            height: boardH,
            child: GameBoard(
              board: gs.board,
              winningCells: gs.winningCells,
              onColumnTap: _handleColumnTap,
              blockMode: _blockMode,
              useAspectRatio: false,
              gameMode: widget.config.gameMode,
            ),
          ),
        );
      });
    }

    return LayoutBuilder(builder: (context, constraints) {
      const double arrowH = 40.0;
      const double sideW = _kSideButtonWidth;
      final double availW = constraints.maxWidth;
      final double availH = constraints.maxHeight;

      final double innerW = availW - 2 * sideW;
      final double innerH = availH - 2 * arrowH;

      double boardW, boardH;
      if (innerH > 0 && innerW / innerH >= cols / rows) {
        boardH = innerH;
        boardW = boardH * cols / rows;
      } else {
        boardW = innerW;
        boardH = innerW > 0 ? boardW * rows / cols : 0;
      }

      final double cellW = cols > 0 ? boardW / cols : 0;
      final double cellH = rows > 0 ? boardH / rows : 0;
      final double hOff = (innerW - boardW) / 2;

      Widget colArrow(IconData icon, int i, Side side) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: enabled ? () => _handleSidedInsert(side, i) : null,
          child: SizedBox(
            width: cellW,
            height: arrowH,
            child: Center(
              child: Icon(
                icon,
                color: enabled ? const Color(0xFF4ECDC4) : Colors.white12,
                size: _kArrowIconSize,
              ),
            ),
          ),
        );
      }

      Widget rowArrow(IconData icon, int i, Side side) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: enabled ? () => _handleSidedInsert(side, i) : null,
          child: SizedBox(
            width: sideW,
            height: cellH,
            child: Center(
              child: Icon(
                icon,
                color: enabled ? const Color(0xFFFF6B6B) : Colors.white12,
                size: _kArrowIconSize,
              ),
            ),
          ),
        );
      }

      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: arrowH,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(width: sideW + hOff),
                ...List.generate(
                    cols, (i) => colArrow(Icons.arrow_downward, i, Side.top)),
                SizedBox(width: sideW + hOff),
              ],
            ),
          ),
          SizedBox(
            height: boardH,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                    children: List.generate(rows,
                        (i) => rowArrow(Icons.arrow_forward, i, Side.left))),
                SizedBox(width: hOff),
                SizedBox(
                  width: boardW,
                  height: boardH,
                  child: GameBoard(
                    board: gs.board,
                    winningCells: gs.winningCells,
                    onCellTap: _handleCellTap,
                    blockMode: _blockMode,
                    useAspectRatio: false,
                    gameMode: widget.config.gameMode,
                  ),
                ),
                SizedBox(width: hOff),
                Column(
                    children: List.generate(rows,
                        (i) => rowArrow(Icons.arrow_back, i, Side.right))),
              ],
            ),
          ),
          SizedBox(
            height: arrowH,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(width: sideW + hOff),
                ...List.generate(
                    cols, (i) => colArrow(Icons.arrow_upward, i, Side.bottom)),
                SizedBox(width: sideW + hOff),
              ],
            ),
          ),
        ],
      );
    });
  }

  void _handleAiLevelProgress(GameState gs) {
    final l10n = context.l10n;
    if (!_isAiMode) return;
    if (!gs.gameOver) {
      _aiLevelAwarded = false;
      return;
    }
    if (_aiLevelAwarded) return;
    _aiLevelAwarded = true;

    if (gs.winner == 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final currentLevel = widget.config.aiLevel;
        context.read<GameState>().increaseAiLevel(widget.config.gameMode);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content:
                  Text(l10n.aiLevelDefeated(currentLevel, currentLevel + 1)),
              duration: const Duration(milliseconds: 1800),
            ),
          );
      });
    }
  }

  void _startNextAiMatch() {
    final gs = context.read<GameState>();
    final nextLevel = gs.aiLevelForMode(widget.config.gameMode);
    gs.resetBoard();
    final nextConfig = GameConfig(
      connectionMode: widget.config.connectionMode,
      gameMode: widget.config.gameMode,
      aiLevel: nextLevel,
    );
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => GameScreen(
          config: nextConfig,
          playerNumber: widget.playerNumber,
          networkService: widget.networkService,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, gs, _) {
        _handleAiLevelProgress(gs);
        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF0F0C29), Color(0xFF1a1a3e)],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  _buildHeader(gs),
                  const SizedBox(height: 8),
                  _buildPlayerIndicator(gs),
                  const SizedBox(height: 8),
                  Expanded(child: _buildBoardArea(gs)),
                  _buildBottomBar(gs),
                  if (gs.gameOver) _buildGameOverBanner(gs),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(GameState gs) {
    final l10n = context.l10n;
    final modeName = l10n.modeName(widget.config.gameMode);
    final levelLabel = _isAiMode ? ' · LV ${widget.config.aiLevel}' : '';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _showExitDialog(gs),
            child: const Icon(Icons.arrow_back_ios,
                color: Colors.white70, size: 26),
          ),
          const SizedBox(width: 12),
          Text(
            '4alot · $modeName$levelLabel',
            style: GoogleFonts.orbitron(
              color: Colors.white70,
              fontSize: 16,
              letterSpacing: 2.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          if (_isAiMode)
            GestureDetector(
              onTap: () => gs.resetBoard(),
              child: const Icon(Icons.refresh, color: Colors.white54, size: 28),
            ),
        ],
      ),
    );
  }

  Widget _buildPlayerIndicator(GameState gs) {
    final l10n = context.l10n;
    const p1Color = Color(0xFFFF6B6B);
    const p2Color = Color(0xFFFFD700);
    bool myTurn = _isMyTurn && !gs.gameOver;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _PlayerChip(
            label: _isMultiplayer
                ? (widget.playerNumber == 1 ? l10n.you : l10n.playerN(1))
                : l10n.playerN(1),
            color: p1Color,
            active: gs.currentPlayer == 1 && !gs.gameOver,
          ),
          const Spacer(),
          if (!gs.gameOver)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: myTurn
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                myTurn
                    ? l10n.yourTurn
                    : (_isAiMode ? l10n.aiThinking : l10n.opponent),
                style: GoogleFonts.orbitron(
                  color: myTurn ? Colors.white : Colors.white38,
                  fontSize: 9,
                  letterSpacing: 1,
                ),
              ),
            ),
          const Spacer(),
          _PlayerChip(
            label: _isMultiplayer
                ? (widget.playerNumber == 2 ? l10n.you : l10n.playerN(2))
                : (_isAiMode
                    ? l10n.aiLevelChip(widget.config.aiLevel)
                    : l10n.playerN(2)),
            color: p2Color,
            active: gs.currentPlayer == 2 && !gs.gameOver,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(GameState gs) {
    final l10n = context.l10n;
    if (widget.config.gameMode != GameMode.blocks) {
      return const SizedBox(height: 8);
    }
    if (gs.gameOver) return const SizedBox(height: 8);

    int blocksLeft = gs.currentPlayerBlocks;
    bool canBlock = blocksLeft > 0 && _isMyTurn;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(l10n.blocksLabel,
              style: const TextStyle(color: Colors.white54, fontSize: 12)),
          ...List.generate(
              3,
              (i) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Icon(
                      Icons.square,
                      color: i < blocksLeft
                          ? const Color(0xFFFFD700)
                          : Colors.white12,
                      size: 18,
                    ),
                  )),
          const SizedBox(width: 16),
          if (canBlock)
            GestureDetector(
              onTap: () => setState(() => _blockMode = !_blockMode),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: _blockMode
                      ? const Color(0xFFFFD700)
                      : Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.square,
                        color:
                            _blockMode ? Colors.black : const Color(0xFFFFD700),
                        size: 14),
                    const SizedBox(width: 6),
                    Text(
                      _blockMode ? l10n.cancel : l10n.placeBlock,
                      style: GoogleFonts.orbitron(
                        color:
                            _blockMode ? Colors.black : const Color(0xFFFFD700),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGameOverBanner(GameState gs) {
    final l10n = context.l10n;
    String msg;
    Color color;
    if (gs.winner == 0) {
      msg = l10n.draw;
      color = Colors.white;
    } else if (_isAiMode) {
      msg = gs.winner == 1
          ? l10n.youWinLevel(widget.config.aiLevel)
          : l10n.aiWinsLevel(widget.config.aiLevel);
      color =
          gs.winner == 1 ? const Color(0xFFFFD700) : const Color(0xFFFF6B6B);
    } else if (_isMultiplayer) {
      msg = gs.winner == widget.playerNumber ? l10n.youWin : l10n.youLose;
      color = gs.winner == widget.playerNumber
          ? const Color(0xFFFFD700)
          : const Color(0xFFFF6B6B);
    } else {
      msg = l10n.playerWins(gs.winner);
      color =
          gs.winner == 1 ? const Color(0xFFFF6B6B) : const Color(0xFFFFD700);
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Text(
            msg,
            style: GoogleFonts.orbitron(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.menu,
                    style: const TextStyle(
                        color: Colors.white54, letterSpacing: 2)),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: _isAiMode
                    ? _startNextAiMatch
                    : _isMultiplayer
                        ? () => gs.resetBoard()
                        : () => _doLocalRematch(gs),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(
                  _isAiMode ? l10n.newMatch : l10n.rematch,
                  style: GoogleFonts.orbitron(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2),
                ),
              ),
            ],
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms)
        .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1));
  }
}

class _PlayerChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool active;

  const _PlayerChip(
      {required this.label, required this.color, required this.active});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: active ? color.withValues(alpha: 0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: active ? color : Colors.transparent),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: active
                  ? [
                      BoxShadow(
                          color: color.withValues(alpha: 0.5), blurRadius: 6)
                    ]
                  : null,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.orbitron(
              color: active ? Colors.white : Colors.white38,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _CoinFlipDialog extends StatefulWidget {
  final int winner;
  final int playerNumber;
  final bool isMultiplayer;
  final bool isAiMode;

  const _CoinFlipDialog({
    required this.winner,
    required this.playerNumber,
    required this.isMultiplayer,
    required this.isAiMode,
  });

  @override
  State<_CoinFlipDialog> createState() => _CoinFlipDialogState();
}

class _CoinFlipDialogState extends State<_CoinFlipDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _revealed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    )..repeat();

    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        _controller.stop();
        setState(() => _revealed = true);
      }
    });

    Future.delayed(const Duration(milliseconds: 4500), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    const p1Color = Color(0xFFFF6B6B);
    const p2Color = Color(0xFFFFD700);

    final String resultText;
    final Color resultColor;
    if (widget.isMultiplayer) {
      if (widget.winner == widget.playerNumber) {
        resultText = l10n.coinFlipYouStart;
        resultColor = p2Color;
      } else {
        resultText = l10n.coinFlipOpponentStarts;
        resultColor = p1Color;
      }
    } else if (widget.isAiMode) {
      resultText =
          widget.winner == 1 ? l10n.coinFlipYouStart : l10n.coinFlipAiStarts;
      resultColor = widget.winner == 1 ? p2Color : p1Color;
    } else {
      resultText = l10n.coinFlipPlayerStarts(widget.winner);
      resultColor = widget.winner == 1 ? p1Color : p2Color;
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A1A3E), Color(0xFF0F0C29)],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFFFFD700).withValues(alpha: 0.35),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFD700).withValues(alpha: 0.12),
              blurRadius: 32,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.coinFlipTitle,
              style: GoogleFonts.orbitron(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 28),
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final t = _controller.value;
                final scaleX = _revealed
                    ? 1.0
                    : cos(t * 2 * pi).abs().clamp(0.05, 1.0);
                final showPlayer1 = _revealed
                    ? widget.winner == 1
                    : cos(t * 2 * pi) >= 0;
                final faceColor = showPlayer1 ? p1Color : p2Color;

                return Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()..scale(scaleX, 1.0),
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        center: const Alignment(-0.3, -0.3),
                        radius: 0.8,
                        colors: [
                          faceColor.withValues(alpha: 0.9),
                          faceColor.withValues(alpha: 0.5),
                        ],
                      ),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: faceColor.withValues(alpha: 0.4),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        showPlayer1 ? '1' : '2',
                        style: GoogleFonts.orbitron(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            if (_revealed)
              Column(
                children: [
                  Text(
                    resultText,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.orbitron(
                      color: resultColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 400.ms)
                      .scale(begin: const Offset(0.8, 0.8)),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Text(
                      l10n.coinFlipTapToContinue,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 10,
                      ),
                    ),
                  ).animate().fadeIn(delay: 700.ms, duration: 400.ms),
                ],
              )
            else
              Text(
                l10n.coinFlipFlipping,
                style: GoogleFonts.orbitron(
                  color: Colors.white38,
                  fontSize: 10,
                  letterSpacing: 1.5,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Arrow size constants used by _buildBoardArea
const double _kSideButtonWidth = 40.0;
const double _kSideButtonHeight = 40.0;
const double _kArrowIconSize = 26.0;
