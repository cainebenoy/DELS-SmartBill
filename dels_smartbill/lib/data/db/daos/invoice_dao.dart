import 'package:floor/floor.dart';
import '../entities/invoice_entity.dart';

@dao
abstract class InvoiceDao {
  @Query('SELECT * FROM InvoiceEntity WHERE isDeleted = 0 ORDER BY createdAt DESC')
  Stream<List<InvoiceEntity>> watchAll();

  @Query('SELECT * FROM InvoiceEntity WHERE isDeleted = 0 AND (invoiceNumber LIKE :q) ORDER BY createdAt DESC')
  Future<List<InvoiceEntity>> search(String q);

  @Query('SELECT * FROM InvoiceEntity WHERE isDirty = 1')
  Future<List<InvoiceEntity>> findDirty();

  @Query('SELECT COUNT(*) FROM InvoiceEntity')
  Future<int?> countAll();

  @insert
  Future<void> insertAll(List<InvoiceEntity> items);

  @insert
  Future<void> insertOne(InvoiceEntity item);

  @update
  Future<void> updateOne(InvoiceEntity item);

  @Query('UPDATE InvoiceEntity SET isDeleted = 1, deletedAtMillis = :deletedAtMillis, isDirty = 1 WHERE id = :id')
  Future<void> softDelete(String id, int deletedAtMillis);
}

@dao
abstract class InvoiceItemDao {
  @Query('SELECT * FROM InvoiceItemEntity WHERE isDeleted = 0 AND invoiceId = :invoiceId ORDER BY createdAt ASC')
  Stream<List<InvoiceItemEntity>> watchByInvoice(String invoiceId);

  @Query('SELECT * FROM InvoiceItemEntity WHERE isDeleted = 0 AND invoiceId = :invoiceId ORDER BY createdAt ASC')
  Future<List<InvoiceItemEntity>> byInvoice(String invoiceId);

  @Query('SELECT * FROM InvoiceItemEntity WHERE isDeleted = 0 ORDER BY createdAt ASC')
  Future<List<InvoiceItemEntity>> getAll();

  @Query('SELECT * FROM InvoiceItemEntity WHERE isDirty = 1')
  Future<List<InvoiceItemEntity>> findDirty();

  @insert
  Future<void> insertAll(List<InvoiceItemEntity> items);

  @insert
  Future<void> insertOne(InvoiceItemEntity item);

  @update
  Future<void> updateOne(InvoiceItemEntity item);

  @Query('UPDATE InvoiceItemEntity SET isDeleted = 1, deletedAtMillis = :deletedAtMillis, isDirty = 1 WHERE id = :id')
  Future<void> softDelete(String id, int deletedAtMillis);
}
