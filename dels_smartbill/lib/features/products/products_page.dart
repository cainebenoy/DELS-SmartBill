import 'package:flutter/material.dart';
import '../../core/design/app_colors.dart';
import '../../core/format/currency.dart';
import '../../data/db/app_database.dart';
import '../../services/sync_service.dart';
import '../../data/db/entities/product_entity.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  final TextEditingController _searchCtrl = TextEditingController();

  AppDatabase? _db;

  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.primary : AppColors.backgroundLight;

    return FutureBuilder<AppDatabase>(
      future: _initDb(),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done || !snap.hasData) {
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
            ),
            body: snap.hasError
                ? Center(child: Text('Error: ${snap.error}'))
                : const Center(child: CircularProgressIndicator()),
          );
        }
        final db = snap.data!;
        return StreamBuilder<List<ProductEntity>>(
          stream: db.productDao.watchAll(),
          builder: (context, s) {
            final items = s.data ?? const [];
            final filtered = items
                .where((e) => e.name.toLowerCase().contains(_query.toLowerCase()) ||
                    e.category.toLowerCase().contains(_query.toLowerCase()))
                .toList();

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
              ),
              body: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Stack(
                      children: [
                        TextField(
                          controller: _searchCtrl,
                          onChanged: (v) => setState(() => _query = v),
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
                  Expanded(
                    child: filtered.isEmpty
                        ? const Center(
                            child: Text(
                              'No products found.\nTap + to add your first product.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 16),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                            itemCount: filtered.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                        final p = filtered[index];
                        return ProductTile(
                          p: ProductVM(
                            name: p.name,
                            category: p.category,
                            price: p.price,
                          ),
                          onEdit: () async {
                            final db = await _initDb();
                            if (!mounted) return;
                            if (!context.mounted) return;
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
                              await db.productDao.updateOne(
                                ProductEntity(
                                  id: p.id,
                                  name: result.name,
                                  category: result.category,
                                  price: result.price,
                                  createdAt: p.createdAt,
                                  updatedAt: DateTime.now(),
                                  deletedAtMillis: p.deletedAtMillis,
                                  isDirty: true,
                                  isDeleted: p.isDeleted,
                                ),
                              );
                              // Trigger sync after mutation
                              if (await _isOnline()) {
                                await SyncService().push(db);
                              }
                            }
                          },
                          onDelete: () async {
                            final db = await _initDb();
                            if (!mounted) return;
                            if (!context.mounted) return;
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
                              await db.productDao.updateOne(
                                ProductEntity(
                                  id: p.id,
                                  name: p.name,
                                  category: p.category,
                                  price: p.price,
                                  createdAt: p.createdAt,
                                  updatedAt: DateTime.now(),
                                  deletedAtMillis: DateTime.now().millisecondsSinceEpoch,
                                  isDirty: true,
                                  isDeleted: true,
                                ),
                              );
                              // Trigger sync after mutation
                              if (await _isOnline()) {
                                await SyncService().push(db);
                              }
                            }
                          },
                        );
                      },
                    ),
                  )
                ],
              ),
              floatingActionButton: FloatingActionButton(
                onPressed: () async {
                  final db = await _initDb();
                  if (!mounted) return;
                  if (!context.mounted) return;
                  final result = await showDialog<ProductDialogResult>(
                    context: context,
                    builder: (ctx) => ProductDialog(),
                  );
                  if (!mounted) return;
                  if (result != null) {
                    final now = DateTime.now();
                    await db.productDao.insertOne(
                      ProductEntity(
                        id: UniqueKey().toString(),
                        name: result.name,
                        category: result.category,
                        price: result.price,
                        createdAt: now,
                        updatedAt: now,
                        isDirty: true,
                        isDeleted: false,
                      ),
                    );
                    // Trigger sync after mutation
                    if (await _isOnline()) {
                      await SyncService().push(db);
                    }
                  }
                },
                backgroundColor: AppColors.accent,
                child: const Icon(Icons.add, color: AppColors.primary, size: 28),
              ),

            );
          },
        );
      },
    );
  }

  Future<AppDatabase> _initDb() async {
    if (_db != null) return _db!;
    _db = await openAppDatabase();
    return _db!;
  }

  Future<bool> _isOnline() async {
  // For now, always return true
  return true;
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
  final ProductVM p;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ProductTile({
    super.key,
    required this.p,
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
                  p.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  p.category,
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
              CurrencyFormatter.format(p.price),
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

// Currency formatter replaced by CurrencyFormatter (INR)

class ProductVM {
  final String name;
  final String category;
  final double price;
  const ProductVM({required this.name, required this.category, required this.price});
}
