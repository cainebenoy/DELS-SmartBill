import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/db/app_database.dart';
import '../data/db/entities/product_entity.dart';
import '../data/db/entities/customer_entity.dart';
import '../data/db/entities/invoice_entity.dart';

class SyncService {
  static const _lastSyncKey = 'last_sync_at';

  /// Push dirty (locally modified) records to Supabase
  Future<void> push(AppDatabase db) async {
    try {
      // Check if Supabase is initialized by trying to access the client
      SupabaseClient? supabase;
      try {
        supabase = Supabase.instance.client;
      } catch (e) {
        print('[SyncService] Supabase not initialized, skipping push');
        return;
      }

      print('[SyncService] Starting push sync...');

      // 1. Push Products
      await _pushProducts(db, supabase);

      // 2. Push Customers
      await _pushCustomers(db, supabase);

      // 3. Push Invoices
      await _pushInvoices(db, supabase);

      // 4. Push Invoice Items
      await _pushInvoiceItems(db, supabase);

      print('[SyncService] Push sync completed successfully');
    } catch (e, stackTrace) {
      print('[SyncService] Push sync failed: $e');
      print('[SyncService] Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> _pushProducts(AppDatabase db, SupabaseClient supabase) async {
    final dirtyProducts = await db.productDao.findDirty();
    if (dirtyProducts.isEmpty) {
      print('[SyncService] No dirty products to push');
      return;
    }

    print('[SyncService] Pushing ${dirtyProducts.length} products...');

    for (final product in dirtyProducts) {
      try {
        if (product.isDeleted) {
          // Soft delete in Supabase
          await supabase.from('products').update({
            'deleted_at': product.deletedAtMillis != null
                ? DateTime.fromMillisecondsSinceEpoch(product.deletedAtMillis!).toIso8601String()
                : DateTime.now().toIso8601String(),
            'updated_at': product.updatedAt.toIso8601String(),
          }).eq('id', product.id);
        } else {
          // Upsert product to Supabase
          await supabase.from('products').upsert({
            'id': product.id,
            'name': product.name,
            'category': product.category,
            'price': product.price,
            'created_at': product.createdAt.toIso8601String(),
            'updated_at': product.updatedAt.toIso8601String(),
            'deleted_at': null,
          });
        }

        // Clear isDirty flag
        await db.productDao.updateOne(ProductEntity(
          id: product.id,
          name: product.name,
          category: product.category,
          price: product.price,
          createdAt: product.createdAt,
          updatedAt: product.updatedAt,
          deletedAtMillis: product.deletedAtMillis,
          isDirty: false,
          isDeleted: product.isDeleted,
        ));

        print('[SyncService] Pushed product: ${product.name}');
      } catch (e) {
        print('[SyncService] Failed to push product ${product.name}: $e');
        // Continue with other products
      }
    }
  }

  Future<void> _pushCustomers(AppDatabase db, SupabaseClient supabase) async {
    final dirtyCustomers = await db.customerDao.findDirty();
    if (dirtyCustomers.isEmpty) {
      print('[SyncService] No dirty customers to push');
      return;
    }

    print('[SyncService] Pushing ${dirtyCustomers.length} customers...');

    for (final customer in dirtyCustomers) {
      try {
        if (customer.isDeleted) {
          // Soft delete in Supabase
          await supabase.from('customers').update({
            'deleted_at': customer.deletedAtMillis != null
                ? DateTime.fromMillisecondsSinceEpoch(customer.deletedAtMillis!).toIso8601String()
                : DateTime.now().toIso8601String(),
            'updated_at': customer.updatedAt.toIso8601String(),
          }).eq('id', customer.id);
        } else {
          // Upsert customer to Supabase
          await supabase.from('customers').upsert({
            'id': customer.id,
            'name': customer.name,
            'created_at': customer.createdAt.toIso8601String(),
            'updated_at': customer.updatedAt.toIso8601String(),
            'deleted_at': null,
          });
        }

        // Clear isDirty flag
        await db.customerDao.updateOne(CustomerEntity(
          id: customer.id,
          name: customer.name,
          phone: customer.phone,
          email: customer.email,
          address: customer.address,
          createdAt: customer.createdAt,
          updatedAt: customer.updatedAt,
          deletedAtMillis: customer.deletedAtMillis,
          isDirty: false,
          isDeleted: customer.isDeleted,
        ));

        print('[SyncService] Pushed customer: ${customer.name}');
      } catch (e) {
        print('[SyncService] Failed to push customer ${customer.name}: $e');
        // Continue with other customers
      }
    }
  }

  Future<void> _pushInvoices(AppDatabase db, SupabaseClient supabase) async {
    final dirtyInvoices = await db.invoiceDao.findDirty();
    if (dirtyInvoices.isEmpty) {
      print('[SyncService] No dirty invoices to push');
      return;
    }

    print('[SyncService] Pushing ${dirtyInvoices.length} invoices...');

    for (final invoice in dirtyInvoices) {
      try {
        if (invoice.isDeleted) {
          // Soft delete in Supabase
          await supabase.from('invoices').update({
            'deleted_at': invoice.deletedAtMillis != null
                ? DateTime.fromMillisecondsSinceEpoch(invoice.deletedAtMillis!).toIso8601String()
                : DateTime.now().toIso8601String(),
            'updated_at': invoice.updatedAt.toIso8601String(),
          }).eq('id', invoice.id);
        } else {
          // Upsert invoice to Supabase
          final response = await supabase.from('invoices').upsert({
            'id': invoice.id,
            'invoice_number': invoice.invoiceNumber,
            'customer_id': invoice.customerId,
            'total_amount': invoice.totalAmount,
            'created_by_user_id': invoice.createdByUserId,
            'created_at': invoice.createdAt.toIso8601String(),
            'updated_at': invoice.updatedAt.toIso8601String(),
            'deleted_at': null,
          }).select().single();

          // Update local invoice with server-generated invoice_number if changed
          final serverInvoiceNumber = response['invoice_number'] as String?;
          if (serverInvoiceNumber != null && serverInvoiceNumber != invoice.invoiceNumber) {
            print('[SyncService] Invoice number updated: ${invoice.invoiceNumber} -> $serverInvoiceNumber');
          }
        }

        // Clear isDirty flag
        await db.invoiceDao.updateOne(InvoiceEntity(
          id: invoice.id,
          invoiceNumber: invoice.invoiceNumber,
          customerId: invoice.customerId,
          totalAmount: invoice.totalAmount,
          createdByUserId: invoice.createdByUserId,
          createdAt: invoice.createdAt,
          updatedAt: invoice.updatedAt,
          deletedAtMillis: invoice.deletedAtMillis,
          isDirty: false,
          isDeleted: invoice.isDeleted,
        ));

        print('[SyncService] Pushed invoice: ${invoice.invoiceNumber}');
      } catch (e) {
        print('[SyncService] Failed to push invoice ${invoice.invoiceNumber}: $e');
        // Continue with other invoices
      }
    }
  }

  Future<void> _pushInvoiceItems(AppDatabase db, SupabaseClient supabase) async {
    final dirtyItems = await db.invoiceItemDao.findDirty();
    if (dirtyItems.isEmpty) {
      print('[SyncService] No dirty invoice items to push');
      return;
    }

    print('[SyncService] Pushing ${dirtyItems.length} invoice items...');

    for (final item in dirtyItems) {
      try {
        if (item.isDeleted) {
          // Soft delete in Supabase
          await supabase.from('invoice_items').update({
            'deleted_at': item.deletedAtMillis != null
                ? DateTime.fromMillisecondsSinceEpoch(item.deletedAtMillis!).toIso8601String()
                : DateTime.now().toIso8601String(),
            'updated_at': item.updatedAt.toIso8601String(),
          }).eq('id', item.id);
        } else {
          // Upsert invoice item to Supabase
          await supabase.from('invoice_items').upsert({
            'id': item.id,
            'invoice_id': item.invoiceId,
            'product_id': item.productId,
            'quantity': item.quantity,
            'unit_price': item.unitPrice,
            'created_at': item.createdAt.toIso8601String(),
            'updated_at': item.updatedAt.toIso8601String(),
            'deleted_at': null,
          });
        }

        // Clear isDirty flag
        await db.invoiceItemDao.updateOne(InvoiceItemEntity(
          id: item.id,
          invoiceId: item.invoiceId,
          productId: item.productId,
          quantity: item.quantity,
          unitPrice: item.unitPrice,
          createdAt: item.createdAt,
          updatedAt: item.updatedAt,
          deletedAtMillis: item.deletedAtMillis,
          isDirty: false,
          isDeleted: item.isDeleted,
        ));

        print('[SyncService] Pushed invoice item: ${item.id}');
      } catch (e) {
        print('[SyncService] Failed to push invoice item ${item.id}: $e');
        // Continue with other items
      }
    }
  }

  Future<void> pull(AppDatabase db) async {
  // TODO: Use SharedPreferences for lastSync in Supabase pull
  // TODO: Use lastSync for Supabase pull
    // TODO: Fetch changes from Supabase since lastSync
    // TODO: Merge changes to local DB
    // TODO: Update lastSync
  }

  Future<void> updateLastSync(int millis) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastSyncKey, millis);
  }

  Future<int> getLastSync() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_lastSyncKey) ?? 0;
  }
}
