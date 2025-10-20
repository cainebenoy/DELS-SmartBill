import 'dart:async';
import '../data/db/app_database.dart';
import 'sync_service.dart';
import 'package:logger/logger.dart';

/// Handles automatic syncing with debouncing to avoid excessive sync operations
class AutoSyncService {
  final Logger _logger = Logger();
  static final AutoSyncService _instance = AutoSyncService._internal();
  factory AutoSyncService() => _instance;
  AutoSyncService._internal();

  final _syncService = SyncService();
  Timer? _debounceTimer;
  bool _isSyncing = false;
  
  /// Debounce duration - wait this long after last mutation before syncing
  static const _debounceDuration = Duration(seconds: 2);

  /// Trigger a sync after a mutation (create/update/delete)
  /// Uses debouncing to batch multiple rapid changes into a single sync
  Future<void> syncAfterMutation() async {
    // Cancel any pending sync
    _debounceTimer?.cancel();

    // Schedule a new sync after debounce duration
    _debounceTimer = Timer(_debounceDuration, () {
      _performSync();
    });
  }

  /// Immediately sync (used for app resume, manual sync, etc.)
  Future<void> syncNow() async {
    // Cancel any pending debounced sync
    _debounceTimer?.cancel();
    
    await _performSync();
  }

  /// Internal method that performs the actual sync
  Future<void> _performSync() async {
    if (_isSyncing) {
      _logger.w('[AutoSync] Sync already in progress, skipping...');
      return;
    }

    try {
      _isSyncing = true;
      _logger.i('[AutoSync] Starting automatic sync...');

      final db = await openAppDatabase();

      // Push local changes first
      await _syncService.push(db);

      // Then pull remote changes
      await _syncService.pull(db);

      _logger.i('[AutoSync] Automatic sync completed');
    } catch (e) {
      _logger.e('[AutoSync] Sync failed: $e');
      // Don't rethrow - we don't want to crash the app on sync failures
    } finally {
      _isSyncing = false;
    }
  }

  /// Cancel any pending sync (useful when app is closing)
  void dispose() {
    _debounceTimer?.cancel();
  }
}
