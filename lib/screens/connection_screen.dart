import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fouralot/models/game_models.dart';
import 'package:fouralot/services/network_service.dart';
import 'package:fouralot/screens/game_mode_screen.dart';

class ConnectionScreen extends StatefulWidget {
  final ConnectionMode connectionMode;
  const ConnectionScreen({super.key, required this.connectionMode});

  @override
  State<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends State<ConnectionScreen> {
  final NetworkService _networkService = NetworkService();
  String _status = '';
  bool _connected = false;
  bool _loading = false;
  String? _localIp;
  final TextEditingController _ipController = TextEditingController();
  int _playerNumber = 1;
  StreamSubscription? _statusSub;

  @override
  void initState() {
    super.initState();
    _initOnline();
  }

  Future<void> _initOnline() async {
    _localIp = await _networkService.getLocalIp();
    setState(() {});
    _statusSub = _networkService.onStatus.listen((s) {
      setState(() => _status = s);
      if (s == 'connected') {
        setState(() {
          _connected = true;
          _playerNumber = _networkService.playerNumber;
        });
      }
    });
  }

  @override
  void dispose() {
    _statusSub?.cancel();
    _ipController.dispose();
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
                _buildHeader(),
                const SizedBox(height: 32),
                _buildOnlineSection(),
                const Spacer(),
                if (_connected) _buildContinueButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    Color color = const Color(0xFF4ECDC4);

    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back_ios, color: Colors.white54),
        ),
        const SizedBox(width: 16),
        Text(
          'CONNESSIONE ONLINE',
          style: GoogleFonts.orbitron(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildOnlineSection() {
    final isInternet = widget.connectionMode == ConnectionMode.internet;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isInternet && _localIp != null) ...[
          _InfoCard(
            icon: Icons.info_outline,
            color: const Color(0xFF4ECDC4),
            title: 'Il tuo IP',
            body: 'Condividi questo IP con l\'altro giocatore: $_localIp',
          ),
          const SizedBox(height: 20),
        ],
        if (isInternet) ...[
          _InfoCard(
            icon: Icons.public,
            color: const Color(0xFFFBBF24),
            title: 'Internet Multiplayer',
            body: 'Crea una stanza e condividi il codice, oppure inserisci un codice per unirti.',
          ),
          const SizedBox(height: 20),
        ],
        if (_networkService.isHost && isInternet && _networkService.generatedRoomCode.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFFBBF24).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFBBF24)),
            ),
            child: Column(
              children: [
                Text('CODICE STANZA', style: GoogleFonts.orbitron(color: Colors.white54, fontSize: 11, letterSpacing: 2)),
                const SizedBox(height: 8),
                Text(
                  _networkService.generatedRoomCode,
                  style: GoogleFonts.orbitron(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 8),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
        Text('CREA PARTITA', style: GoogleFonts.orbitron(color: Colors.white54, fontSize: 11, letterSpacing: 2)),
        const SizedBox(height: 8),
        _ActionButton(
          label: 'OSPITA',
          icon: isInternet ? Icons.cloud : Icons.dns,
          color: isInternet ? const Color(0xFFFBBF24) : const Color(0xFF4ECDC4),
          loading: _loading && _networkService.isHost,
          onTap: _status.isEmpty ? _hostOnline : null,
        ),
        const SizedBox(height: 20),
        Text('UNISCITI', style: GoogleFonts.orbitron(color: Colors.white54, fontSize: 11, letterSpacing: 2)),
        const SizedBox(height: 8),
        TextField(
          controller: _ipController,
          style: const TextStyle(color: Colors.white),
          keyboardType: isInternet ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(
            hintText: isInternet ? 'Inserisci codice stanza (es. 12345)' : 'Inserisci IP dell\'host (es. 192.168.1.10)',
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: (isInternet ? const Color(0xFFFBBF24) : const Color(0xFF4ECDC4)).withValues(alpha: 0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: (isInternet ? const Color(0xFFFBBF24) : const Color(0xFF4ECDC4)).withValues(alpha: 0.3)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _ActionButton(
          label: 'CONNETTI',
          icon: Icons.link,
          color: isInternet ? const Color(0xFFFBBF24) : const Color(0xFF4ECDC4),
          loading: _loading && !_networkService.isHost,
          onTap: _status.isEmpty ? _connectOnline : null,
        ),
        if (_status.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            _statusLabel(_status),
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ],
    );
  }

  Widget _buildContinueButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _goToGameMode,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFFD700),
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Text(
          _networkService.isHost ? 'SCEGLI MODALITÀ DI GIOCO' : 'VEDI MODALITÀ HOST',
          style: GoogleFonts.orbitron(
            fontWeight: FontWeight.w900,
            fontSize: 14,
            letterSpacing: 2,
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.3, end: 0);
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'connecting':
        return '⏳ Connessione in corso...';
      case 'hosting':
        return '⏳ In attesa di un giocatore...';
      case 'connected':
        return '✅ Connesso!';
      case 'disconnected':
        return '❌ Disconnesso';
      case 'error':
        return '❌ Errore di connessione';
      default:
        return s;
    }
  }

  Future<void> _hostOnline() async {
    setState(() => _loading = true);
    if (widget.connectionMode == ConnectionMode.lan) {
      await _networkService.startLanHost();
    } else {
      await _networkService.startInternetHost();
    }
    setState(() => _loading = false);
  }

  Future<void> _connectOnline() async {
    final input = _ipController.text.trim();
    if (input.isEmpty) return;

    setState(() => _loading = true);
    bool ok;
    if (widget.connectionMode == ConnectionMode.lan) {
      ok = await _networkService.connectToLanHost(input);
    } else {
      ok = await _networkService.connectToInternetHost(input);
    }

    setState(() {
      _loading = false;
      if (!ok) _status = 'error';
    });
  }

  void _goToGameMode() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GameModeScreen(
          connectionMode: widget.connectionMode,
          playerNumber: _playerNumber,
          networkService: _networkService,
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String body;

  const _InfoCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text(body, style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool loading;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.loading,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: onTap != null ? color.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: onTap != null ? 0.4 : 0.1)),
        ),
        child: Row(
          children: [
            loading
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: color),
                  )
                : Icon(icon, color: color, size: 22),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.orbitron(
                color: onTap != null ? Colors.white : Colors.white38,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
