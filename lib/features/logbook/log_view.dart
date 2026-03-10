import 'dart:io'; // Homework: Connection Guard
import 'dart:async'; // Homework: TimeoutException
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Homework: Timestamp Formatting
import 'package:logbook_app_modul5/features/logbook/log_controller.dart';
import 'package:logbook_app_modul5/features/logbook/models/log_model.dart';
import 'package:logbook_app_modul5/features/onboarding/onboarding_view.dart';
import 'package:logbook_app_modul5/services/mongo_service.dart';
import 'package:logbook_app_modul5/helpers/log_helper.dart';

class LogView extends StatefulWidget {
  final String username;

  const LogView({super.key, required this.username});

  @override
  State<LogView> createState() => _LogViewState();
}

class _LogViewState extends State<LogView> {
  late LogController _controller;
  Key _futureKey =
      UniqueKey(); // Task 3: Trigger untuk auto-refresh FutureBuilder

  // Controller untuk menangkap input di dalam State
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  // HOMEWORK: Category management
  String _selectedCategory = 'Pribadi';
  final List<String> _categories = ['Pribadi', 'Pekerjaan', 'Kuliah', 'Urgent'];

  @override
  void initState() {
    super.initState();
    _controller = LogController();
    // Task 3: FutureBuilder akan handle fetch otomatis di build()
  }

