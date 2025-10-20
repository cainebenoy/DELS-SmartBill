import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/db/app_database.dart';
import '../../../data/db/entities/product_entity.dart';
import '../../../services/auto_sync_service.dart';
import 'package:uuid/uuid.dart';
import 'package:logger/logger.dart';

final Logger _logger = Logger();

// State class for products
class ProductsState {
  final List<ProductEntity> products;
  final bool isLoading;
  final String? error;
  final String searchQuery;

  const ProductsState({
    this.products = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
  });

  ProductsState copyWith({
    List<ProductEntity>? products,
    bool? isLoading,
    String? error,
    String? searchQuery,
  }) {
    return ProductsState(
      products: products ?? this.products,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  // Filtered products based on search query
  List<ProductEntity> get filteredProducts {
    if (searchQuery.isEmpty) return products;
    final query = searchQuery.toLowerCase();
    return products.where((p) =>
      p.name.toLowerCase().contains(query) ||
      p.category.toLowerCase().contains(query)
    ).toList();
  }
}

// Notifier for products
class ProductsNotifier extends AsyncNotifier<ProductsState> {
  @override
  Future<ProductsState> build() async {
    await _loadProducts();
    return state.requireValue;
  }

  Future<void> _loadProducts() async {
    state = const AsyncValue.loading();
    try {
      final db = await openAppDatabase();
      // Use '%' as wildcard to get all products
      final products = await db.productDao.search('%');
      state = AsyncValue.data(ProductsState(
        products: products,
        isLoading: false,
      ));
      _logger.i('[ProductsProvider] Loaded ${products.length} products');
    } catch (e, stack) {
      _logger.e('[ProductsProvider] Failed to load products: $e');
      state = AsyncValue.error(e, stack);
    }
  }

  void setSearchQuery(String query) {
    state.whenData((currentState) {
      state = AsyncValue.data(currentState.copyWith(searchQuery: query));
    });
  }

  Future<void> addProduct({
    required String name,
    required String category,
    required double price,
  }) async {
    try {
      final db = await openAppDatabase();
      const uuid = Uuid();
      final now = DateTime.now();
      
      final product = ProductEntity(
        id: uuid.v4(),
        name: name,
        category: category,
        price: price,
        createdAt: now,
        updatedAt: now,
        isDirty: true,
        isDeleted: false,
      );

      await db.productDao.insertOne(product);
      _logger.i('[ProductsProvider] Added product: $name');
      
      // Reload products
      await _loadProducts();
      
      // Trigger sync
      AutoSyncService().syncAfterMutation();
    } catch (e) {
      _logger.e('[ProductsProvider] Failed to add product: $e');
      rethrow;
    }
  }

  Future<void> updateProduct(ProductEntity product) async {
    try {
      final db = await openAppDatabase();
      final updated = product.copyWith(
        updatedAt: DateTime.now(),
        isDirty: true,
      );
      
      await db.productDao.updateOne(updated);
      _logger.i('[ProductsProvider] Updated product: ${product.name}');
      
      // Reload products
      await _loadProducts();
      
      // Trigger sync
      AutoSyncService().syncAfterMutation();
    } catch (e) {
      _logger.e('[ProductsProvider] Failed to update product: $e');
      rethrow;
    }
  }

  Future<void> deleteProduct(String id) async {
    try {
      final db = await openAppDatabase();
      final product = await db.productDao.findById(id);
      
      if (product != null) {
        final deleted = product.copyWith(
          isDeleted: true,
          isDirty: true,
          updatedAt: DateTime.now(),
        );
        
        await db.productDao.updateOne(deleted);
        _logger.i('[ProductsProvider] Soft-deleted product: ${product.name}');
        
        // Reload products
        await _loadProducts();
        
        // Trigger sync
        AutoSyncService().syncAfterMutation();
      }
    } catch (e) {
      _logger.e('[ProductsProvider] Failed to delete product: $e');
      rethrow;
    }
  }

  Future<void> restoreProduct(String id) async {
    try {
      final db = await openAppDatabase();
      // Search for deleted products
      final product = await db.productDao.findById(id);
      
      if (product != null) {
        final restored = product.copyWith(
          isDeleted: false,
          isDirty: true,
          updatedAt: DateTime.now(),
        );
        
        await db.productDao.updateOne(restored);
        _logger.i('[ProductsProvider] Restored product: ${product.name}');
        
        // Reload products
        await _loadProducts();
        
        // Trigger sync
        AutoSyncService().syncAfterMutation();
      }
    } catch (e) {
      _logger.e('[ProductsProvider] Failed to restore product: $e');
      rethrow;
    }
  }
}

// Provider for products
final productsProvider = AsyncNotifierProvider<ProductsNotifier, ProductsState>(() {
  return ProductsNotifier();
});
