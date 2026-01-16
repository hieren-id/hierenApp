import 'dart:async';
import 'dart:convert';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import '../models/sensor_ampere_model.dart';
import '../models/sensor_reading_model.dart';
import 'api_service.dart';

class MqttService {
  // MQTT Broker Configuration
  // Ganti dengan IP broker MQTT Anda (EMQX, Mosquitto, dll)
  static const String broker =
      'test.mosquitto.org'; // Public broker (lebih stabil untuk mobile)

  static const int port = 1883;

  // Topic untuk subscribe data ampere
  // PRODUCTION: Buat topic unique untuk keamanan
  static const String ampereTopic =
      'hieren/sensor/user_${12345}'; // Ganti 12345 dengan ID unik Anda

  MqttServerClient? client;
  final StreamController<SensorAmpere> _ampereController =
      StreamController<SensorAmpere>.broadcast();
  final StreamController<SensorReading> _sensorController =
      StreamController<SensorReading>.broadcast();

  // Stream untuk listen data ampere realtime
  Stream<SensorAmpere> get ampereStream => _ampereController.stream;
  // Stream generic untuk semua sensor
  Stream<SensorReading> get sensorStream => _sensorController.stream;

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
      final payload = MqttPublishPayload.bytesToStringAsString(
        recMessage.payload.message,
      );

      print('📩 Received from ${messages[0].topic}: $payload');
      _handleAmpereData(payload);
    });
  }

  // Subscribe ke device tertentu (multi-device support)
  void subscribeDevice(String deviceId) {
    if (client == null || !_isConnected) return;

    final topicPattern = 'hieren/$deviceId/#';
    print('📡 Subscribing to device topic: $topicPattern');
    client!.subscribe(topicPattern, MqttQos.atLeastOnce);

    client!.updates!.listen((List<MqttReceivedMessage<MqttMessage>> messages) {
      final message = messages.first;
      final recMessage = message.payload as MqttPublishMessage;
      final payload = MqttPublishPayload.bytesToStringAsString(
        recMessage.payload.message,
      );

      _handleGenericSensor(message.topic, payload);
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
      final result = await ApiService.saveSensorAmpere(
        ampere,
        voltage: voltage,
      );
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
    _sensorController.close();
    disconnect();
  }

  // Handle generic sensor payloads
  void _handleGenericSensor(String topic, String payload) {
    try {
      final parts = topic.split('/');
      // Expected: hieren/{deviceId}/{sensorType}
      if (parts.length < 3) return;
      final deviceId = parts[1];
      final sensorType = parts[2];

      Map<String, dynamic> data;
      if (payload.contains('{')) {
        data = json.decode(payload) as Map<String, dynamic>;
      } else {
        // Support slash-separated "v/a/p" format
        final segments = payload.split('/');
        data = {};
        if (segments.isNotEmpty) data['voltage'] = double.tryParse(segments[0]);
        if (segments.length > 1) data['current'] = double.tryParse(segments[1]);
        if (segments.length > 2) data['power'] = double.tryParse(segments[2]);
      }

      final reading = SensorReading(
        id: 0,
        deviceId: deviceId,
        sensorType: sensorType,
        voltage: _asDouble(data['voltage']),
        current: _asDouble(data['current']),
        power: _asDouble(data['power']),
        temperature: _asDouble(data['temperature']),
        angle: data['angle'] != null
            ? int.tryParse(data['angle'].toString())
            : null,
        lightIntensity: _asDouble(data['light_intensity'] ?? data['ldr']),
        createdAt: DateTime.now().toIso8601String(),
      );

      _sensorController.add(reading);

      // If it's pzem* treat as ampere for legacy graph and save to DB
      if (reading.isPzem) {
        final amp = reading.current ?? 0.0;
        _ampereController.add(
          SensorAmpere(
            id: 0,
            ampere: amp,
            voltage: reading.voltage,
            createdAt: reading.createdAt,
          ),
        );
        _saveToDatabase(amp, reading.voltage);
      }
    } catch (e) {
      print('❌ Error handling sensor payload: $e');
    }
  }

  double? _asDouble(dynamic val) {
    if (val == null) return null;
    return double.tryParse(val.toString());
  }
}
