import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/design/app_colors.dart';
import 'providers/customers_provider.dart';
import 'widgets/customer_dialog.dart';
import 'widgets/customer_tile.dart';

class CustomersPage extends ConsumerStatefulWidget {
  const CustomersPage({super.key});

  @override
  ConsumerState<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends ConsumerState<CustomersPage> {
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
    final customersAsync = ref.watch(customersProvider);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text('Customers'),
        centerTitle: true,
        backgroundColor: (isDark
                ? AppColors.primary
                : AppColors.backgroundLight)
            .withValues(alpha: 0.8),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: customersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $error', style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(customersProvider);
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (customersState) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) {
                    ref.read(customersProvider.notifier).setSearchQuery(v);
                  },
                  decoration: InputDecoration(
                    hintText: 'Search customers',
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
              if (customersState.filteredCustomers.isEmpty)
                const Expanded(
                  child: Center(
                    child: Text(
                      'No customers found.\nTap + to add your first customer.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                    itemCount: customersState.filteredCustomers.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final c = customersState.filteredCustomers[index];
                      return CustomerTile(
                        customer: c,
                        onEdit: () async {
                          final result = await showDialog<CustomerDialogResult>(
                            context: context,
                            builder: (ctx) => CustomerDialog(
                              initial: CustomerDialogResult(
                                name: c.name,
                                phone: c.phone,
                                email: c.email,
                                address: c.address,
                              ),
                            ),
                          );
                          if (!mounted) return;
                          if (result != null) {
                            await ref.read(customersProvider.notifier).updateCustomer(
                              c.copyWith(
                                name: result.name,
                                phone: result.phone,
                                email: result.email,
                                address: result.address,
                              ),
                            );
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Customer updated')),
                            );
                          }
                        },
                        onDelete: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Delete Customer'),
                              content: const Text('Are you sure you want to delete this customer?'),
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
                            await ref.read(customersProvider.notifier).deleteCustomer(c.id);
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Customer deleted'),
                                action: SnackBarAction(
                                  label: 'Undo',
                                  onPressed: () {
                                    ref.read(customersProvider.notifier).restoreCustomer(c.id);
                                  },
                                ),
                              ),
                            );
                          }
                        },
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
          final result = await showDialog<CustomerDialogResult>(
            context: context,
            builder: (ctx) => const CustomerDialog(),
          );
          if (!mounted) return;
          if (result != null) {
            try {
              await ref.read(customersProvider.notifier).addCustomer(
                name: result.name,
                phone: result.phone,
                email: result.email,
                address: result.address,
              );
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Customer added')),
              );
            } catch (e) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to add customer: $e')),
              );
            }
          }
        },
        backgroundColor: AppColors.accent,
        child: const Icon(Icons.add, color: AppColors.primary, size: 28),
      ),
    );
  }
}
