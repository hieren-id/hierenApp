class EnergyData {
  final int id;
  final double totalKwh;
  final int solarUsagePercent;
  final double consumedKwh;
  final double capacityKwh;
  final double co2ReductionKwh;
  final String createdAt;

  EnergyData({
    required this.id,
    required this.totalKwh,
    required this.solarUsagePercent,
    required this.consumedKwh,
    required this.capacityKwh,
    required this.co2ReductionKwh,
    required this.createdAt,
  });

  // Convert JSON to EnergyData object
  factory EnergyData.fromJson(Map<String, dynamic> json) {
    return EnergyData(
      id: json['id'] ?? 0,
      totalKwh: (json['total_kwh'] ?? 0).toDouble(),
      solarUsagePercent: json['solar_usage_percent'] ?? 0,
      consumedKwh: (json['consumed_kwh'] ?? 0).toDouble(),
      capacityKwh: (json['capacity_kwh'] ?? 0).toDouble(),
      co2ReductionKwh: (json['co2_reduction_kwh'] ?? 0).toDouble(),
      createdAt: json['created_at'] ?? '',
    );
  }

  // Convert EnergyData object to JSON
  Map<String, dynamic> toJson() {
    return {
      'total_kwh': totalKwh,
      'solar_usage_percent': solarUsagePercent,
      'consumed_kwh': consumedKwh,
      'capacity_kwh': capacityKwh,
      'co2_reduction_kwh': co2ReductionKwh,
    };
  }
}
