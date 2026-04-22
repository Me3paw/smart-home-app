import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import '../models/app_state_model.dart';

class MqttService extends ChangeNotifier {
  late MqttServerClient client;
  bool isConnected = false;
  bool isConnecting = false;
  FullAppState state = FullAppState.initial();

  // HiveMQ Cloud Standard Secure TCP
  final String server = '7da9926a4f2c40e7b22d7c0194a6dde1.s1.eu.hivemq.cloud';
  final int port = 8883; 
  final String username = 'SYS_USER_PLACEHOLDER';
  final String password = '27072003Hp@_@';
  final String clientIdentifier = 'smarthome_flutter_SYS_USER_PLACEHOLDER_final_v10';

  MqttService() {
    _initializeClient();
  }

  void _initializeClient() {
    client = MqttServerClient.withPort(server, clientIdentifier, port);
    client.secure = true;
    client.useWebSocket = false;
    client.keepAlivePeriod = 60;
    client.onDisconnected = _onDisconnected;
    client.onConnected = _onConnected;
    client.onSubscribed = _onSubscribed;
    client.autoReconnect = true;
    client.logging(on: true);
    
    client.onBadCertificate = (dynamic cert) => true;

    final connMess = MqttConnectMessage()
        .withClientIdentifier(clientIdentifier)
        .authenticateAs(username, password)
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);
    client.connectionMessage = connMess;
    client.setProtocolV311();
  }

  Future<void> connect() async {
    if (isConnected || isConnecting) return;
    isConnecting = true;
    notifyListeners();

    try {
      await client.connect();
    } catch (e) {
      debugPrint('MQTT: Connection error: $e');
      _onDisconnected();
    } finally {
      isConnecting = false;
      notifyListeners();
    }
  }

  void disconnect() {
    client.disconnect();
  }

  void _onConnected() {
    isConnected = true;
    client.subscribe('device/state/sync', MqttQos.atMostOnce);
    client.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      final MqttPublishMessage recMess = c[0].payload as MqttPublishMessage;
      final String pt = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
      if (c[0].topic == 'device/state/sync') {
        _handleSync(pt);
      }
    });
    notifyListeners();
  }

  void _onDisconnected() {
    isConnected = false;
    isConnecting = false;
    notifyListeners();
  }

  void _onSubscribed(String topic) {}

  void _handleSync(String payload) {
    try {
      final data = jsonDecode(payload);
      if (data['type'] == 'sync') {
        _updateState(data);
      }
    } catch (e) {
      debugPrint('MQTT: Data Error: $e');
    }
  }

  void _updateState(Map<String, dynamic> data) {
    state = state.copyWith(
      pzem: data['pzem'] != null ? PZEMState.fromJson(Map<String, dynamic>.from(data['pzem'])) : null,
      relays: data['relays'] != null 
          ? List<RelayInfo>.from(data['relays'].map((m) => RelayInfo.fromJson(Map<String, dynamic>.from(m)))) 
          : null,
      ac: data['ac'] != null ? ACState.fromJson(Map<String, dynamic>.from(data['ac'])) : null,
      pc: data['pc'] != null ? PCInfo.fromJson(Map<String, dynamic>.from(data['pc'])) : null,
      macros: data['macros'] != null 
          ? List<MacroConfig>.from(data['macros'].map((m) => MacroConfig.fromJson(Map<String, dynamic>.from(m))))
          : null,
      elecPrice: (data['elecPrice'] ?? state.elecPrice).toDouble(),
      tierPrices: data['tierPrices'] != null ? List<double>.from(data['tierPrices'].map((e) => (e as num).toDouble())) : null,
      monthly: data['monthly'] != null ? List<double?>.from(data['monthly'].map((e) => (e as num?)?.toDouble())) : null,
      hourly: data['hourly'] != null ? List<double?>.from(data['hourly'].map((e) => (e as num?)?.toDouble())) : null,
    );
    notifyListeners();
  }

  void publish(String topic, String message) {
    if (!isConnected) return;
    final builder = MqttClientPayloadBuilder();
    builder.addString(message);
    client.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
  }

  void sendCommand(String type, Map<String, dynamic> params) {
    final msg = jsonEncode(params);
    publish('device/cmd/$type', msg);
  }
}
