import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:firebase_database/firebase_database.dart';
import 'package:fouralot/models/game_models.dart';

/// Handles both LAN (TCP sockets) and Internet (Firebase Realtime Database)
/// multiplayer connections.
class NetworkService {
  // ─── Shared State ──────────────────────────────────────────────────────────

  bool isHost = false;
  int playerNumber = 1;
  ConnectionMode mode = ConnectionMode.lan;

  final StreamController<Move> _moveController = StreamController.broadcast();
  final StreamController<GameMode> _modeController =
      StreamController.broadcast();
  final StreamController<GameMode> _modeAcceptedController =
      StreamController.broadcast();
  final StreamController<void> _surrenderController =
      StreamController.broadcast();
  final StreamController<void> _rematchController =
      StreamController.broadcast();
  final StreamController<void> _endMatchController =
      StreamController.broadcast();
  final StreamController<String> _statusController =
      StreamController.broadcast();
  final StreamController<int> _coinFlipController =
      StreamController.broadcast();

  Stream<Move> get onMove => _moveController.stream;
  Stream<GameMode> get onModeSelected => _modeController.stream;
  Stream<GameMode> get onModeAccepted => _modeAcceptedController.stream;
  Stream<void> get onSurrender => _surrenderController.stream;
  Stream<void> get onRematch => _rematchController.stream;
  Stream<void> get onEndMatch => _endMatchController.stream;
  Stream<String> get onStatus => _statusController.stream;
  Stream<int> get onCoinFlip => _coinFlipController.stream;

  // ─── LAN State (TCP sockets) ───────────────────────────────────────────────

  ServerSocket? _server;
  Socket? _socket;
  StreamSubscription? _socketSub;

  // ─── Internet State (Firebase Realtime Database) ──────────────────────────

  DatabaseReference? _roomRef;
  StreamSubscription? _messagesSub;
  StreamSubscription? _joinedSub;
  String? _roomCode;
  String _myKey = 'p1'; // 'p1' for host, 'p2' for guest

  // ─── LAN Methods ──────────────────────────────────────────────────────────

