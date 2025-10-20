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
      // Use AutoSyncService for immediate sync
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
            ElevatedButton(
              onPressed: syncing ? null : _syncNow,
              child: syncing ? const CircularProgressIndicator() : const Text('Sync Now'),
            ),
            const SizedBox(height: 16),
            Text(syncStatus, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () async {
                try {
                  await AuthService().signOut();
                  if (!context.mounted) return;
                  // Pop to root and show sign-in screen
                  Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Logout failed: $e')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }
}
