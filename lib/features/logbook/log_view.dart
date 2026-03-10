import 'package:flutter/material.dart';
import 'package:logbook_app_modul5/features/logbook/log_controller.dart';
import 'package:logbook_app_modul5/features/logbook/models/log_model.dart';
import 'package:logbook_app_modul5/features/logbook/log_editor_page.dart';
import 'package:logbook_app_modul5/features/onboarding/onboarding_view.dart';
import 'package:logbook_app_modul5/services/access_control_service.dart';
import 'package:logbook_app_modul5/services/connectivity_service.dart';

/// LogView - Main Logbook Page (Modul 5: Offline-First & RBAC)
///
/// Konsep: Collaborative Logbook dengan Team Isolation & Role-Based Access
/// Logika: ValueListenable + RBAC Gatekeeper + Navigation to dedicated Editor
/// Tujuan: Production-ready collaborative logging system
class LogView extends StatefulWidget {
  final Map<String, String> currentUser; // {username, role, uid, teamId}

  const LogView({super.key, required this.currentUser});

  @override
  State<LogView> createState() => _LogViewState();
}

class _LogViewState extends State<LogView> {
  late LogController _controller;
  final ConnectivityService _connectivityService = ConnectivityService();

  @override
  void initState() {
    super.initState();
    _controller = LogController();

    // Load logs for current user's team (Team Isolation)
    _controller.loadFromDisk(teamId: widget.currentUser['teamId']);

    // Start connectivity monitoring for Auto-Sync
    _connectivityService.startMonitoring(
      onConnectivityRestored: () {
        // Auto-sync when network restored
        _controller.loadFromDisk(teamId: widget.currentUser['teamId']);

        // Show notification
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🌐 Koneksi pulih! Data sedang disinkronkan...'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      },
    );
  }

  @override
  void dispose() {
    _connectivityService.stopMonitoring();
    super.dispose();
  }

  /// Navigate to LogEditorPage (Full-Page Editor dengan Markdown)
  void _goToEditor({LogModel? log, int? index}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LogEditorPage(
          log: log,
          index: index,
          controller: _controller,
          currentUser: widget.currentUser,
        ),
      ),
    );
  }

  /// Delete Log dengan Confirmation Dialog
  Future<void> _deleteLog(int index) async {
    final log = _controller.logs[index];

    // GATEKEEPER: Security check di UI layer
    final bool isOwner = log.authorId == widget.currentUser['uid'];
    if (!AccessControlService.canPerform(
      widget.currentUser['role']!,
      AccessControlService.actionDelete,
      isOwner: isOwner,
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '❌ Anda tidak memiliki akses untuk menghapus data ini!',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Confirmation Dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Konfirmasi Hapus'),
        content: Text('Yakin ingin menghapus "${log.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await _controller.removeLog(index, currentUser: widget.currentUser);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Data berhasil dihapus'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Gagal menghapus: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Logbook Digital', style: TextStyle(fontSize: 18)),
            Text(
              '${widget.currentUser['username']} • ${widget.currentUser['role']}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          // Info RBAC
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('🔐 Hak Akses Anda'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Role: ${widget.currentUser['role']}'),
                      Text('Team: ${widget.currentUser['teamId']}'),
                      const SizedBox(height: 12),
                      const Text(
                        'Permissions:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      ...AccessControlService.getPermissions(
                        widget.currentUser['role']!,
                      ).map((perm) => Text('✅ $perm')),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),
          // Logout Button
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Konfirmasi Logout'),
                  content: const Text('Yakin ingin keluar?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Batal'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context); // Close dialog
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const OnboardingView(),
                          ),
                          (route) => false,
                        );
                      },
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Keluar'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),

      // Body: ValueListenableBuilder untuk Reactive UI
      body: ValueListenableBuilder<List<LogModel>>(
        valueListenable: _controller.logsNotifier,
        builder: (context, logs, child) {
          // Empty State
          if (logs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.note_alt_outlined,
                    size: 80,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Belum ada catatan',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Klik tombol + untuk membuat catatan pertama',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _goToEditor(),
                    icon: const Icon(Icons.add),
                    label: const Text('Buat Catatan'),
                  ),
                ],
              ),
            );
          }

          // List of Logs
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[index];

              // Check ownership untuk RBAC
              final bool isOwner = log.authorId == widget.currentUser['uid'];

              // Check permissions
              final canEdit = AccessControlService.canPerform(
                widget.currentUser['role']!,
                AccessControlService.actionUpdate,
                isOwner: isOwner,
              );
              final canDelete = AccessControlService.canPerform(
                widget.currentUser['role']!,
                AccessControlService.actionDelete,
                isOwner: isOwner,
              );

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  // Sync Status Icon
                  leading: CircleAvatar(
                    backgroundColor: log.id != null
                        ? Colors.green
                        : Colors.orange,
                    child: Icon(
                      log.id != null ? Icons.cloud_done : Icons.cloud_upload,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    log.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 6),
                      Text(
                        log.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      // Metadata Row
                      Row(
                        children: [
                          // Author Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isOwner ? Colors.blue : Colors.grey,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              log.authorId,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          const Spacer(),
                          // Date
                          Text(
                            log.date.split(' ')[0], // Show date only
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  // Action Buttons (RBAC Gatekeeper)
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (canEdit)
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _goToEditor(log: log, index: index),
                          tooltip: 'Edit',
                        ),
                      if (canDelete)
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteLog(index),
                          tooltip: 'Hapus',
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),

      // Floating Action Button
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _goToEditor(),
        icon: const Icon(Icons.add),
        label: const Text('Catatan Baru'),
        backgroundColor: Colors.indigo,
      ),
    );
  }
}
