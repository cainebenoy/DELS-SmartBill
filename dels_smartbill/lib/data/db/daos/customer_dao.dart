import 'package:floor/floor.dart';
import '../entities/customer_entity.dart';

@dao
abstract class CustomerDao {
  @Query('SELECT * FROM CustomerEntity WHERE isDeleted = 0 ORDER BY name ASC')
  Stream<List<CustomerEntity>> watchAll();

  @Query('SELECT * FROM CustomerEntity WHERE isDeleted = 0 AND (name LIKE :q OR phone LIKE :q OR email LIKE :q) ORDER BY name ASC')
  Future<List<CustomerEntity>> search(String q);

  @Query('SELECT * FROM CustomerEntity WHERE id = :id LIMIT 1')
  Future<CustomerEntity?> findById(String id);

  @Query('SELECT * FROM CustomerEntity WHERE isDirty = 1')
  Future<List<CustomerEntity>> findDirty();

  @Query('SELECT COUNT(*) FROM CustomerEntity')
  Future<int?> countAll();

  @insert
  Future<void> insertAll(List<CustomerEntity> items);

  @insert
  Future<void> insertOne(CustomerEntity item);

  @update
  Future<void> updateOne(CustomerEntity item);

  @Query('UPDATE CustomerEntity SET isDeleted = 1, deletedAtMillis = :deletedAtMillis, isDirty = 1 WHERE id = :id')
  Future<void> softDelete(String id, int deletedAtMillis);
}
