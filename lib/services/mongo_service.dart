import 'package:mongo_dart/mongo_dart.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logbook_app_modul4/helpers/log_helper.dart';

/// MongoService - Menangani koneksi dan operasi database MongoDB
/// Menerapkan Single Responsibility Principle (SRP)
class MongoService {
  static const String sourceFile = "MongoService";

  Db? _db;
  bool _isConnected = false;

  /// Getter untuk mengecek status koneksi
  bool get isConnected => _isConnected;

  /// Getter untuk instance database
  Db? get database => _db;

  /// Method untuk membuka koneksi ke MongoDB Atlas
  Future<void> connect() async {
    try {
      // 1. Ambil Connection String dari .env
      final String? mongoUri = dotenv.env['MONGODB_URI'];

      if (mongoUri == null || mongoUri.isEmpty) {
        throw Exception("MONGODB_URI tidak ditemukan di file .env");
      }

      await LogHelper.writeLog(
        "Mencoba koneksi ke MongoDB Atlas...",
        source: sourceFile,
        level: 2,
      );

      // 2. Inisialisasi koneksi database
      _db = await Db.create(mongoUri);

      // 3. Buka koneksi
      await _db!.open();

      _isConnected = true;

      await LogHelper.writeLog(
        "✓ Koneksi MongoDB berhasil!",
        source: sourceFile,
        level: 2,
      );
    } catch (e) {
      _isConnected = false;
      await LogHelper.writeLog(
        "✗ Koneksi MongoDB gagal: $e",
        source: sourceFile,
        level: 1,
      );
      rethrow; // Lempar ulang error agar bisa ditangkap oleh caller
    }
  }

  /// Method untuk menutup koneksi database
  Future<void> close() async {
    try {
      if (_db != null && _isConnected) {
        await _db!.close();
        _isConnected = false;

        await LogHelper.writeLog(
          "Koneksi MongoDB ditutup",
          source: sourceFile,
          level: 2,
        );
      }
    } catch (e) {
      await LogHelper.writeLog(
        "Error saat menutup koneksi: $e",
        source: sourceFile,
        level: 1,
      );
    }
  }

  /// Method untuk mengakses collection tertentu
  /// Contoh: getCollection('logbook_db', 'logs')
  DbCollection? getCollection(String databaseName, String collectionName) {
    if (!_isConnected || _db == null) {
      LogHelper.writeLog(
        "Database belum terkoneksi!",
        source: sourceFile,
        level: 1,
      );
      return null;
    }

    return _db!.collection(collectionName);
  }
}
