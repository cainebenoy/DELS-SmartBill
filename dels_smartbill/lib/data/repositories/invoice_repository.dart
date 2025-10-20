import '../db/app_database.dart';
import '../db/entities/invoice_entity.dart';
import '../../services/auto_sync_service.dart';

class InvoiceRepository {
  final AppDatabase db;
  InvoiceRepository(this.db);

  Stream<List<InvoiceEntity>> watchAll() {
    return db.invoiceDao.watchAll();
  }

  Future<InvoiceEntity?> getById(String id) async {
    return db.invoiceDao.findById(id);
  }

  Future<void> add(InvoiceEntity invoice) async {
    await db.invoiceDao.insertOne(invoice.copyWith(isDirty: true));
    await AutoSyncService().syncAfterMutation();
  }

  Future<void> update(InvoiceEntity invoice) async {
    await db.invoiceDao.updateOne(invoice.copyWith(isDirty: true));
    await AutoSyncService().syncAfterMutation();
  }

  Future<void> delete(String id) async {
    final invoice = await db.invoiceDao.findById(id);
    if (invoice != null) {
      await db.invoiceDao.updateOne(invoice.copyWith(isDeleted: true, isDirty: true));
      await AutoSyncService().syncAfterMutation();
    }
  }
}
