import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:signalr_netcore/signalr_client.dart';

class SignalRService {
  static final SignalRService _instance = SignalRService._internal();

  factory SignalRService() => _instance;

  SignalRService._internal();

  HubConnection? _connection;
  final _events = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get events => _events.stream;

  Future<void> init(String hubUrl, {String? accessToken}) async {
    if (_connection != null) return;

    _connection = HubConnectionBuilder()
        .withUrl(
          hubUrl,
          HttpConnectionOptions(
            accessTokenFactory: () async => accessToken ?? '',
            transport: HttpTransportType.webSockets,
          ),
        )
        .build();

    _connection!.onclose((error) {
      debugPrint('[SignalR] connection closed: $error');
    });

    _connection!.onreconnecting((error) {
      debugPrint('[SignalR] reconnecting: $error');
    });

    _connection!.onreconnected((id) {
      debugPrint('[SignalR] reconnected: $id');
    });

    _connection!.on('ReceiveEvent', _onReceiveEvent);

    await _connection!.start();
    debugPrint('[SignalR] started at $hubUrl');
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

  Future<void> stop() async {
    if (_connection != null) {
      await _connection!.stop();
      _connection = null;
      debugPrint('[SignalR] stopped');
    }
  }

  Future<void> send(String method, [List<Object?>? args]) async {
    if (_connection == null || _connection?.state != HubConnectionState.connected) {
      throw StateError('SignalR connection is not open');
    }
    await _connection!.invoke(method, args: args);
  }
}
