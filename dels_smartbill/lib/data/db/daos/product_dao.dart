import 'package:floor/floor.dart';
import '../entities/product_entity.dart';

@dao
abstract class ProductDao {
  @Query('SELECT * FROM ProductEntity WHERE isDeleted = 0 ORDER BY name ASC')
  Stream<List<ProductEntity>> watchAll();

  @Query('SELECT * FROM ProductEntity WHERE isDeleted = 0 AND (name LIKE :q OR category LIKE :q) ORDER BY name ASC')
  Future<List<ProductEntity>> search(String q);

  @Query('SELECT * FROM ProductEntity WHERE isDirty = 1')
  Future<List<ProductEntity>> findDirty();

  @Query('SELECT COUNT(*) FROM ProductEntity')
  Future<int?> countAll();

  @insert
  Future<void> insertAll(List<ProductEntity> items);

  @insert
  Future<void> insertOne(ProductEntity item);

  @update
  Future<void> updateOne(ProductEntity item);

  @Query('UPDATE ProductEntity SET isDeleted = 1, deletedAtMillis = :deletedAtMillis, isDirty = 1 WHERE id = :id')
  Future<void> softDelete(String id, int deletedAtMillis);
}
