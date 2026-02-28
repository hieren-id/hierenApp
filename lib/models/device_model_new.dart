enum DeviceType {
  solarPanel,
  smartBattery,
  windTurbine;

  String get value {
    switch (this) {
      case DeviceType.solarPanel:
        return 'solar_panel';
      case DeviceType.smartBattery:
        return 'smart_battery';
      case DeviceType.windTurbine:
        return 'wind_turbine';
    }
  }

  static DeviceType fromString(String value) {
    switch (value) {
      case 'solar_panel':
        return DeviceType.solarPanel;
      case 'smart_battery':
        return DeviceType.smartBattery;
      case 'wind_turbine':
        return DeviceType.windTurbine;
      default:
        throw Exception('Unknown device type: $value');
    }
  }

  String get displayName {
    switch (this) {
      case DeviceType.solarPanel:
        return 'Solar Panel';
      case DeviceType.smartBattery:
        return 'Smart Battery';
      case DeviceType.windTurbine:
        return 'Wind Turbine';
    }
  }
}

class DeviceModel {
  final int id;
  final int userId;
  final String deviceId; // Hardware ID (unique)
  final DeviceType deviceType;
  final String name;
  final String? location;
  final bool isActive;
  final String createdAt;

  DeviceModel({
    required this.id,
    required this.userId,
    required this.deviceId,
    required this.deviceType,
    required this.name,
    this.location,
    this.isActive = true,
    required this.createdAt,
  });

  factory DeviceModel.fromJson(Map<String, dynamic> json) {
    return DeviceModel(
      id: int.parse(json['id'].toString()),
      userId: int.parse(json['user_id'].toString()),
      deviceId: json['device_id'] as String,
      deviceType: DeviceType.fromString(json['device_type'] as String),
      name: json['name'] as String,
      location: json['location'] as String?,
      isActive: json['is_active'] == 1 || json['is_active'] == true,
      createdAt: json['created_at'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'device_id': deviceId,
      'device_type': deviceType.value,
      'name': name,
      'location': location,
      'is_active': isActive,
      'created_at': createdAt,
    };
  }
}
