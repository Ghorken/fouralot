import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fouralot/models/game_models.dart';
import 'package:fouralot/services/network_service.dart';

import 'game_screen.dart';

class GameModeScreen extends StatefulWidget {
  final ConnectionMode connectionMode;
  final int playerNumber;
  final NetworkService? networkService;

  const GameModeScreen({
    super.key,
    required this.connectionMode,
    required this.playerNumber,
    this.networkService,
  });

  @override
  State<GameModeScreen> createState() => _GameModeScreenState();
}

class _GameModeScreenState extends State<GameModeScreen> {
  StreamSubscription<GameMode>? _modeSub;
  StreamSubscription<void>? _modeAcceptedSub;
  GameMode? _selectedMode;

  bool get _isOnlineClient {
    if (widget.networkService == null) return false;
    final isOnline = widget.connectionMode == ConnectionMode.lan ||
        widget.connectionMode == ConnectionMode.internet;
    return isOnline && !widget.networkService!.isHost;
  }

  bool get _isOnlineHost {
    if (widget.networkService == null) return false;
    final isOnline = widget.connectionMode == ConnectionMode.lan ||
        widget.connectionMode == ConnectionMode.internet;
    return isOnline && widget.networkService!.isHost;
  }

  @override
  void initState() {
    super.initState();
    if (_isOnlineClient) {
      _modeSub = widget.networkService!.onModeSelected.listen((mode) {
        if (!mounted) return;
        setState(() => _selectedMode = mode);
      });
    }

    if (_isOnlineHost) {
      _modeAcceptedSub = widget.networkService!.onModeAccepted.listen((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('Modalità accettata dal giocatore 2'),
              duration: Duration(milliseconds: 1200),
            ),
          );
      });
    }
  }

  @override
  void dispose() {
    _modeSub?.cancel();
    _modeAcceptedSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F0C29), Color(0xFF302B63), Color(0xFF24243E)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.arrow_back_ios,
                          color: Colors.white54),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      _isOnlineClient ? 'MODALITÀ HOST' : 'MODALITÀ DI GIOCO',
                      style: GoogleFonts.orbitron(
                        color: const Color(0xFFFFD700),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                if (_isOnlineClient)
                  _buildClientView()
                else
                  _buildSelectableModes(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectableModes(BuildContext context) {
    return Column(
      children: [
        _ModeCard(
          delay: 100,
          title: 'NORMALE',
          icon: '⬇️',
          color: const Color(0xFFFF6B6B),
          description:
              'Le regole classiche del Forza 4. Inserisci le pedine dall\'alto e forma una fila di 4.',
          onTap: () => _startGame(context, GameMode.normal),
        ),
        const SizedBox(height: 16),
        _ModeCard(
          delay: 200,
          title: '4 DIREZIONI',
          icon: '↔️',
          color: const Color(0xFF4ECDC4),
          description:
              'Inserisci le pedine da qualsiasi lato della griglia toccando le frecce ↑↓←→. La pedina scivola fino al lato opposto o a un\'altra pedina.',
          onTap: () => _startGame(context, GameMode.fourDirections),
        ),
        const SizedBox(height: 16),
        _ModeCard(
          delay: 300,
          title: 'BLOCCHI',
          icon: '🧱',
          color: const Color(0xFFFFD700),
          description:
              'Come 4 Direzioni (usa le frecce ↑↓←→), ma ogni giocatore ha 3 blocchi da posizionare al posto di una mossa. Le pedine si fermano anche sui blocchi.',
          onTap: () => _startGame(context, GameMode.blocks),
        ),
      ],
    );
  }

  Widget _buildClientView() {
    final selectedMode = _selectedMode;
    final selectedData = selectedMode == null ? null : _modeInfo(selectedMode);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color:
                    (selectedData == null ? Colors.white24 : selectedData.color)
                        .withValues(alpha: 0.4)),
          ),
          child: selectedData == null
              ? const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('In attesa che l\'host scelga la modalità...',
                        style: TextStyle(color: Colors.white70, fontSize: 14)),
                    SizedBox(height: 12),
                    LinearProgressIndicator(
                        minHeight: 6,
                        color: Color(0xFFFFD700),
                        backgroundColor: Colors.white10),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(selectedData.title,
                        style: GoogleFonts.orbitron(
                            color: selectedData.color,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2)),
                    const SizedBox(height: 10),
                    Text(selectedData.description,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13, height: 1.4)),
                  ],
                ),
        ).animate().fadeIn(duration: 350.ms),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _selectedMode == null ? null : _acceptMode,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD700),
              foregroundColor: Colors.black,
              disabledBackgroundColor: Colors.white12,
              disabledForegroundColor: Colors.white38,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            child: Text(
              'ACCETTA MODALITÀ',
              style: GoogleFonts.orbitron(
                  fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 2),
            ),
          ),
        ),
      ],
    );
  }

  void _acceptMode() {
    final mode = _selectedMode;
    if (mode == null) return;
    widget.networkService?.sendModeAccepted();
    _openGame(mode);
  }

  void _startGame(BuildContext context, GameMode mode) {
    if (_isOnlineHost) {
      widget.networkService?.sendSelectedMode(mode);
    }
    _openGame(mode);
  }

  void _openGame(GameMode mode) {
    final config =
        GameConfig(connectionMode: widget.connectionMode, gameMode: mode);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GameScreen(
          config: config,
          playerNumber: widget.playerNumber,
          networkService: widget.networkService,
        ),
      ),
    );
  }

  _ModeData _modeInfo(GameMode mode) {
    switch (mode) {
      case GameMode.normal:
        return const _ModeData(
          title: 'NORMALE',
          color: Color(0xFFFF6B6B),
          description:
              'Le regole classiche del Forza 4. Inserisci le pedine dall\'alto e forma una fila di 4.',
        );
      case GameMode.fourDirections:
        return const _ModeData(
          title: '4 DIREZIONI',
          color: Color(0xFF4ECDC4),
          description:
              'Inserisci le pedine da qualsiasi lato della griglia toccando le frecce ↑↓←→. La pedina scivola fino al lato opposto o a un\'altra pedina.',
        );
      case GameMode.blocks:
        return const _ModeData(
          title: 'BLOCCHI',
          color: Color(0xFFFFD700),
          description:
              'Come 4 Direzioni (usa le frecce ↑↓←→), ma ogni giocatore ha 3 blocchi da posizionare al posto di una mossa. Le pedine si fermano anche sui blocchi.',
        );
    }
  }
}

class _ModeData {
  final String title;
  final Color color;
  final String description;

  const _ModeData({
    required this.title,
    required this.color,
    required this.description,
  });
}

class _ModeCard extends StatefulWidget {
  final String title;
  final String icon;
  final Color color;
  final String description;
  final int delay;
  final VoidCallback onTap;

  const _ModeCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.description,
    required this.delay,
    required this.onTap,
  });

  @override
  State<_ModeCard> createState() => _ModeCardState();
}

class _ModeCardState extends State<_ModeCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: widget.color.withValues(alpha: 0.4)),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.1),
                blurRadius: 20,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child:
                      Text(widget.icon, style: const TextStyle(fontSize: 28)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: GoogleFonts.orbitron(
                        color: widget.color,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.description,
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 12, height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.play_arrow_rounded, color: widget.color, size: 28),
            ],
          ),
        )
            .animate()
            .fadeIn(
                delay: Duration(milliseconds: widget.delay), duration: 400.ms)
            .slideX(begin: 0.2, end: 0),
      ),
    );
  }
}
