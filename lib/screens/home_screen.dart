import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fouralot/screens/connection_screen.dart';
import 'package:fouralot/screens/game_mode_screen.dart';
import 'package:fouralot/models/game_models.dart';
import 'package:fouralot/l10n/app_localizations.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
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
          child: Column(
            children: [
              const Spacer(flex: 2),
              // Logo
              _buildLogo(),
              const Spacer(flex: 2),
              // Connection mode
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    Text(
                      l10n.chooseOpponent,
                      style: GoogleFonts.orbitron(
                        color: Colors.white54,
                        fontSize: 12,
                        letterSpacing: 3,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _ConnectionButton(
                      icon: Icons.people,
                      label: l10n.localLabel,
                      subtitle: l10n.localSubtitle,
                      color: const Color(0xFFFF6B6B),
                      delay: 100,
                      onTap: () => _navigate(context, ConnectionMode.local),
                    ),
                    const SizedBox(height: 12),
                    _ConnectionButton(
                      icon: Icons.wifi,
                      label: 'LAN',
                      subtitle: l10n.lanSubtitle,
                      color: const Color(0xFF4ECDC4),
                      delay: 200,
                      onTap: () => _navigate(context, ConnectionMode.lan),
                    ),
                    const SizedBox(height: 12),
                    _ConnectionButton(
                      icon: Icons.public,
                      label: 'INTERNET',
                      subtitle: l10n.internetSubtitle,
                      color: const Color(0xFFFBBF24), // an amber/gold color
                      delay: 250,
                      onTap: () => _navigate(context, ConnectionMode.internet),
                    ),
                    const SizedBox(height: 12),
                    _ConnectionButton(
                      icon: Icons.smart_toy,
                      label: l10n.vsComputerLabel,
                      subtitle: l10n.vsComputerSubtitle,
                      color: const Color(0xFFA78BFA),
                      delay: 300,
                      onTap: () => _navigate(context, ConnectionMode.ai),
                    ),
                  ],
                ),
              ),
              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        // Game board logo
        _GameLogoWidget()
            .animate()
            .fadeIn(duration: 800.ms)
            .slideY(begin: -0.3, end: 0),
        const SizedBox(height: 16),
        Text(
          '4alot',
          style: GoogleFonts.orbitron(
            color: Colors.white,
            fontSize: 36,
            fontWeight: FontWeight.w900,
            letterSpacing: 8,
          ),
        ).animate().fadeIn(delay: 300.ms, duration: 600.ms),
      ],
    );
  }

  void _navigate(BuildContext context, ConnectionMode mode) {
    if (mode == ConnectionMode.local || mode == ConnectionMode.ai) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => GameModeScreen(
            connectionMode: mode,
            playerNumber: 1,
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => ConnectionScreen(connectionMode: mode)),
      );
    }
  }
}

class _GameLogoWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = [
      [
        Colors.grey.shade800,
        Colors.grey.shade800,
        Colors.grey.shade800,
        Colors.grey.shade800,
        Colors.grey.shade800,
        Colors.grey.shade800,
        Colors.grey.shade800
      ],
      [
        Colors.grey.shade800,
        Colors.grey.shade800,
        Colors.grey.shade800,
        const Color(0xFFFFD700),
        Colors.grey.shade800,
        Colors.grey.shade800,
        Colors.grey.shade800
      ],
      [
        Colors.grey.shade800,
        Colors.grey.shade800,
        const Color(0xFFFF6B6B),
        const Color(0xFFFFD700),
        Colors.grey.shade800,
        Colors.grey.shade800,
        Colors.grey.shade800
      ],
      [
        Colors.grey.shade800,
        const Color(0xFFFF6B6B),
        const Color(0xFFFF6B6B),
        const Color(0xFFFFD700),
        const Color(0xFFFFD700),
        Colors.grey.shade800,
        Colors.grey.shade800
      ],
    ];

    return SizedBox(
      height: 80,
      width: 200,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
        ),
        itemCount: 4 * 7,
        itemBuilder: (_, i) {
          int row = i ~/ 7;
          int col = i % 7;
          Color c = colors[row][col];
          return Container(
            decoration: BoxDecoration(
              color: c,
              shape: BoxShape.circle,
              boxShadow: c != Colors.grey.shade800
                  ? [BoxShadow(color: c.withValues(alpha: 0.5), blurRadius: 6)]
                  : null,
            ),
          );
        },
      ),
    );
  }
}

class _ConnectionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final int delay;
  final VoidCallback onTap;

  const _ConnectionButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.delay,
    required this.onTap,
  });

  @override
  State<_ConnectionButton> createState() => _ConnectionButtonState();
}

class _ConnectionButtonState extends State<_ConnectionButton> {
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
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: widget.color.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.1),
                blurRadius: 12,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(widget.icon, color: widget.color, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.label,
                      style: GoogleFonts.orbitron(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                      ),
                    ),
                    Text(
                      widget.subtitle,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: widget.color, size: 14),
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
