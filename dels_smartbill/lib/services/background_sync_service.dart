import 'package:workmanager/workmanager.dart';
import 'auto_sync_service.dart';
import 'package:logger/logger.dart';

const String backgroundSyncTask = 'backgroundSyncTask';

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    final logger = Logger();
    try {
      logger.i('[BackgroundSync] Starting background sync...');
      await AutoSyncService().syncNow();
      logger.i('[BackgroundSync] Sync completed');
      return Future.value(true);
    } catch (e) {
      logger.e('[BackgroundSync] Sync failed: $e');
      return Future.value(false);
    }
  });
}

class BackgroundSyncService {
  static Future<void> initialize() async {
    await Workmanager().initialize(
      callbackDispatcher,
    );
    await Workmanager().registerPeriodicTask(
      'backgroundSyncTaskId',
      backgroundSyncTask,
      frequency: const Duration(minutes: 15),
      initialDelay: const Duration(minutes: 1),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
  }
}