  Future<String?> getLocalIp() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );
      for (var iface in interfaces) {
        for (var addr in iface.addresses) {
          if (!addr.isLoopback) return addr.address;
        }
      }
    } catch (_) {}
    return null;
  }

  Future<bool> startLanHost() async {
    try {
      mode = ConnectionMode.lan;
      _server = await ServerSocket.bind(InternetAddress.anyIPv4, 4242);
      isHost = true;
      playerNumber = 1;
      _statusController.add('hosting');
      _server!.first.then((socket) {
        _socket = socket;
        _statusController.add('connected');
        _listenToSocket();
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> connectToLanHost(String ip) async {
    try {
      mode = ConnectionMode.lan;
      _socket =
          await Socket.connect(ip, 4242, timeout: const Duration(seconds: 10));
      isHost = false;
      playerNumber = 2;
      _statusController.add('connected');
      _listenToSocket();
      return true;
    } catch (_) {
      return false;
    }
  }

  void _listenToSocket() {
    _socketSub = _socket!.listen(
      (Uint8List data) {
        final msg = utf8.decode(data).trim();
        for (var line in msg.split('\n')) {
          line = line.trim();
          if (line.isEmpty) continue;
          try {
            _dispatchMessage(jsonDecode(line) as Map<String, dynamic>);
          } catch (_) {}
        }
      },
      onDone: () => _statusController.add('disconnected'),
      onError: (_) => _statusController.add('error'),
    );
  }

  // ─── Internet Methods (Firebase) ──────────────────────────────────────────

  String get generatedRoomCode => _roomCode ?? '';

  Future<bool> startInternetHost() async {
    try {
      mode = ConnectionMode.internet;
      isHost = true;
      playerNumber = 1;
      _myKey = 'p1';
      _statusController.add('connecting');

      _roomCode = (10000 + Random().nextInt(90000)).toString();
      _roomRef = FirebaseDatabase.instance.ref('fouralot_rooms/$_roomCode');

      // Create room; Firebase auto-deletes it if the host disconnects.
      await _roomRef!.set({'p2_joined': false});
      await _roomRef!.onDisconnect().remove();

      // Watch for the guest to join.
      _joinedSub = _roomRef!.child('p2_joined').onValue.listen((event) {
        if (event.snapshot.value == true) {
          _joinedSub?.cancel();
          _joinedSub = null;
          _listenToFirebaseMessages();
          _statusController.add('connected');
        }
      });

      _statusController.add('hosting');
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> connectToInternetHost(String code) async {
    try {
      mode = ConnectionMode.internet;
      isHost = false;
      playerNumber = 2;
      _myKey = 'p2';
      _statusController.add('connecting');

      _roomCode = code.trim();
      _roomRef = FirebaseDatabase.instance.ref('fouralot_rooms/$_roomCode');

      // Verify the room exists before joining.
      final snap = await _roomRef!.get();
      if (!snap.exists) {
        _statusController.add('error');
        return false;
      }

      // Start listening BEFORE signalling join to avoid missing fast messages.
      _listenToFirebaseMessages();

      await _roomRef!.child('p2_joined').set(true);
      // Firebase resets p2_joined if the guest disconnects ungracefully.
      await _roomRef!.child('p2_joined').onDisconnect().remove();

      _statusController.add('connected');
      return true;
    } catch (_) {
      _statusController.add('error');
      return false;
    }
  }

  /// Subscribes to the Firebase messages queue and dispatches incoming
  /// messages from the opponent.
  void _listenToFirebaseMessages() {
    if (_roomRef == null) return;
    final oppKey = _myKey == 'p1' ? 'p2' : 'p1';

    _messagesSub =
        _roomRef!.child('messages').onChildAdded.listen((event) {
      final raw = event.snapshot.value;
      if (raw == null) return;
      final data = Map<String, dynamic>.from(raw as Map);
      // Only process messages sent by the opponent.
      if (data['from'] != oppKey) return;
      final payload = data['payload'] as String?;
      if (payload == null) return;
      try {
        _dispatchMessage(jsonDecode(payload) as Map<String, dynamic>);
      } catch (_) {}
    });
  }

  void _sendFirebase(String payload) {
    _roomRef?.child('messages').push().set({
      'from': _myKey,
      'payload': payload,
    });
  }

  // ─── Unified Send ──────────────────────────────────────────────────────────

  void _send(Map<String, dynamic> data) {
    final payload = jsonEncode(data);
    if (mode == ConnectionMode.lan) {
      _socket?.write('$payload\n');
    } else if (mode == ConnectionMode.internet) {
      _sendFirebase(payload);
    }
  }

  void sendMove(Move move) => _send(move.toJson());

  void sendSelectedMode(GameMode gameMode) => _send({
        'type': 'mode_selected',
        'mode': _gameModeToWire(gameMode),
      });

  void sendModeAccepted(GameMode gameMode) => _send({
        'type': 'mode_accepted',
        'mode': _gameModeToWire(gameMode),
      });

  void sendSurrender() => _send({'type': 'surrender'});

  void sendCoinFlip(int winner) => _send({'type': 'coin_flip', 'winner': winner});

  void sendRematch() => _send({'type': 'rematch'});
  void sendEndMatch() => _send({'type': 'end_match'});

  // ─── Message Dispatch ─────────────────────────────────────────────────────

  void _dispatchMessage(Map<String, dynamic> json) {
    final type = json['type'];
    final gm = _gameModeFromWire(json['mode'] as String?);

    if (type == 'mode_selected') {
      if (gm != null) _modeController.add(gm);
    } else if (type == 'mode_accepted') {
      if (gm != null) _modeAcceptedController.add(gm);
    } else if (type == 'surrender') {
      _surrenderController.add(null);
    } else if (type == 'rematch') {
      _rematchController.add(null);
    } else if (type == 'end_match') {
      _endMatchController.add(null);
    } else if (type == 'coin_flip') {
      final winner = json['winner'];
      if (winner != null) _coinFlipController.add((winner as num).toInt());
    } else if (json.containsKey('row') &&
        json.containsKey('col') &&
        json.containsKey('player')) {
      _moveController.add(Move(
        row: (json['row'] as num).toInt(),
        col: (json['col'] as num).toInt(),
        player: (json['player'] as num).toInt(),
        isBlock: json['isBlock'] as bool? ?? false,
      ));
    }
  }

  String _gameModeToWire(GameMode mode) {
    switch (mode) {
      case GameMode.normal:
        return 'normal';
      case GameMode.fourDirections:
        return 'fourDirections';
      case GameMode.blocks:
        return 'blocks';
    }
  }

  GameMode? _gameModeFromWire(String? name) {
    switch (name) {
      case 'normal':
        return GameMode.normal;
      case 'fourDirections':
        return GameMode.fourDirections;
      case 'blocks':
        return GameMode.blocks;
      default:
        return null;
    }
  }

  void dispose() {
    _socketSub?.cancel();
    _socket?.destroy();
    _server?.close();

    _messagesSub?.cancel();
    _joinedSub?.cancel();
    if (mode == ConnectionMode.internet) {
      _roomRef?.remove(); // best-effort: delete room data on exit
    }

    _moveController.close();
    _modeController.close();
    _modeAcceptedController.close();
    _surrenderController.close();
    _rematchController.close();
    _endMatchController.close();
    _statusController.close();
    _coinFlipController.close();
  }
}
