import 'package:flutter/material.dart';
import '../../core/design/app_colors.dart';
import '../../services/auto_sync_service.dart';
import '../../services/auth_service.dart';


class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool syncing = false;
  String syncStatus = '';

  Future<void> _syncNow() async {
    setState(() {
      syncing = true;
      syncStatus = 'Syncing...';
    });
    try {
      // Use AutoSyncService for immediate sync (push + pull)
      await AutoSyncService().syncNow();
      
      setState(() {
        syncStatus = 'Sync successful! ✓';
      });
    } catch (e) {
      setState(() {
        syncStatus = 'Sync failed: $e';
      });
    } finally {
      setState(() {
        syncing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.primary : AppColors.backgroundLight,
      appBar: AppBar(title: const Text('Settings'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sync Now button - performs bidirectional sync (push + pull)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: syncing ? null : _syncNow,
                icon: syncing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.sync),
                label: Text(syncing ? 'Syncing...' : 'Sync Now'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (syncStatus.isNotEmpty)
              Text(
                syncStatus,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: syncStatus.contains('✓') ? Colors.green : Colors.red,
                    ),
              ),
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),
            // Logout button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  try {
                    await AuthService().signOut();
                    if (!context.mounted) return;
                    // Pop to root and show sign-in screen
                    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Logout failed: $e')),
                    );
                  }
                },
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
