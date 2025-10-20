import '../db/app_database.dart';
import '../db/entities/customer_entity.dart';
import '../../services/auto_sync_service.dart';

class CustomerRepository {
  final AppDatabase db;
  CustomerRepository(this.db);

  Stream<List<CustomerEntity>> watchAll() {
    return db.customerDao.watchAll();
  }

  Future<CustomerEntity?> getById(String id) async {
    return db.customerDao.findById(id);
  }

  Future<void> add(CustomerEntity customer) async {
    await db.customerDao.insertOne(customer.copyWith(isDirty: true));
    await AutoSyncService().syncAfterMutation();
  }

  Future<void> update(CustomerEntity customer) async {
    await db.customerDao.updateOne(customer.copyWith(isDirty: true));
    await AutoSyncService().syncAfterMutation();
  }

  Future<void> delete(String id) async {
    final customer = await db.customerDao.findById(id);
    if (customer != null) {
      await db.customerDao.updateOne(customer.copyWith(isDeleted: true, isDirty: true));
      await AutoSyncService().syncAfterMutation();
    }
  }
}
