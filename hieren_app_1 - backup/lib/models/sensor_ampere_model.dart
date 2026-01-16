class SensorAmpere {
  final int id;
  final double ampere;
  final double? voltage;
  final String createdAt;

  SensorAmpere({
    required this.id,
    required this.ampere,
    this.voltage,
    required this.createdAt,
  });

  factory SensorAmpere.fromJson(Map<String, dynamic> json) {
    return SensorAmpere(
      id: int.parse(json['id'].toString()),
      ampere: double.parse(json['ampere'].toString()),
      voltage: json['voltage'] != null ? double.parse(json['voltage'].toString()) : null,
      createdAt: json['created_at'].toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ampere': ampere,
      'voltage': voltage,
      'created_at': createdAt,
    };
  }
}
