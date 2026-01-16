import 'package:flutter/material.dart';

class Device {
  final int id;
  final String name;
  final String condition;
  final int percentage;
  final String colorName;

  Device({
    required this.id,
    required this.name,
    required this.condition,
    required this.percentage,
    required this.colorName,
  });

  // Convert JSON to Device object
  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      condition: json['condition'] ?? '',
      percentage: json['percentage'] ?? 0,
      colorName: json['color'] ?? 'cyan',
    );
  }

  // Convert Device object to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'condition': condition,
      'percentage': percentage,
      'color': colorName,
    };
  }

  // Get Color from string name
  Color get color {
    switch (colorName.toLowerCase()) {
      case 'cyan':
        return Colors.cyan;
      case 'orange':
        return Colors.orange;
      case 'pink':
        return Colors.pink;
      case 'green':
        return Colors.green;
      case 'blue':
        return Colors.blue;
      case 'red':
        return Colors.red;
      default:
        return Colors.cyan;
    }
  }
}
