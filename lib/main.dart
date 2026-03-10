import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart'; // Gunakan hive_flutter, bukan hive biasa
import 'package:logbook_app_modul5/features/logbook/models/log_model.dart';
import 'package:logbook_app_modul5/features/onboarding/onboarding_view.dart';

void main() async {
  // Wajib untuk operasi asinkron sebelum runApp
  WidgetsFlutterBinding.ensureInitialized();

  // Load ENV - Memuat konfigurasi dari file .env
  await dotenv.load(fileName: ".env");

  // INISIALISASI HIVE (Modul 5 - Offline-First Strategy)
  await Hive.initFlutter();
  Hive.registerAdapter(LogModelAdapter()); // WAJIB: Sesuai nama di .g.dart
  await Hive.openBox<LogModel>(
    'offline_logs',
  ); // Buka box sebelum Controller dipakai

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'LogBook App - Modul 5',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      ),
      home: const OnboardingView(),
    );
  }
}
