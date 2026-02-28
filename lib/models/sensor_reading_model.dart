class SensorReading {
  final int id;
  final String deviceId;
  final String
  sensorType; // 'pzem', 'piezo', 'teg', 'pzem_dc', 'pzem_ac', 'dht22', 'encoder', 'ldr1-5'
  final double? voltage;
  final double? current;
  final double? power;
  final double? temperature;
  final int? angle;
  final double? lightIntensity;
  final String createdAt;

  SensorReading({
    required this.id,
    required this.deviceId,
    required this.sensorType,
    this.voltage,
    this.current,
    this.power,
    this.temperature,
    this.angle,
    this.lightIntensity,
    required this.createdAt,
  });

  factory SensorReading.fromJson(Map<String, dynamic> json) {
    return SensorReading(
      id: int.parse(json['id'].toString()),
      deviceId: json['device_id'] as String,
      sensorType: json['sensor_type'] as String,
      voltage: json['voltage'] != null
          ? double.parse(json['voltage'].toString())
          : null,
      current: json['current'] != null
          ? double.parse(json['current'].toString())
          : null,
      power: json['power'] != null
          ? double.parse(json['power'].toString())
          : null,
      temperature: json['temperature'] != null
          ? double.parse(json['temperature'].toString())
          : null,
      angle: json['angle'] != null ? int.parse(json['angle'].toString()) : null,
      lightIntensity: json['light_intensity'] != null
          ? double.parse(json['light_intensity'].toString())
          : null,
      createdAt: json['created_at'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'device_id': deviceId,
      'sensor_type': sensorType,
      'voltage': voltage,
      'current': current,
      'power': power,
      'temperature': temperature,
      'angle': angle,
      'light_intensity': lightIntensity,
      'created_at': createdAt,
    };
  }

  // Helper untuk cek jenis sensor
  bool get isPzem => sensorType.startsWith('pzem');
  bool get isPiezo => sensorType == 'piezo';
  bool get isTeg => sensorType == 'teg';
  bool get isDht22 => sensorType == 'dht22';
  bool get isEncoder => sensorType == 'encoder';
  bool get isLdr => sensorType.startsWith('ldr');

  // Helper untuk mendapatkan nilai string
  String get voltageDisplay =>
      voltage != null ? '${voltage!.toStringAsFixed(2)}V' : 'N/A';
  String get currentDisplay =>
      current != null ? '${current!.toStringAsFixed(2)}A' : 'N/A';
  String get powerDisplay =>
      power != null ? '${power!.toStringAsFixed(2)}W' : 'N/A';
  String get temperatureDisplay =>
      temperature != null ? '${temperature!.toStringAsFixed(1)}°C' : 'N/A';
  String get angleDisplay => angle != null ? '$angle°' : 'N/A';
}
