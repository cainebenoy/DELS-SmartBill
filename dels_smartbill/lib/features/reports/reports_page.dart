import 'package:flutter/material.dart';
import '../../core/design/app_colors.dart';

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.primary : AppColors.backgroundLight,
      appBar: AppBar(title: const Text('Reports'), centerTitle: true),
      body: const Center(child: Text('Reports placeholder')),
    );
  }
}
