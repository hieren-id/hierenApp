import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/device_model.dart';
import '../models/energy_data_model.dart';
import '../models/sensor_ampere_model.dart';

class ApiService {
  // IP WiFi komputer - update setiap kali WiFi berubah (cek: ipconfig)
  // HP & PC harus dalam WiFi yang sama: 192.168.1.x
  // Pastikan XAMPP Apache running & firewall allow port 80
  static const String baseUrl = 'http://192.168.1.4/hieren_api';

  static Future<List<Device>> getDevices() async {
    try {
      print('📡 GET: $baseUrl/read_device.php');
      final response = await http
          .get(Uri.parse('$baseUrl/read_device.php'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['success'] == true) {
          List<dynamic> devicesJson = jsonData['data'];
          return devicesJson.map((json) => Device.fromJson(json)).toList();
        } else {
          throw Exception(jsonData['message'] ?? 'Failed to load devices');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching devices: $e');
    }
  }

  // Create new device
  static Future<Map<String, dynamic>> createDevice(Device device) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/create_device.php'),
        body: {
          'name': device.name,
          'condition': device.condition,
          'percentage': device.percentage.toString(),
          'color': device.colorName,
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating device: $e');
    }
  }

  // Update device
  static Future<Map<String, dynamic>> updateDevice(Device device) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/update_device.php'),
        body: {
          'id': device.id.toString(),
          'name': device.name,
          'condition': device.condition,
          'percentage': device.percentage.toString(),
          'color': device.colorName,
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating device: $e');
    }
  }

  // Delete device
  static Future<Map<String, dynamic>> deleteDevice(int id) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/delete_device.php'),
        body: {'id': id.toString()},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting device: $e');
    }
  }

  // ==================== ENERGY APIs ====================

  // Get latest energy data
  static Future<EnergyData> getEnergyData() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/read_energy.php'));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['success'] == true) {
          return EnergyData.fromJson(jsonData['data']);
        } else {
          throw Exception(jsonData['message'] ?? 'Failed to load energy data');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching energy data: $e');
    }
  }

  // Create new energy data
  static Future<Map<String, dynamic>> createEnergyData(
    EnergyData energyData,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/create_energy.php'),
        body: {
          'total_kwh': energyData.totalKwh.toString(),
          'solar_usage_percent': energyData.solarUsagePercent.toString(),
          'consumed_kwh': energyData.consumedKwh.toString(),
          'capacity_kwh': energyData.capacityKwh.toString(),
          'co2_reduction_kwh': energyData.co2ReductionKwh.toString(),
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating energy data: $e');
    }
  }

  // ==================== SENSOR AMPERE APIs ====================

  // Get latest sensor ampere data
  static Future<SensorAmpere> getSensorAmpere() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/read_sensor_ampere.php'),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['success'] == true) {
          return SensorAmpere.fromJson(jsonData['data']);
        } else {
          throw Exception(jsonData['message'] ?? 'Failed to load sensor data');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching sensor data: $e');
    }
  }

  // Save sensor ampere data
  static Future<Map<String, dynamic>> saveSensorAmpere(
    double ampere, {
    double? voltage,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/save_sensor_ampere.php'),
        body: {
          'ampere': ampere.toString(),
          if (voltage != null) 'voltage': voltage.toString(),
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error saving sensor data: $e');
    }
  }

  // Get historical sensor ampere data for graph
  static Future<List<SensorAmpere>> getSensorAmpereHistory({
    int limit = 20,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/read_sensor_ampere_history.php?limit=$limit'),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['success'] == true) {
          List<dynamic> dataList = jsonData['data'];
          return dataList.map((json) => SensorAmpere.fromJson(json)).toList();
        } else {
          throw Exception(
            jsonData['message'] ?? 'Failed to load sensor history',
          );
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching sensor history: $e');
    }
  }
}
