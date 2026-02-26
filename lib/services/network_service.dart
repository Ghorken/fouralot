import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:math';

import 'package:fouralot/models/game_models.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

/// Handles both LAN (TCP sockets) and Internet (MQTT) multiplayer connections.
class NetworkService {
  // ─── Shared State ────────────────────────────────────────────────────────

  bool isHost = false;
  int playerNumber = 1;
  final StreamController<Move> _moveController = StreamController.broadcast();
  final StreamController<GameMode> _modeController = StreamController.broadcast();
  final StreamController<GameMode> _modeAcceptedController = StreamController.broadcast();
  final StreamController<String> _statusController = StreamController.broadcast();
  ConnectionMode mode = ConnectionMode.lan;

  Stream<Move> get onMove => _moveController.stream;
  Stream<GameMode> get onModeSelected => _modeController.stream;
  Stream<GameMode> get onModeAccepted => _modeAcceptedController.stream;
  Stream<String> get onStatus => _statusController.stream;

  // ─── LAN State (Sockets) ─────────────────────────────────────────────────

  ServerSocket? _server;
  Socket? _socket;
  StreamSubscription? _socketSub;

  // ─── Internet State (MQTT) ───────────────────────────────────────────────

  MqttServerClient? _mqttClient;
  String? _roomCode;
  String? _myTopic;
  String? _oppTopic;

  // ─── LAN Methods ─────────────────────────────────────────────────────────

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
    } catch (e) {
      return false;
    }
  }

  Future<bool> connectToLanHost(String ip) async {
    try {
      mode = ConnectionMode.lan;
      _socket = await Socket.connect(ip, 4242, timeout: const Duration(seconds: 10));
      isHost = false;
      playerNumber = 2;
      _statusController.add('connected');
      _listenToSocket();
      return true;
    } catch (e) {
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
          _handleIncomingPayload(line);
        }
      },
      onDone: () => _statusController.add('disconnected'),
      onError: (_) => _statusController.add('error'),
    );
  }

  // ─── Internet Methods (MQTT) ─────────────────────────────────────────────

  String get generatedRoomCode => _roomCode ?? '';

  Future<MqttServerClient> _setupMqtt() async {
    final client = MqttServerClient('test.mosquitto.org', '');
    client.port = 1883;
    client.logging(on: false);
    client.keepAlivePeriod = 20;
    client.onDisconnected = () => _statusController.add('disconnected');
    client.onConnected = () {
      client.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) {
        final MqttPublishMessage recMess = c[0].payload as MqttPublishMessage;
        final String pt = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
        _handleIncomingPayload(pt);
      });
    };
    final connMess = MqttConnectMessage().withClientIdentifier('fouralot_${Random().nextInt(100000)}').startClean();
    client.connectionMessage = connMess;

    try {
      await client.connect();
    } catch (e) {
      client.disconnect();
      rethrow;
    }
    return client;
  }

  Future<bool> startInternetHost() async {
    try {
      mode = ConnectionMode.internet;
      isHost = true;
      playerNumber = 1;
      _statusController.add('connecting');

      _mqttClient = await _setupMqtt();

      // Generate a Random 5 digit Room Code
      _roomCode = (10000 + Random().nextInt(90000)).toString();
      _myTopic = 'fouralot/room_$_roomCode/p1';
      _oppTopic = 'fouralot/room_$_roomCode/p2';

      _mqttClient!.subscribe(_oppTopic!, MqttQos.atMostOnce);

      _statusController.add('hosting');
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> connectToInternetHost(String code) async {
    try {
      mode = ConnectionMode.internet;
      isHost = false;
      playerNumber = 2;
      _statusController.add('connecting');

      _mqttClient = await _setupMqtt();

      _roomCode = code.trim();
      _myTopic = 'fouralot/room_$_roomCode/p2';
      _oppTopic = 'fouralot/room_$_roomCode/p1';

      _mqttClient!.subscribe(_oppTopic!, MqttQos.atMostOnce);

      // Send a joined ping
      _sendMqttRaw('JOINED');

      _statusController.add('connected');
      return true;
    } catch (e) {
      return false;
    }
  }

  void _sendMqttRaw(String data) {
    if (_mqttClient == null || _myTopic == null) return;
    final builder = MqttClientPayloadBuilder();
    builder.addString(data);
    _mqttClient!.publishMessage(_myTopic!, MqttQos.atMostOnce, builder.payload!);
  }

  // ─── Unified Send ────────────────────────────────────────────────────────

  void sendMove(Move move) {
    final payload = jsonEncode(move.toJson());
    if (mode == ConnectionMode.lan) {
      _socket?.write('$payload\n');
    } else if (mode == ConnectionMode.internet) {
      _sendMqttRaw(payload);
    }
  }

  void sendSelectedMode(GameMode gameMode) {
    final payload = jsonEncode({
      'type': 'mode_selected',
      'mode': _gameModeToWire(gameMode),
    });
    if (mode == ConnectionMode.lan) {
      _socket?.write('$payload\n');
    } else if (mode == ConnectionMode.internet) {
      _sendMqttRaw(payload);
    }
  }

  void sendModeAccepted(GameMode gameMode) {
    final payload = jsonEncode({
      'type': 'mode_accepted',
      'mode': _gameModeToWire(gameMode),
    });
    if (mode == ConnectionMode.lan) {
      _socket?.write('$payload\n');
    } else if (mode == ConnectionMode.internet) {
      _sendMqttRaw(payload);
    }
  }

  void _handleIncomingPayload(String raw) {
    final payload = raw.trim();
    if (payload.isEmpty) return;

    if (payload == 'JOINED') {
      if (isHost) _statusController.add('connected');
      return;
    }

    try {
      final json = jsonDecode(payload) as Map<String, dynamic>;
      final type = json['type'];
      final modeName = json['mode'] as String?;
      final mode = _gameModeFromWire(modeName);
      if (type == 'mode_selected') {
        if (mode != null) _modeController.add(mode);
        return;
      }
      if (type == 'mode_accepted') {
        if (mode != null) _modeAcceptedController.add(mode);
        return;
      }
      if (json.containsKey('row') && json.containsKey('col') && json.containsKey('player')) {
        _moveController.add(Move.fromJson(json));
      }
    } catch (_) {}
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

  GameMode? _gameModeFromWire(String? modeName) {
    switch (modeName) {
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

    _mqttClient?.disconnect();

    _moveController.close();
    _modeController.close();
    _modeAcceptedController.close();
    _statusController.close();
  }
}
