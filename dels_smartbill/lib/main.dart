import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'features/shell/home_shell.dart';
import 'features/auth/auth_gate.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io';
import 'core/supabase/supabase_client.dart';
import 'services/auto_sync_service.dart';
import 'services/background_sync_service.dart';
import 'package:logger/logger.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load .env file
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    // .env file not found or error loading, continue without it
    // This allows the app to still work with --dart-define flags
  }

  // Initialize sqflite for desktop platforms (not web)
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Initialize Supabase if env vars are provided via .env or --dart-define
  await SupabaseInit.ensureInitialized();

  // Initialize background sync (only on Android/iOS, not web or desktop)
  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    await BackgroundSyncService.initialize();
  }

  runApp(const SmartBillApp());
}

class SmartBillApp extends StatefulWidget {
  const SmartBillApp({super.key});

  @override
  State<SmartBillApp> createState() => _SmartBillAppState();
}

class _SmartBillAppState extends State<SmartBillApp> with WidgetsBindingObserver {
  final Logger _logger = Logger();
  @override
  void initState() {
    super.initState();
    // Listen to app lifecycle changes
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    AutoSyncService().dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // Sync when app resumes from background
    if (state == AppLifecycleState.resumed) {
      _logger.i('[App] App resumed, triggering sync...');
      AutoSyncService().syncNow();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool enableAuthGate = const bool.fromEnvironment('ENABLE_AUTH', defaultValue: false);
    return MaterialApp(
      title: 'DELS SmartBill',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      locale: const Locale('en', 'IN'),
      supportedLocales: const [
        Locale('en', 'IN'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // ignore: dead_code
      home: enableAuthGate ? const AuthGate(child: HomeShell()) : const HomeShell(),
    );
  }
}

// Placeholder removed; using ProductsPage as initial screen.
