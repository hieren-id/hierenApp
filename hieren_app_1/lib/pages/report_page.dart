import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; // Pastikan sudah 'flutter pub add fl_chart'

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  bool isMainElectricity = true; // Untuk state switch di pojok kanan atas

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Warna background abu muda
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. HEADER (Judul & Switch)
              _buildHeader(),
              const SizedBox(height: 20),

              // 2. KARTU UTAMA (Solar Power Usage)
              _buildSolarUsageCard(),
              const SizedBox(height: 20),

              // 3. GRID STATISTIK (4 Kartu Kecil)
              _buildStatsGrid(),
              const SizedBox(height: 20),

              // 4. GRAFIK (Chart)
              _buildGraphCard(),
              const SizedBox(height: 80), // Spasi bawah agar tidak tertutup nav bar
            ],
          ),
        ),
      ),
      
      // 5. BOTTOM NAVIGATION BAR
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Statistics'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications_outlined), label: 'Notification'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: 'Settings'),
        ],
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Report',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            Text(
              'Monday 18, 2023',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Transform.scale(
              scale: 0.8,
              child: Switch(
                value: isMainElectricity,
                activeColor: Colors.white,
                activeTrackColor: Colors.green,
                onChanged: (val) {
                  setState(() => isMainElectricity = val);
                },
              ),
            ),
            const Text(
              'Switch to main electricity',
              style: TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildSolarUsageCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.green.withOpacity(0.5)),
                ),
                child: const Icon(Icons.electric_bolt, color: Colors.green),
              ),
              const SizedBox(width: 15),
              const Text(
                '30.276KWh',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('Solar Power Usage', style: TextStyle(color: Colors.grey)),
              Text('40%', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: const LinearProgressIndicator(
              value: 0.4, // 40%
              minHeight: 8,
              backgroundColor: Color(0xFFEEEEEE),
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 15,
      mainAxisSpacing: 15,
      childAspectRatio: 1.1, // Mengatur rasio lebar:tinggi kartu
      children: [
        _statCard(Icons.lightbulb_outline, 'Total energy', '36.2', 'Kwh'),
        _statCard(Icons.bolt, 'Consumed', '28.2', 'Kwh'),
        _statCard(Icons.savings_outlined, 'Capacity', '42.0', 'Kwh'),
        _statCard(Icons.eco_outlined, 'Co2 Reduction', '28.2', 'Kwh'),
      ],
    );
  }

  Widget _statCard(IconData icon, String title, String value, String unit) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 30, color: Colors.black87),
          const Spacer(),
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 5),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(unit, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGraphCard() {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Electricity generated by solar', style: TextStyle(color: Colors.grey, fontSize: 12)),
              Icon(Icons.more_horiz, color: Colors.grey[400]),
            ],
          ),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('140.65KWh', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              Row(
                children: const [
                  Icon(Icons.circle, size: 10, color: Colors.green),
                  SizedBox(width: 5),
                  Text('Live', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                ],
              )
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.withOpacity(0.2),
                      strokeWidth: 1,
                      dashArray: [5, 5], // Garis putus-putus
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        if (value == 0 || value == 200) return const SizedBox.shrink(); // Sembunyikan 0 dan max
                        return Text('${value.toInt()}KWh', style: const TextStyle(color: Colors.grey, fontSize: 10));
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        switch (value.toInt()) {
                          case 0: return const Text('13:00', style: TextStyle(color: Colors.grey, fontSize: 10));
                          case 2: return const Text('14:00', style: TextStyle(color: Colors.grey, fontSize: 10));
                          case 4: return const Text('15:00', style: TextStyle(color: Colors.grey, fontSize: 10));
                          case 6: return const Text('16:00', style: TextStyle(color: Colors.grey, fontSize: 10));
                          case 8: return const Text('17:00', style: TextStyle(color: Colors.grey, fontSize: 10));
                          case 10: return const Text('18:00', style: TextStyle(color: Colors.grey, fontSize: 10));
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 10,
                minY: 0,
                maxY: 200,
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 60),
                      FlSpot(1, 130),
                      FlSpot(1.5, 115),
                      FlSpot(2.5, 140),
                      FlSpot(3.5, 125),
                      FlSpot(4, 75),
                      FlSpot(5.5, 75),
                      FlSpot(6.5, 110),
                      FlSpot(7.5, 70),
                      FlSpot(8.5, 120),
                      FlSpot(9.2, 110),
                      FlSpot(9.5, 70),
                      FlSpot(10, 120),
                    ],
                    isCurved: true, // Membuat garis melengkung halus
                    color: Colors.green,
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          Colors.green.withOpacity(0.4),
                          Colors.green.withOpacity(0.0),
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
        ],
      ),
    );
  }
}