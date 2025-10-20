import 'package:flutter/material.dart';
import 'features/shell/home_shell.dart';
import 'features/auth/auth_gate.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io';
import 'core/supabase/supabase_client.dart';
import 'services/auto_sync_service.dart';
import 'package:logger/logger.dart';

Future<void> main() async {
  // Initialize sqflite for desktop platforms
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Supabase if env vars are provided via --dart-define
  await SupabaseInit.ensureInitialized();
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
