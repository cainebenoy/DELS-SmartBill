import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/design/app_colors.dart';
import 'invoice_page.dart';
import 'providers/invoices_provider.dart';

class InvoicesListPage extends ConsumerStatefulWidget {
  const InvoicesListPage({super.key});

  @override
  ConsumerState<InvoicesListPage> createState() => _InvoicesListPageState();
}

class _InvoicesListPageState extends ConsumerState<InvoicesListPage> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.primary : AppColors.backgroundLight;
    final invoicesAsync = ref.watch(invoicesProvider);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text('Invoices'),
        centerTitle: true,
        backgroundColor: (isDark
                ? AppColors.primary
                : AppColors.backgroundLight)
            .withValues(alpha: 0.8),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: invoicesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $error', style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(invoicesProvider);
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (invoicesState) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) {
                    ref.read(invoicesProvider.notifier).setSearchQuery(v);
                  },
                  decoration: InputDecoration(
                    hintText: 'Search invoices',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: isDark
                        ? AppColors.secondary.withValues(alpha: 0.2)
                        : Colors.white.withValues(alpha: 0.7),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark
                            ? AppColors.secondary.withValues(alpha: 0.3)
                            : const Color(0xFFE7E5E4),
                      ),
                    ),
                  ),
                ),
              ),
              if (invoicesState.filteredInvoices.isEmpty)
                const Expanded(
                  child: Center(
                    child: Text(
                      'No invoices found.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                    itemCount: invoicesState.filteredInvoices.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final iwd = invoicesState.filteredInvoices[index];
                      return Card(
                        color: isDark
                            ? AppColors.secondary.withValues(alpha: 0.15)
                            : Colors.white.withValues(alpha: 0.9),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: isDark ? 0 : 1,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: AppColors.accent.withValues(alpha: 0.2),
                            child: const Icon(
                              Icons.receipt_long,
                              color: AppColors.accent,
                            ),
                          ),
                          title: Text(
                            iwd.invoice.invoiceNumber,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              if (iwd.customer != null)
                                Row(
                                  children: [
                                    const Icon(Icons.person, size: 14, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(
                                      iwd.customer!.name,
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ],
                                ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(
                                    DateFormat('MMM dd, yyyy').format(iwd.invoice.createdAt),
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  const Icon(Icons.shopping_cart, size: 14, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${iwd.items.length} item(s)',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '₹${iwd.total.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: AppColors.accent,
                                ),
                              ),
                              const SizedBox(height: 4),
                              IconButton(
                                icon: const Icon(Icons.delete, size: 20),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Delete Invoice'),
                                      content: const Text('Are you sure you want to delete this invoice?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.of(ctx).pop(false),
                                          child: const Text('Cancel'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () => Navigator.of(ctx).pop(true),
                                          child: const Text('Delete'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (!mounted) return;
                                  if (confirm == true) {
                                    await ref
                                        .read(invoicesProvider.notifier)
                                        .deleteInvoice(iwd.invoice.id);
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Invoice deleted')),
                                    );
                                  }
                                },
                                color: Colors.red,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const InvoicePage()),
            );
            // Refresh the list after returning from invoice creation
            ref.invalidate(invoicesProvider);
        },
        backgroundColor: AppColors.accent,
        child: const Icon(Icons.add, color: AppColors.primary, size: 28),
      ),
    );
  }
}
