import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/device_model.dart';
import '../models/energy_data_model.dart';
import '../models/sensor_ampere_model.dart';
import '../services/api_service.dart';
import '../services/mqtt_service.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  bool isElectricityOn = true;
  String selectedPeriod = 'Month';

  List<Device> devices = [];
  EnergyData? energyData;
  SensorAmpere? sensorAmpere;
  List<SensorAmpere> ampereHistory = [];
  bool isLoading = true;
  String? errorMessage;

  // MQTT realtime
  final MqttService _mqttService = MqttService();
  StreamSubscription<SensorAmpere>? _ampereSubscription;
  bool _isMqttConnected = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _connectMqtt();
  }

  // Connect to MQTT and listen for realtime data
  Future<void> _connectMqtt() async {
    final connected = await _mqttService.connect();
    setState(() {
      _isMqttConnected = connected;
    });

    if (connected) {
      // Listen to ampere stream for realtime updates
      _ampereSubscription = _mqttService.ampereStream.listen((ampereData) {
        setState(() {
          sensorAmpere = ampereData;
        });
        print('📊 UI Updated: ${ampereData.ampere}A');
      });
    }
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      print('🔄 Loading data from API...');
      // Load devices, energy data, and sensor ampere from API
      final devicesData = await ApiService.getDevices();
      print('✅ Devices loaded: ${devicesData.length}');

      final energy = await ApiService.getEnergyData();
      print('✅ Energy data loaded');

      final ampere = await ApiService.getSensorAmpere();
      print('✅ Sensor ampere loaded: ${ampere.ampere}A');

      final history = await ApiService.getSensorAmpereHistory(limit: 20);
      print('✅ Sensor ampere history loaded: ${history.length} records');

      setState(() {
        devices = devicesData; // Will be empty list if no devices
        energyData = energy;
        sensorAmpere = ampere;
        ampereHistory = history;
        isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading data: $e');
      setState(() {
        // If error is just empty data, don't show error
        if (e.toString().contains('No devices found')) {
          devices = [];
          errorMessage = null;
        } else {
          errorMessage = e.toString();
        }
        isLoading = false;
      });
    }
  }

  // Delete device
  Future<void> _deleteDevice(int id) async {
    try {
      final result = await ApiService.deleteDevice(id);
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Device deleted successfully')),
        );
        _loadData(); // Reload data
      } else {
        throw Exception(result['message'] ?? 'Failed to delete');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  void dispose() {
    _ampereSubscription?.cancel();
    _mqttService.dispose();
    super.dispose();
  }

  // Show delete confirmation
  void _showDeleteConfirmation(Device device) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Device'),
        content: Text('Are you sure you want to delete ${device.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteDevice(device.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // Show edit dialog
  void _showEditDialog(Device device) {
    final nameController = TextEditingController(text: device.name);
    final conditionController = TextEditingController(text: device.condition);
    final percentageController = TextEditingController(
      text: device.percentage.toString(),
    );
    String selectedColor = device.colorName;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Device'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Device Name'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: conditionController,
                decoration: const InputDecoration(labelText: 'Condition'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: percentageController,
                decoration: const InputDecoration(labelText: 'Percentage'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: selectedColor,
                decoration: const InputDecoration(labelText: 'Color'),
                items: ['cyan', 'orange', 'pink', 'green', 'blue', 'red']
                    .map(
                      (color) =>
                          DropdownMenuItem(value: color, child: Text(color)),
                    )
                    .toList(),
                onChanged: (value) {
                  selectedColor = value!;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final updatedDevice = Device(
                id: device.id,
                name: nameController.text,
                condition: conditionController.text,
                percentage: int.parse(percentageController.text),
                colorName: selectedColor,
              );
              Navigator.pop(context);
              await _updateDevice(updatedDevice);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateDevice(Device device) async {
    try {
      final result = await ApiService.updateDevice(device);
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Device updated successfully')),
        );
        _loadData();
      } else {
        throw Exception(result['message'] ?? 'Failed to update');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  // Show add device dialog
  void _showAddDialog() {
    final nameController = TextEditingController();
    final conditionController = TextEditingController();
    final percentageController = TextEditingController(text: '0');
    String selectedColor = 'cyan';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Device'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Device Name'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: conditionController,
                decoration: const InputDecoration(labelText: 'Condition'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: percentageController,
                decoration: const InputDecoration(labelText: 'Percentage'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: selectedColor,
                decoration: const InputDecoration(labelText: 'Color'),
                items: ['cyan', 'orange', 'pink', 'green', 'blue', 'red']
                    .map(
                      (color) =>
                          DropdownMenuItem(value: color, child: Text(color)),
                    )
                    .toList(),
                onChanged: (value) {
                  selectedColor = value!;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final newDevice = Device(
                id: 0,
                name: nameController.text,
                condition: conditionController.text,
                percentage: int.parse(percentageController.text),
                colorName: selectedColor,
              );
              Navigator.pop(context);
              await _createDevice(newDevice);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _createDevice(Device device) async {
    try {
      final result = await ApiService.createDevice(device);
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Device added successfully')),
        );
        _loadData();
      } else {
        throw Exception(result['message'] ?? 'Failed to add device');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: Colors.green,
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : errorMessage != null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 60,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error: $errorMessage',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadData,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: _loadData,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 25),
                      _buildElectricitySavedCard(),
                      const SizedBox(height: 25),
                      _buildDeviceSection(),
                      const SizedBox(height: 25),
                      _buildEnergyGeneratedCard(),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Statistics',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // MQTT Status Indicator
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _isMqttConnected ? Colors.green : Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  _isMqttConnected ? 'MQTT Live' : 'MQTT Off',
                  style: TextStyle(
                    fontSize: 10,
                    color: _isMqttConnected ? Colors.green : Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Transform.scale(
              scale: 0.8,
              child: Switch(
                value: isElectricityOn,
                activeThumbColor: Colors.white,
                activeTrackColor: Colors.green,
                onChanged: (val) {
                  setState(() => isElectricityOn = val);
                },
              ),
            ),
            const Text(
              'Electricity ON',
              style: TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildElectricitySavedCard() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Electricity Saved',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 30),
          Center(
            child: SizedBox(
              height: 200,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      sectionsSpace: 0,
                      centerSpaceRadius: 70,
                      startDegreeOffset: -90,
                      sections: [
                        PieChartSectionData(
                          color: Colors.green,
                          value: (energyData?.solarUsagePercent ?? 75)
                              .toDouble(),
                          title: '',
                          radius: 25,
                        ),
                        PieChartSectionData(
                          color: Colors.red,
                          value: (100 - (energyData?.solarUsagePercent ?? 75))
                              .toDouble(),
                          title: '',
                          radius: 25,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.electric_bolt, size: 30),
                      const SizedBox(height: 5),
                      Text(
                        '${energyData?.solarUsagePercent ?? 75}%',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'Electricity',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 25),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem(Colors.red, 'Electricity'),
              const SizedBox(width: 20),
              _buildLegendItem(Colors.green, 'Solar Energy'),
            ],
          ),
          const SizedBox(height: 15),
          Center(
            child: Text(
              '${energyData?.solarUsagePercent ?? 75}% electricity saved',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(color: Colors.black87, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildDeviceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          'Device',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          'Power and Connected Device',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 20),
        if (devices.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(40.0),
              child: Column(
                children: const [
                  Icon(Icons.devices_other, size: 60, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No devices yet',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tap the + button to add a device',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          )
        else
          ...devices.map((device) => _buildDeviceItem(device)),
      ],
    );
  }

  Widget _buildDeviceItem(Device device) {
    return Dismissible(
      key: Key(device.id.toString()),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        _showDeleteConfirmation(device);
        return false; // Don't dismiss automatically
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(15),
        ),
        alignment: Alignment.centerRight,
        child: const Padding(
          padding: EdgeInsets.only(right: 20),
          child: Icon(Icons.delete, color: Colors.white, size: 30),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            SizedBox(
              width: 50,
              height: 50,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: device.percentage / 100,
                    backgroundColor: Colors.grey.withOpacity(0.2),
                    color: device.color,
                    strokeWidth: 4,
                  ),
                  Text(
                    '${device.percentage}%',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    device.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    device.condition,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  color: Colors.blue,
                  onPressed: () => _showEditDialog(device),
                ),
                Icon(Icons.chevron_right, color: Colors.grey.withOpacity(0.5)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnergyGeneratedCard() {
    return Column(
      children: [
        // Current Reading Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Current Sensor Reading',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      const Icon(
                        Icons.offline_bolt,
                        color: Colors.orange,
                        size: 30,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${sensorAmpere?.ampere.toStringAsFixed(2) ?? "0.00"}A',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'Ampere',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  Container(
                    width: 1,
                    height: 60,
                    color: Colors.grey.withOpacity(0.3),
                  ),
                  Column(
                    children: [
                      const Icon(Icons.bolt, color: Colors.blue, size: 30),
                      const SizedBox(height: 5),
                      Text(
                        '${sensorAmpere?.voltage?.toStringAsFixed(1) ?? "0.0"}V',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'Voltage',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Ampere Graph
        _buildAmpereGraph(),
        const SizedBox(height: 20),
        // Voltage Graph
        _buildVoltageGraph(),
      ],
    );
  }

  Widget _buildAmpereGraph() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.offline_bolt, color: Colors.orange, size: 16),
              SizedBox(width: 5),
              Text(
                'Ampere Sensor History',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildPeriodButton('Day'),
              _buildPeriodButton('Week'),
              _buildPeriodButton('Month'),
              _buildPeriodButton('All time'),
            ],
          ),
          const SizedBox(height: 25),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.withOpacity(0.15),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const SizedBox.shrink();
                        return Text(
                          '${value.toInt()}A',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: ampereHistory.isEmpty
                          ? 1
                          : (ampereHistory.length / 4).ceilToDouble(),
                      getTitlesWidget: (value, meta) {
                        if (ampereHistory.isEmpty) {
                          // Show default time labels when no data
                          switch (value.toInt()) {
                            case 0:
                              return const Text(
                                '00:00',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 11,
                                ),
                              );
                            case 1:
                              return const Text(
                                '06:00',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 11,
                                ),
                              );
                            case 2:
                              return const Text(
                                '12:00',
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            case 3:
                              return const Text(
                                '18:00',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 11,
                                ),
                              );
                          }
                          return const SizedBox.shrink();
                        }

                        // Show time from actual data
                        int index = value.toInt();
                        if (index < 0 || index >= ampereHistory.length) {
                          return const SizedBox.shrink();
                        }

                        // Parse created_at and show time
                        try {
                          DateTime dateTime = DateTime.parse(
                            ampereHistory[index].createdAt,
                          );
                          String timeStr =
                              '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';

                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              timeStr,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 10,
                              ),
                            ),
                          );
                        } catch (e) {
                          return const SizedBox.shrink();
                        }
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: ampereHistory.isEmpty
                    ? 3
                    : (ampereHistory.length - 1).toDouble(),
                minY: 0,
                maxY: _getMaxAmpere(),
                lineBarsData: [
                  LineChartBarData(
                    spots: _getAmpereSpots(),
                    isCurved: true,
                    color: Colors.orange,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          Colors.orange.withOpacity(0.3),
                          Colors.orange.withOpacity(0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(child: _buildStatBox(_getAvgAmpere('today'), 'Today')),
              const SizedBox(width: 8),
              Flexible(
                child: _buildStatBox(_getAvgAmpere('month'), 'This month'),
              ),
              const SizedBox(width: 8),
              Flexible(child: _buildStatBox(_getAvgAmpere('all'), 'All time')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVoltageGraph() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.bolt, color: Colors.blue, size: 16),
              SizedBox(width: 5),
              Text(
                'Voltage Sensor History',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildPeriodButton('Day'),
              _buildPeriodButton('Week'),
              _buildPeriodButton('Month'),
              _buildPeriodButton('All time'),
            ],
          ),
          const SizedBox(height: 25),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.withOpacity(0.15),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const SizedBox.shrink();
                        return Text(
                          '${value.toInt()}V',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: ampereHistory.isEmpty
                          ? 1
                          : (ampereHistory.length / 4).ceilToDouble(),
                      getTitlesWidget: (value, meta) {
                        if (ampereHistory.isEmpty) {
                          switch (value.toInt()) {
                            case 0:
                              return const Text(
                                '00:00',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 11,
                                ),
                              );
                            case 1:
                              return const Text(
                                '06:00',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 11,
                                ),
                              );
                            case 2:
                              return const Text(
                                '12:00',
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            case 3:
                              return const Text(
                                '18:00',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 11,
                                ),
                              );
                          }
                          return const SizedBox.shrink();
                        }

                        int index = value.toInt();
                        if (index < 0 || index >= ampereHistory.length) {
                          return const SizedBox.shrink();
                        }

                        try {
                          DateTime dateTime = DateTime.parse(
                            ampereHistory[index].createdAt,
                          );
                          String timeStr =
                              '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              timeStr,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 10,
                              ),
                            ),
                          );
                        } catch (e) {
                          return const SizedBox.shrink();
                        }
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: ampereHistory.isEmpty
                    ? 3
                    : (ampereHistory.length - 1).toDouble(),
                minY: _getMinVoltage(),
                maxY: _getMaxVoltage(),
                lineBarsData: [
                  LineChartBarData(
                    spots: _getVoltageSpots(),
                    isCurved: true,
                    color: Colors.blue,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          Colors.blue.withOpacity(0.3),
                          Colors.blue.withOpacity(0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(child: _buildStatBox(_getAvgVoltage('today'), 'Today')),
              const SizedBox(width: 8),
              Flexible(
                child: _buildStatBox(_getAvgVoltage('month'), 'This month'),
              ),
              const SizedBox(width: 8),
              Flexible(child: _buildStatBox(_getAvgVoltage('all'), 'All time')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(String label) {
    final isSelected = selectedPeriod == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedPeriod = label;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.transparent : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border(
            bottom: BorderSide(
              color: isSelected ? Colors.green : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.green : Colors.grey,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildStatBox(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 3),
          Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey)),
        ],
      ),
    );
  }

  // Get ampere data points for the graph from history
  List<FlSpot> _getAmpereSpots() {
    if (ampereHistory.isEmpty) {
      print('⚠️ No ampere history data, using default graph');
      // Return default data if no history
      return const [
        FlSpot(0, 1.5),
        FlSpot(1, 2.5),
        FlSpot(2, 3.5),
        FlSpot(3, 2.2),
      ];
    }

    print('📊 Building graph with ${ampereHistory.length} data points');
    List<FlSpot> spots = [];
    for (int i = 0; i < ampereHistory.length; i++) {
      spots.add(FlSpot(i.toDouble(), ampereHistory[i].ampere));
      if (i < 3) {
        print(
          '  Point $i: ${ampereHistory[i].ampere}A at ${ampereHistory[i].createdAt}',
        );
      }
    }
    return spots;
  }

  // Get max ampere value for Y axis
  double _getMaxAmpere() {
    if (ampereHistory.isEmpty) return 5.0;

    double max = ampereHistory
        .map((e) => e.ampere)
        .reduce((a, b) => a > b ? a : b);
    // Add 20% padding to max value
    print('📈 Graph Y-axis max: ${max * 1.2} (data max: $max)');
    return max * 1.2;
  }

  // Get voltage data points for the graph from history
  List<FlSpot> _getVoltageSpots() {
    if (ampereHistory.isEmpty) {
      // Return default data if no history
      return const [
        FlSpot(0, 218.5),
        FlSpot(1, 220.2),
        FlSpot(2, 222.8),
        FlSpot(3, 219.9),
      ];
    }

    List<FlSpot> spots = [];
    for (int i = 0; i < ampereHistory.length; i++) {
      double voltage = ampereHistory[i].voltage ?? 220.0;
      spots.add(FlSpot(i.toDouble(), voltage));
    }
    return spots;
  }

  // Get min voltage value for Y axis
  double _getMinVoltage() {
    if (ampereHistory.isEmpty) return 215.0;

    double min = ampereHistory
        .where((e) => e.voltage != null)
        .map((e) => e.voltage!)
        .fold(230.0, (a, b) => a < b ? a : b);
    // Subtract 5V padding
    return (min - 5.0).clamp(0, double.infinity);
  }

  // Get max voltage value for Y axis
  double _getMaxVoltage() {
    if (ampereHistory.isEmpty) return 230.0;

    double max = ampereHistory
        .where((e) => e.voltage != null)
        .map((e) => e.voltage!)
        .fold(0.0, (a, b) => a > b ? a : b);
    // Add 5V padding
    return max + 5.0;
  }

  // Get average ampere for different periods
  String _getAvgAmpere(String period) {
    if (ampereHistory.isEmpty) return '0.0A';

    double avg =
        ampereHistory.map((e) => e.ampere).reduce((a, b) => a + b) /
        ampereHistory.length;
    return '${avg.toStringAsFixed(1)}A';
  }

  // Get average voltage for different periods
  String _getAvgVoltage(String period) {
    if (ampereHistory.isEmpty) return '0.0V';

    var voltages = ampereHistory
        .where((e) => e.voltage != null)
        .map((e) => e.voltage!)
        .toList();
    if (voltages.isEmpty) return '0.0V';

    double avg = voltages.reduce((a, b) => a + b) / voltages.length;
    return '${avg.toStringAsFixed(1)}V';
  }
}
