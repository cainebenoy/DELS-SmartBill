import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/design/app_colors.dart';
import '../../core/format/currency.dart';
import '../../data/db/entities/product_entity.dart';
import 'providers/products_provider.dart';

class ProductsPage extends ConsumerStatefulWidget {
  const ProductsPage({super.key});

  @override
  ConsumerState<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends ConsumerState<ProductsPage> with WidgetsBindingObserver {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Listen to app lifecycle changes
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // Refresh products when app resumes (after sync completes)
    if (state == AppLifecycleState.resumed) {
      // Give sync a moment to complete, then refresh
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          ref.invalidate(productsProvider);
        }
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.primary : AppColors.backgroundLight;
    final productsAsync = ref.watch(productsProvider);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text('Products'),
        centerTitle: true,
        backgroundColor: (isDark
                ? AppColors.primary
                : AppColors.backgroundLight)
            .withValues(alpha: 0.8),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(productsProvider);
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $error', style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(productsProvider);
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (productsState) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Stack(
                  children: [
                    TextField(
                      controller: _searchCtrl,
                      onChanged: (v) {
                        ref.read(productsProvider.notifier).setSearchQuery(v);
                      },
                      decoration: InputDecoration(
                        hintText: 'Search products',
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
                  ],
                ),
              ),
              if (productsState.filteredProducts.isEmpty)
                const Expanded(
                  child: Center(
                    child: Text(
                      'No products found.\nTap + to add your first product.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                )
              else
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(productsProvider);
                      // Wait for the provider to rebuild
                      await ref.read(productsProvider.future);
                    },
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                      itemCount: productsState.filteredProducts.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                      final p = productsState.filteredProducts[index];
                      return ProductTile(
                        product: p,
                        onEdit: () async {
                          final result = await showDialog<ProductDialogResult>(
                            context: context,
                            builder: (ctx) => ProductDialog(
                              initial: ProductDialogResult(
                                name: p.name,
                                category: p.category,
                                price: p.price,
                              ),
                            ),
                          );
                          if (!mounted) return;
                          if (result != null) {
                            await ref.read(productsProvider.notifier).updateProduct(
                              p.copyWith(
                                name: result.name,
                                category: result.category,
                                price: result.price,
                              ),
                            );
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Product updated')),
                            );
                          }
                        },
                        onDelete: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Delete Product'),
                              content: const Text('Are you sure you want to delete this product?'),
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
                            await ref.read(productsProvider.notifier).deleteProduct(p.id);
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Product deleted'),
                                action: SnackBarAction(
                                  label: 'Undo',
                                  onPressed: () {
                                    ref.read(productsProvider.notifier).restoreProduct(p.id);
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
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await showDialog<ProductDialogResult>(
            context: context,
            builder: (ctx) => const ProductDialog(),
          );
          if (!mounted) return;
          if (result != null) {
            try {
              await ref.read(productsProvider.notifier).addProduct(
                name: result.name,
                category: result.category,
                price: result.price,
              );
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Product added')),
              );
            } catch (e) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to add product: $e')),
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

// Dialog result model
class ProductDialogResult {
  final String name;
  final String category;
  final double price;
  ProductDialogResult({required this.name, required this.category, required this.price});
}

// Product Add/Edit dialog
class ProductDialog extends StatefulWidget {
  final ProductDialogResult? initial;
  const ProductDialog({this.initial, super.key});

  @override
  State<ProductDialog> createState() => _ProductDialogState();
}

class _ProductDialogState extends State<ProductDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _categoryCtrl;
  late TextEditingController _priceCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initial?.name ?? '');
    _categoryCtrl = TextEditingController(text: widget.initial?.category ?? '');
    _priceCtrl = TextEditingController(text: widget.initial?.price != null ? widget.initial!.price.toString() : '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _categoryCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initial == null ? 'Add Product' : 'Edit Product'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (v) => v == null || v.trim().isEmpty ? 'Name required' : null,
            ),
            TextFormField(
              controller: _categoryCtrl,
              decoration: const InputDecoration(labelText: 'Category'),
              validator: (v) => v == null || v.trim().isEmpty ? 'Category required' : null,
            ),
            TextFormField(
              controller: _priceCtrl,
              decoration: const InputDecoration(labelText: 'Price'),
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Price required';
                final val = double.tryParse(v);
                if (val == null || val < 0) return 'Enter a valid price';
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              Navigator.of(context).pop(ProductDialogResult(
                name: _nameCtrl.text.trim(),
                category: _categoryCtrl.text.trim(),
                price: double.parse(_priceCtrl.text.trim()),
              ));
            }
          },
          child: Text(widget.initial == null ? 'Add' : 'Save'),
        ),
      ],
    );
  }
}

class ProductTile extends StatelessWidget {
  final ProductEntity product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ProductTile({
    super.key,
    required this.product,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
  color: isDark ? AppColors.secondary.withValues(alpha: 0.2) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  product.category,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.accent : AppColors.secondary,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Text(
              CurrencyFormatter.format(product.price),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppColors.primary,
              ),
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: onEdit,
                icon: Icon(Icons.edit,
                    color: isDark ? AppColors.accent : AppColors.secondary),
              ),
              IconButton(
                onPressed: onDelete,
                icon: Icon(Icons.delete,
                    color: isDark ? AppColors.accent : AppColors.secondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
