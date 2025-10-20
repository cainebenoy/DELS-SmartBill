import 'package:flutter/material.dart';
import 'features/shell/home_shell.dart';
import 'features/auth/auth_gate.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io';
import 'core/supabase/supabase_client.dart';

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

class SmartBillApp extends StatelessWidget {
  const SmartBillApp({super.key});

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