  // Task 3: Future-Based Method untuk FutureBuilder
  // Homework: Enhanced dengan Connection Guard
  Future<List<LogModel>> _fetchLogs() async {
    try {
      await LogHelper.writeLog(
        "UI: [FutureBuilder] Connecting to MongoDB Atlas...",
        source: "log_view.dart",
      );

      // Homework: Connection Guard - Check internet connectivity
      try {
        final result = await InternetAddress.lookup(
          'google.com',
        ).timeout(const Duration(seconds: 3));
        if (result.isEmpty || result[0].rawAddress.isEmpty) {
          throw SocketException('No Internet Connection');
        }
      } on SocketException {
        throw Exception(
          '📡 Offline Mode: Tidak ada koneksi internet.\n'
          'Periksa WiFi/Data dan coba lagi.',
        );
      } on TimeoutException {
        throw Exception(
          '⏱️ Koneksi Lambat: Timeout saat cek koneksi.\n'
          'Periksa kecepatan internet Anda.',
        );
      }

      // Task 3: Connect ke MongoDB Atlas dengan timeout
      await MongoService().connect().timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw Exception(
          '⏱️ Koneksi Timeout (15s).\n'
          'Periksa IP Whitelist di MongoDB Atlas.',
        ),
      );

      await LogHelper.writeLog(
        "UI: [FutureBuilder] Connected successfully.",
        source: "log_view.dart",
      );

      // Task 3: Ambil data dari MongoDB Atlas Cloud
      final logs = await MongoService().getLogs();

      await LogHelper.writeLog(
        "UI: [FutureBuilder] Fetched ${logs.length} logs from Cloud.",
        source: "log_view.dart",
      );

      return logs;
    } on SocketException catch (e) {
      // Homework: Connection Guard - Network errors
      await LogHelper.writeLog(
        "UI: [Connection Guard] Network Error - $e",
        source: "log_view.dart",
        level: 1,
      );
      throw Exception(
        '📡 Kesalahan Jaringan\n'
        'Tidak dapat terhubung ke server.\n'
        'Periksa koneksi internet Anda.',
      );
    } on TimeoutException catch (e) {
      await LogHelper.writeLog(
        "UI: [Connection Guard] Timeout - $e",
        source: "log_view.dart",
        level: 1,
      );
      throw Exception(
        '⏱️ Waktu Habis\n'
        'Server tidak merespon (15 detik).\n'
        'Coba lagi atau periksa koneksi.',
      );
    } catch (e) {
      await LogHelper.writeLog(
        "UI: [FutureBuilder] Error - $e",
        source: "log_view.dart",
        level: 1,
      );
      rethrow; // Task 3: Lempar error ke FutureBuilder.hasError
    }
  }

  // Homework: Pull-to-Refresh handler
  Future<void> _refreshLogs() async {
    setState(() => _futureKey = UniqueKey());
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // HOMEWORK: Get category color
  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Pekerjaan':
        return Colors.blue;
      case 'Kuliah':
        return Colors.green;
      case 'Urgent':
        return Colors.red;
      case 'Pribadi':
      default:
        return Colors.purple;
    }
  }

  // HOMEWORK: Get category icon
  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Pekerjaan':
        return Icons.work;
      case 'Kuliah':
        return Icons.school;
      case 'Urgent':
        return Icons.priority_high;
      case 'Pribadi':
      default:
        return Icons.person;
    }
  }

  void _showAddLogDialog() {
    _selectedCategory = 'Pribadi'; // Reset category
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Tambah Catatan Baru"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: "Judul Catatan",
                    prefixIcon: Icon(Icons.title),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _contentController,
                  decoration: const InputDecoration(
                    labelText: "Isi Deskripsi",
                    prefixIcon: Icon(Icons.description),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 15),
                // HOMEWORK: Category dropdown
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: "Kategori",
                    prefixIcon: Icon(Icons.category),
                    border: OutlineInputBorder(),
                  ),
                  items: _categories.map((String category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Row(
                        children: [
                          Icon(
                            _getCategoryIcon(category),
                            color: _getCategoryColor(category),
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Text(category),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setDialogState(() {
                      _selectedCategory = newValue!;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _titleController.clear();
                _contentController.clear();
                Navigator.pop(context);
              },
              child: const Text("Batal"),
            ),
            ElevatedButton(
              onPressed: () {
                // Validasi input kosong
                if (_titleController.text.isEmpty ||
                    _contentController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        '⚠️ Judul dan Deskripsi tidak boleh kosong!',
                      ),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                // HOMEWORK: Jalankan fungsi tambah dengan teamId dan authorId
                _controller
                    .addLog(
                      _titleController.text,
                      _contentController.text,
                      authorId: widget.username,
                      teamId: 'MEKTRA_KLP_01', // TODO: Ambil dari user profile
                    )
                    .then((_) {
                      // Task 3: Auto-refresh dengan ganti key FutureBuilder
                      setState(() => _futureKey = UniqueKey());

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✓ Data berhasil disimpan ke Cloud!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    })
                    .catchError((error) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('✗ Gagal: $error'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    });

                // Bersihkan input dan tutup dialog
                _titleController.clear();
                _contentController.clear();
                Navigator.pop(context);
              },
              child: const Text("Simpan"),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditLogDialog(int index, LogModel log) {
    _titleController.text = log.title;
    _contentController.text = log.description;
    _selectedCategory = 'Pribadi'; // Reset category (field removed in Modul 5)
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Edit Catatan"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: "Judul Catatan",
                    prefixIcon: Icon(Icons.title),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _contentController,
                  decoration: const InputDecoration(
                    labelText: "Isi Deskripsi",
                    prefixIcon: Icon(Icons.description),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 15),
                // HOMEWORK: Category dropdown
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: "Kategori",
                    prefixIcon: Icon(Icons.category),
                    border: OutlineInputBorder(),
                  ),
                  items: _categories.map((String category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Row(
                        children: [
                          Icon(
                            _getCategoryIcon(category),
                            color: _getCategoryColor(category),
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Text(category),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setDialogState(() {
                      _selectedCategory = newValue!;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _titleController.clear();
                _contentController.clear();
                Navigator.pop(context);
              },
              child: const Text("Batal"),
            ),
            ElevatedButton(
              onPressed: () {
                // Validasi input kosong
                if (_titleController.text.isEmpty ||
                    _contentController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        '⚠️ Judul dan Deskripsi tidak boleh kosong!',
                      ),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                // Update log tanpa perlu category (authorId dan teamId tetap sama)
                _controller
                    .updateLog(
                      index,
                      _titleController.text,
                      _contentController.text,
                    )
                    .then((_) {
                      if (mounted) {
                        // Task 3: Auto-refresh dengan ganti key FutureBuilder
                        setState(() => _futureKey = UniqueKey());

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('✓ Data berhasil diupdate di Cloud!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    })
                    .catchError((error) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('✗ Gagal: $error'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    });
                _titleController.clear();
                _contentController.clear();
                Navigator.pop(context);
              },
              child: const Text("Update"),
            ),
          ],
        ),
      ),
    );
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi Logout'),
          content: const Text(
            'Apakah Anda yakin ingin keluar? Data catatan Anda sudah tersimpan otomatis.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const OnboardingView(),
                  ),
                  (route) => false,
                );
              },
              child: const Text(
                'Ya, Logout',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Logbook - ${widget.username}'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: Column(
        children: [
          // HOMEWORK: Search bar
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                // Task 3: Trigger rebuild untuk apply filter
                setState(() {});
              },
              decoration: InputDecoration(
                labelText: "Cari Catatan...",
                hintText: "Ketik judul atau deskripsi",
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            // Task 3: setState cukup untuk trigger rebuild
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
          ),
          // Task 3: FutureBuilder untuk async data dari MongoDB Atlas
          // HOMEWORK: Pull-to-Refresh dengan RefreshIndicator
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshLogs,
              child: FutureBuilder<List<LogModel>>(
                key: _futureKey, // Task 3: Ganti key untuk trigger refresh
                future: _fetchLogs(),
                builder: (context, snapshot) {
                  // Task 3 Requirement #2: Loading State
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text("Menghubungkan ke MongoDB Atlas..."),
                        ],
                      ),
                    );
                  }

                  // Task 3: Error State + HOMEWORK: Enhanced Offline UI
                  if (snapshot.hasError) {
                    final errorMsg = snapshot.error.toString();
                    final isOffline =
                        errorMsg.contains('📡') ||
                        errorMsg.contains('Jaringan') ||
                        errorMsg.contains('Offline');

                    return SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isOffline ? Icons.wifi_off : Icons.cloud_off,
                                size: 80,
                                color: isOffline ? Colors.orange : Colors.red,
                              ),
                              const SizedBox(height: 20),
                              Text(
                                isOffline ? "Mode Offline" : "Kesalahan Server",
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: isOffline
                                      ? Colors.orange[700]
                                      : Colors.red[700],
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                errorMsg,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                ),
                              ),
                              if (isOffline) ...[
                                const SizedBox(height: 20),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.orange[50],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.orange.shade200,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.tips_and_updates,
                                        color: Colors.orange[700],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        "Tips:",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.orange[700],
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "• Periksa koneksi WiFi atau Data Seluler\n"
                                        "• Pastikan sinyal stabil\n"
                                        "• Tarik ke bawah untuk muat ulang",
                                        textAlign: TextAlign.left,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(height: 20),
                              ElevatedButton.icon(
                                onPressed: () {
                                  setState(() => _futureKey = UniqueKey());
                                },
                                icon: const Icon(Icons.refresh),
                                label: const Text("Coba Lagi"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isOffline
                                      ? Colors.orange
                                      : Colors.red,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  // Task 3: Success - ambil data dari snapshot
                  final allLogs = snapshot.data ?? [];

                  // Task 3: Apply search filter di UI layer
                  final currentLogs = _searchController.text.isEmpty
                      ? allLogs
                      : allLogs.where((log) {
                          final query = _searchController.text.toLowerCase();
                          return log.title.toLowerCase().contains(query) ||
                              log.description.toLowerCase().contains(query);
                        }).toList();

                  // Task 3 Requirement #3: Pesan "Data Kosong" dari MongoDB
                  if (currentLogs.isEmpty && _searchController.text.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.cloud_off,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          const Text("Belum ada catatan di Cloud."),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: _showAddLogDialog,
                            child: const Text("Buat Catatan Pertama"),
                          ),
                        ],
                      ),
                    );
                  }

                  // 3. Tampilan hasil pencarian kosong
                  if (currentLogs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _searchController.text.isEmpty
                                ? Icons.note_add
                                : Icons.search_off,
                            size: 100,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 20),
                          Text(
                            _searchController.text.isEmpty
                                ? "Belum ada catatan."
                                : "Tidak ada hasil pencarian",
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _searchController.text.isEmpty
                                ? "Tekan tombol + untuk menambah catatan"
                                : "Coba kata kunci lain",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                          if (_searchController.text.isEmpty) ...[
                            const SizedBox(height: 30),
                            Icon(
                              Icons.arrow_downward,
                              color: Colors.grey[400],
                              size: 40,
                            ),
                          ],
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: currentLogs.length,
                    itemBuilder: (context, index) {
                      final log = currentLogs[index];
                      final displayDate = _formatDate(log.date);
                      // Modul 5: Ganti category dengan author info
                      final categoryColor = Colors.indigo;
                      final categoryIcon = Icons.person;

                      // HOMEWORK: Dismissible for swipe-to-delete
                      return Dismissible(
                        key: Key(log.date),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.delete, color: Colors.white, size: 32),
                              SizedBox(height: 4),
                              Text(
                                'Hapus',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        confirmDismiss: (direction) async {
                          return await showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Konfirmasi Hapus'),
                              content: Text(
                                'Yakin ingin menghapus "${log.title}"?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Batal'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text(
                                    'Hapus',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        onDismissed: (direction) async {
                          // Find real index in logsNotifier
                          final realIndex = _controller.logsNotifier.value
                              .indexWhere((l) => l.date == log.date);

                          try {
                            await _controller.removeLog(realIndex);

                            // Task 3: Auto-refresh dengan ganti key FutureBuilder
                            if (mounted) {
                              setState(() => _futureKey = UniqueKey());
                            }

                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '✓ "${log.title}" dihapus dari Cloud',
                                  ),
                                  backgroundColor: Colors.green,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('✗ Gagal hapus: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                        child:
                            // HOMEWORK: Card with category color
                            Card(
                              elevation: 3,
                              margin: const EdgeInsets.symmetric(
                                vertical: 6,
                                horizontal: 4,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: categoryColor.withOpacity(0.5),
                                  width: 2,
                                ),
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  gradient: LinearGradient(
                                    colors: [
                                      categoryColor.withOpacity(0.1),
                                      Colors.white,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  leading: CircleAvatar(
                                    backgroundColor: categoryColor,
                                    child: Icon(
                                      categoryIcon,
                                      color: Colors.white,
                                    ),
                                  ),
                                  title: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          log.title,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                      // Category chip
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: categoryColor,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          log.authorId,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 6),
                                      Text(
                                        log.description,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.cloud_done,
                                            size: 14,
                                            color: Colors.green,
                                          ),
                                          const SizedBox(width: 4),
                                          Icon(
                                            Icons.access_time,
                                            size: 14,
                                            color: Colors.grey[600],
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            displayDate,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  trailing: IconButton(
                                    icon: Icon(
                                      Icons.edit,
                                      color: categoryColor,
                                    ),
                                    onPressed: () {
                                      // Find real index
                                      final realIndex = _controller
                                          .logsNotifier
                                          .value
                                          .indexWhere(
                                            (l) => l.date == log.date,
                                          );
                                      _showEditLogDialog(realIndex, log);
                                    },
                                  ),
                                ),
                              ),
                            ),
                      );
                    },
                  );
                },
              ),
            ), // Closing RefreshIndicator
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddLogDialog,
        tooltip: 'Tambah Catatan',
        child: const Icon(Icons.add),
      ),
    );
  }

  // HOMEWORK: Relative Timestamp Formatting (Indonesian)
  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      // Less than 60 seconds
      if (difference.inSeconds < 60) {
        return 'Baru saja';
      }

      // Less than 60 minutes
      if (difference.inMinutes < 60) {
        final minutes = difference.inMinutes;
        return '$minutes menit yang lalu';
      }

      // Less than 24 hours
      if (difference.inHours < 24) {
        final hours = difference.inHours;
        return '$hours jam yang lalu';
      }

      // Yesterday (1 day ago)
      if (difference.inDays == 1) {
        final time =
            '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
        return 'Kemarin $time';
      }

      // Less than 7 days
      if (difference.inDays < 7) {
        final days = difference.inDays;
        return '$days hari yang lalu';
      }

      // 7 days or more: Absolute format
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'Mei',
        'Jun',
        'Jul',
        'Agu',
        'Sep',
        'Okt',
        'Nov',
        'Des',
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }
}
