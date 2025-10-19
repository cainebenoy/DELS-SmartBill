import 'package:flutter/material.dart';
import '../../core/design/app_colors.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.primary : AppColors.backgroundLight,
      appBar: AppBar(title: const Text('Settings'), centerTitle: true),
      body: const Center(child: Text('Settings placeholder')),
    );
  }
}
