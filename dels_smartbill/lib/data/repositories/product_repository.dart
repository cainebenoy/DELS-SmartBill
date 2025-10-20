import '../db/app_database.dart';
import '../db/entities/product_entity.dart';
import '../../services/auto_sync_service.dart';

class ProductRepository {
  final AppDatabase db;
  ProductRepository(this.db);

  Stream<List<ProductEntity>> watchAll() {
    return db.productDao.watchAll();
  }

  Future<ProductEntity?> getById(String id) async {
    return db.productDao.findById(id);
  }

  Future<void> add(ProductEntity product) async {
    await db.productDao.insertOne(product.copyWith(isDirty: true));
    await AutoSyncService().syncAfterMutation();
  }

  Future<void> update(ProductEntity product) async {
    await db.productDao.updateOne(product.copyWith(isDirty: true));
    await AutoSyncService().syncAfterMutation();
  }

  Future<void> delete(String id) async {
    final product = await db.productDao.findById(id);
    if (product != null) {
      await db.productDao.updateOne(product.copyWith(isDeleted: true, isDirty: true));
      await AutoSyncService().syncAfterMutation();
    }
  }
}
