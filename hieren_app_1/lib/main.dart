import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // 1. Import ini
// Import halaman report Anda (sesuaikan nama filenya)
import 'pages/report_page.dart'; 

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Solar Energy App',
      
      // 2. Atur Font Global di sini
      theme: ThemeData(
        useMaterial3: true,
        // Ini baris ajaibnya: Mengubah semua gaya teks default menjadi Montserrat
        textTheme: GoogleFonts.montserratTextTheme(
          Theme.of(context).textTheme,
        ),
        // Sesuaikan warna utama aplikasi (misal Hijau seperti desain Anda)
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
      ),
      
      home: const ReportPage(),
    );
  }
}