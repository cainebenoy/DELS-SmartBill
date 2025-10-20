import 'package:flutter/material.dart';
import '../../data/db/app_database.dart';
import '../../data/db/entities/product_entity.dart';
import '../../data/db/entities/invoice_entity.dart';


class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  DateTimeRange? range;
  double totalSales = 0;
  int totalInvoices = 0;
  String bestProduct = '';
  List<InvoiceEntity> filteredInvoices = [];
  bool loading = false;
  String? error;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    range = DateTimeRange(
      start: DateTime(now.year, now.month, 1),
      end: now,
    );
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final db = await openAppDatabase();
      // Use '%' pattern to fetch all invoices
      final invoices = await db.invoiceDao.search('%');
      filteredInvoices = invoices.where((i) =>
        i.createdAt.isAfter(range!.start.subtract(const Duration(days: 1))) &&
        i.createdAt.isBefore(range!.end.add(const Duration(days: 1)))
      ).toList();
      totalSales = filteredInvoices.fold(0.0, (sum, i) => sum + i.totalAmount);
      totalInvoices = filteredInvoices.length;
      
      // Best selling product
      final items = <InvoiceItemEntity>[];
      for (final inv in filteredInvoices) {
        final invItemsList = await db.invoiceItemDao.byInvoice(inv.id);
        items.addAll(invItemsList);
      }
      final productSales = <String, int>{};
      for (final item in items) {
        productSales[item.productId] = (productSales[item.productId] ?? 0) + item.quantity;
      }
      if (productSales.isNotEmpty) {
        final bestId = productSales.entries.reduce((a, b) => a.value > b.value ? a : b).key;
        final products = await db.productDao.search('%');
        final bestProductEntity = products.firstWhere(
          (p) => p.id == bestId,
          orElse: () => ProductEntity(
            id: '', name: 'Unknown', category: '', price: 0, 
            createdAt: DateTime(2000), updatedAt: DateTime(2000),
          ),
        );
        bestProduct = bestProductEntity.name;
      } else {
        bestProduct = 'N/A';
      }
    } catch (e) {
      error = 'Failed to load report: $e';
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }  Future<void> _pickRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: range,
    );
    if (picked != null) {
      setState(() => range = picked);
      await _loadReport();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadReport,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('From: ${range!.start.toLocal().toString().split(' ')[0]}'),
                          const SizedBox(width: 8),
                          Text('To: ${range!.end.toLocal().toString().split(' ')[0]}'),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _pickRange,
                            child: const Text('Pick Range'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Card(
                        child: ListTile(
                          title: const Text('Total Sales'),
                          trailing: Text('₹${totalSales.toStringAsFixed(2)}'),
                        ),
                      ),
                      Card(
                        child: ListTile(
                          title: const Text('Total Invoices'),
                          trailing: Text('$totalInvoices'),
                        ),
                      ),
                      Card(
                        child: ListTile(
                          title: const Text('Best Selling Product'),
                          trailing: Text(bestProduct),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text('Historical Invoices', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Expanded(
                        child: filteredInvoices.isEmpty
                            ? const Center(
                                child: Text(
                                  'No invoices in selected date range',
                                  style: TextStyle(fontSize: 16),
                                ),
                              )
                            : ListView.builder(
                                itemCount: filteredInvoices.length,
                                itemBuilder: (context, idx) {
                                  final inv = filteredInvoices[idx];
                                  return ListTile(
                                    title: Text(inv.invoiceNumber),
                                    subtitle: Text('₹${inv.totalAmount.toStringAsFixed(2)}'),
                                    trailing: Text('${inv.createdAt.toLocal()}'.split('.')[0]),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
