import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart' show ObjectId;
import 'models/log_model.dart';
import 'package:logbook_app_modul5/services/mongo_service.dart';
import 'package:logbook_app_modul5/helpers/log_helper.dart';

class LogController {
  final ValueNotifier<List<LogModel>> logsNotifier =
      ValueNotifier<List<LogModel>>([]);
  final ValueNotifier<List<LogModel>> filteredLogsNotifier =
      ValueNotifier<List<LogModel>>([]);

  // Getter untuk mempermudah akses list data saat ini
  List<LogModel> get logs => logsNotifier.value;

  // --- KONSTRUKTOR ---
  // Saat Controller dibuat, ia otomatis mencoba mengambil data dari Cloud
  LogController() {
    loadFromDisk();
  }

  // HOMEWORK: Search feature untuk filter logs secara real-time
  void searchLog(String query) {
    if (query.isEmpty) {
      filteredLogsNotifier.value = logsNotifier.value;
    } else {
      filteredLogsNotifier.value = logsNotifier.value
          .where(
            (log) =>
                log.title.toLowerCase().contains(query.toLowerCase()) ||
                log.description.toLowerCase().contains(query.toLowerCase()),
          )
          .toList();
    }
  }

  // 1. Menambah data ke Cloud
  Future<void> addLog(
    String title,
    String desc, {
    required String authorId,
    required String teamId,
  }) async {
    final newLog = LogModel(
      id: null, // Akan di-generate oleh MongoDB
      title: title,
      description: desc,
      date: DateTime.now().toString(),
      authorId: authorId,
      teamId: teamId,
    );

    try {
      // Kirim ke MongoDB Atlas
      await MongoService().insertLog(newLog);

      // Update UI Lokal
      final currentLogs = List<LogModel>.from(logsNotifier.value);
      currentLogs.add(newLog);
      logsNotifier.value = currentLogs;
      filteredLogsNotifier.value = logsNotifier.value;

      await LogHelper.writeLog(
        "SUCCESS: Tambah data '${newLog.title}' berhasil",
        source: "log_controller.dart",
        level: 2,
      );
    } catch (e) {
      await LogHelper.writeLog(
        "ERROR: Gagal sinkronisasi Add - $e",
        source: "log_controller.dart",
        level: 1,
      );
      rethrow;
    }
  }

  // 2. Memperbarui data di Cloud
  Future<void> updateLog(
    int index,
    String newTitle,
    String newDesc,
  ) async {
    final currentLogs = List<LogModel>.from(logsNotifier.value);
    final oldLog = currentLogs[index];

    final updatedLog = LogModel(
      id: oldLog.id, // ID harus tetap sama
      title: newTitle,
      description: newDesc,
      date: DateTime.now().toString(),
      authorId: oldLog.authorId, // Tetap sama
      teamId: oldLog.teamId, // Tetap sama
    );

    try {
      // Jalankan update di MongoService
      await MongoService().updateLog(updatedLog);

      // Jika sukses, baru perbarui state lokal
      currentLogs[index] = updatedLog;
      logsNotifier.value = currentLogs;
      filteredLogsNotifier.value = logsNotifier.value;

      await LogHelper.writeLog(
        "SUCCESS: Sinkronisasi Update '${oldLog.title}' Berhasil",
        source: "log_controller.dart",
        level: 2,
      );
    } catch (e) {
      await LogHelper.writeLog(
        "ERROR: Gagal sinkronisasi Update - $e",
        source: "log_controller.dart",
        level: 1,
      );
      rethrow;
    }
  }

  // 3. Menghapus data dari Cloud
  Future<void> removeLog(int index) async {
    final currentLogs = List<LogModel>.from(logsNotifier.value);
    final targetLog = currentLogs[index];

    try {
      if (targetLog.id == null) {
        throw Exception(
          "ID Log tidak ditemukan, tidak bisa menghapus di Cloud.",
        );
      }

      // Hapus data di MongoDB Atlas
      await MongoService().deleteLog(ObjectId.fromHexString(targetLog.id!));

      // Jika sukses, baru hapus dari state lokal
      currentLogs.removeAt(index);
      logsNotifier.value = currentLogs;
      filteredLogsNotifier.value = logsNotifier.value;

      await LogHelper.writeLog(
        "SUCCESS: Sinkronisasi Hapus '${targetLog.title}' Berhasil",
        source: "log_controller.dart",
        level: 2,
      );
    } catch (e) {
      await LogHelper.writeLog(
        "ERROR: Gagal sinkronisasi Hapus - $e",
        source: "log_controller.dart",
        level: 1,
      );
      rethrow;
    }
  }

  // Ganti pemanggilan SharedPreferences menjadi MongoService
  Future<void> loadFromDisk() async {
    try {
      await LogHelper.writeLog(
        "Controller: Memuat data dari Cloud...",
        source: "log_controller.dart",
        level: 3,
      );

      // Mengambil dari Cloud, bukan lokal
      final cloudData = await MongoService().getLogs();
      logsNotifier.value = cloudData;
      filteredLogsNotifier.value = cloudData;

      await LogHelper.writeLog(
        "Controller: Berhasil memuat ${cloudData.length} data",
        source: "log_controller.dart",
        level: 2,
      );
    } catch (e) {
      await LogHelper.writeLog(
        "Controller: Error saat memuat data - $e",
        source: "log_controller.dart",
        level: 1,
      );
      // Set ke empty list jika gagal
      logsNotifier.value = [];
      filteredLogsNotifier.value = [];
    }
  }
}
