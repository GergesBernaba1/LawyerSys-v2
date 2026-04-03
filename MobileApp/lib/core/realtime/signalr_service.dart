import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:signalr_netcore/signalr_client.dart';

class SignalRService {
  static final SignalRService _instance = SignalRService._internal();

  factory SignalRService() => _instance;

  SignalRService._internal();

  HubConnection? _connection;
  StreamController<Map<String, dynamic>> _events =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get events => _events.stream;

  Future<void> init(String hubUrl,
      {Future<String> Function()? tokenFactory}) async {
    if (_connection != null) {
      await stop();
    }

    _events = StreamController<Map<String, dynamic>>.broadcast();

    _connection = HubConnectionBuilder()
        .withUrl(
          hubUrl,
          options: HttpConnectionOptions(
            accessTokenFactory: tokenFactory,
            transport: HttpTransportType.WebSockets,
          ),
        )
        .withAutomaticReconnect()
        .build();

    _connection!.onclose(({Exception? error}) {
      debugPrint('[SignalR] connection closed: $error');
    });

    _connection!.onreconnecting(({Exception? error}) {
      debugPrint('[SignalR] reconnecting: $error');
    });

    _connection!.onreconnected(({String? connectionId}) {
      debugPrint('[SignalR] reconnected: $connectionId');
    });

    _connection!.on('ReceiveEvent', _onReceiveEvent);
    _connection!.on('NotificationsChanged', _onNotificationsChanged);

    try {
      await _connection!.start();
      debugPrint('[SignalR] started at $hubUrl');
    } catch (e) {
      _connection = null;
      rethrow;
    }
  }

  void _onReceiveEvent(List<Object?>? args) {
    if (args == null || args.isEmpty) return;
    final raw = args.first;
    if (raw is Map<String, dynamic>) {
      _events.add(raw);
    } else if (raw is String) {
      _events.add({'message': raw});
    }
  }

  void _onNotificationsChanged(List<Object?>? args) {
    _events.add({
      'event': 'NotificationsChanged',
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<void> stop() async {
    if (_connection != null) {
      await _connection!.stop();
      _connection = null;
      await _events.close();
      debugPrint('[SignalR] stopped');
    }
  }

  Future<void> send(String method, [List<Object?>? args]) async {
    if (_connection == null ||
        _connection!.state != HubConnectionState.Connected) {
      throw StateError('SignalR connection is not open');
    }
    await _connection!.invoke(method, args: args?.whereType<Object>().toList());
  }
}
