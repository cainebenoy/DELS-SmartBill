import 'package:flutter/material.dart';
import '../../core/design/app_colors.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.primary : AppColors.backgroundLight,
      appBar: AppBar(title: const Text('Dashboard'), centerTitle: true),
      body: const Center(child: Text('Dashboard placeholder')),
    );
  }
}
