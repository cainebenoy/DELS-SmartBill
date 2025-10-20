import 'package:flutter/material.dart';
import '../../core/design/app_colors.dart';
import '../../core/format/currency.dart';
import '../../data/db/app_database.dart';
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
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                      itemCount: filtered.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final p = filtered[index];
                        return _ProductTile(
                          p: _ProductVM(
                            name: p.name,
                            category: p.category,
                            price: p.price,
                          ),
                        );
                      },
                    ),
                  )
                ],
              ),
              floatingActionButton: FloatingActionButton(
                onPressed: () {},
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
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({required this.p});
  final _ProductVM p;

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
                onPressed: () {},
                icon: Icon(Icons.edit,
                    color: isDark ? AppColors.accent : AppColors.secondary),
              ),
              IconButton(
                onPressed: () {},
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

class _ProductVM {
  final String name;
  final String category;
  final double price;
  const _ProductVM({required this.name, required this.category, required this.price});
}
