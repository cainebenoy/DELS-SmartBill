import 'package:flutter/material.dart';
import 'features/shell/home_shell.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  runApp(const SmartBillApp());
}

class SmartBillApp extends StatelessWidget {
  const SmartBillApp({super.key});

  @override
  Widget build(BuildContext context) {
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
      home: const HomeShell(),
    );
  }
}

// Placeholder removed; using ProductsPage as initial screen.
