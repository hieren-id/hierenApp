import 'dart:async';
import 'dart:convert';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import '../models/sensor_ampere_model.dart';
import 'api_service.dart';

class MqttService {
  // MQTT Broker Configuration
  // Ganti dengan IP broker MQTT Anda (EMQX, Mosquitto, dll)
  static const String broker = 'test.mosquitto.org'; // Public broker (lebih stabil untuk mobile)
  
  static const int port = 1883;
  
  // Topic untuk subscribe data ampere
  // PRODUCTION: Buat topic unique untuk keamanan
  static const String ampereTopic = 'hieren/sensor/ampere/user_${12345}'; // Ganti 12345 dengan ID unik Anda
  
  MqttServerClient? client;
  final StreamController<SensorAmpere> _ampereController = StreamController<SensorAmpere>.broadcast();
  
  // Stream untuk listen data ampere realtime
  Stream<SensorAmpere> get ampereStream => _ampereController.stream;
  
  bool _isConnected = false;
  bool get isConnected => _isConnected;

  // Connect ke MQTT broker
  Future<bool> connect() async {
    final clientId = 'flutter_hieren_${DateTime.now().millisecondsSinceEpoch}';
    client = MqttServerClient.withPort(broker, clientId, port);
    client!.logging(on: true); // Enable logging untuk debug
    client!.keepAlivePeriod = 60;
    client!.connectTimeoutPeriod = 5000;
    client!.onDisconnected = _onDisconnected;
    client!.onConnected = _onConnected;
    client!.autoReconnect = true;

    final connMessage = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);
    
    client!.connectionMessage = connMessage;

    try {
      print('🔌 Connecting to MQTT broker: $broker:$port');
      await client!.connect();
    } catch (e) {
      print('❌ MQTT Connection failed: $e');
      client!.disconnect();
      return false;
    }

    if (client!.connectionStatus!.state == MqttConnectionState.connected) {
      print('✅ Connected to MQTT broker');
      _subscribeToTopics();
      return true;
    } else {
      print('❌ Connection failed: ${client!.connectionStatus}');
      client!.disconnect();
      return false;
    }
  }

  void _onConnected() {
    _isConnected = true;
    print('✅ MQTT Client connected');
  }

  void _onDisconnected() {
    _isConnected = false;
    print('⚠️ MQTT Client disconnected');
  }

  // Subscribe ke topic ampere
  void _subscribeToTopics() {
    print('📡 Subscribing to topic: $ampereTopic');
    client!.subscribe(ampereTopic, MqttQos.atLeastOnce);

    client!.updates!.listen((List<MqttReceivedMessage<MqttMessage>> messages) {
      final recMessage = messages[0].payload as MqttPublishMessage;
      final payload = MqttPublishPayload.bytesToStringAsString(recMessage.payload.message);

      print('📩 Received from ${messages[0].topic}: $payload');
      _handleAmpereData(payload);
    });
  }

  // Handle data ampere yang diterima
  void _handleAmpereData(String payload) {
    try {
      // Parse JSON: {"ampere": 2.5, "voltage": 220.0}
      final data = json.decode(payload);
      final double ampere = double.parse(data['ampere'].toString());
      final double? voltage = data['voltage'] != null 
          ? double.parse(data['voltage'].toString()) 
          : null;

      // Buat object SensorAmpere untuk stream
      final sensorData = SensorAmpere(
        id: 0, // Temporary ID
        ampere: ampere,
        voltage: voltage,
        createdAt: DateTime.now().toString(),
      );

      // Kirim ke stream untuk update UI realtime
      _ampereController.add(sensorData);

      // Simpan ke database
      _saveToDatabase(ampere, voltage);
      
    } catch (e) {
      print('❌ Error parsing ampere data: $e');
    }
  }

  // Simpan data ke database via API
  Future<void> _saveToDatabase(double ampere, double? voltage) async {
    try {
      final result = await ApiService.saveSensorAmpere(ampere, voltage: voltage);
      if (result['success'] == true) {
        print('✅ Ampere data saved to DB: ${ampere}A');
      } else {
        print('⚠️ Failed to save: ${result['message']}');
      }
    } catch (e) {
      print('❌ Error saving to database: $e');
    }
  }

  // Publish data ampere (jika perlu kirim dari Flutter)
  void publishAmpere(double ampere, {double? voltage}) {
    if (!_isConnected || client == null) {
      print('⚠️ Not connected to MQTT broker');
      return;
    }

    final payload = json.encode({
      'ampere': ampere,
      'voltage': voltage,
      'timestamp': DateTime.now().toIso8601String(),
    });

    final builder = MqttClientPayloadBuilder();
    builder.addString(payload);
    
    client!.publishMessage(ampereTopic, MqttQos.atLeastOnce, builder.payload!);
    print('📤 Published to $ampereTopic: $payload');
  }

  // Disconnect dari broker
  void disconnect() {
    if (client != null) {
      client!.disconnect();
      print('🔌 Disconnected from MQTT broker');
    }
  }

  // Cleanup
  void dispose() {
    _ampereController.close();
    disconnect();
  }
}
