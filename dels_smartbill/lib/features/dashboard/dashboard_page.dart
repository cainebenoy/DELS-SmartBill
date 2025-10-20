import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../data/db/app_database.dart';
import '../../data/db/entities/invoice_entity.dart';


class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  double todaySales = 0;
  int todayInvoices = 0;
  double yesterdaySales = 0;
  int yesterdayInvoices = 0;
  List<InvoiceEntity> recentInvoices = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadMetrics();
  }

  Future<void> _loadMetrics() async {
    try {
      final db = await openAppDatabase();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      // Use '%' pattern to fetch all invoices
      final allInvoices = await db.invoiceDao.search('%');
      todaySales = allInvoices
          .where((i) => i.createdAt.isAfter(today))
          .fold(0.0, (sum, i) => sum + i.totalAmount);
      todayInvoices = allInvoices.where((i) => i.createdAt.isAfter(today)).length;
      yesterdaySales = allInvoices
          .where((i) => i.createdAt.isAfter(yesterday) && i.createdAt.isBefore(today))
          .fold(0.0, (sum, i) => sum + i.totalAmount);
      yesterdayInvoices = allInvoices
          .where((i) => i.createdAt.isAfter(yesterday) && i.createdAt.isBefore(today))
          .length;
      recentInvoices = allInvoices.take(10).toList();
    } catch (e) {
      if (kIsWeb) {
        error = 'Database not available on web. Please use Android/iOS/Desktop app.';
      } else {
        error = 'Failed to load metrics: $e';
      }
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.info_outline, size: 64, color: Colors.orange),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          error!,
                          style: Theme.of(context).textTheme.bodyLarge,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      if (!kIsWeb) ...[
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              loading = true;
                              error = null;
                            });
                            _loadMetrics();
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ],
                  ),
                )
              : recentInvoices.isEmpty
                  ? const Center(
                      child: Text(
                        'No invoices yet.\nCreate your first invoice to see metrics.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Today\'s Sales: ₹${todaySales.toStringAsFixed(2)}', style: Theme.of(context).textTheme.titleLarge),
                          Text('Today\'s Invoices: $todayInvoices'),
                          Text('Yesterday\'s Sales: ₹${yesterdaySales.toStringAsFixed(2)}'),
                          Text('Yesterday\'s Invoices: $yesterdayInvoices'),
                          const SizedBox(height: 24),
                          Text('Recent Invoices', style: Theme.of(context).textTheme.titleMedium),
                          ...recentInvoices.map((i) => ListTile(
                                title: Text(i.invoiceNumber),
                                subtitle: Text('₹${i.totalAmount.toStringAsFixed(2)}'),
                                trailing: Text('${i.createdAt.toLocal()}'),
                              )),
                        ],
                      ),
                    ),
    );
  }
}
