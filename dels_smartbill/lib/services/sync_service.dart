import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';
import '../data/db/app_database.dart';
import '../data/db/entities/product_entity.dart';
import '../data/db/entities/customer_entity.dart';
import '../data/db/entities/invoice_entity.dart';

class SyncService {
  final Logger _logger = Logger();
  static const _lastSyncKey = 'last_sync_at';

  /// Push dirty (locally modified) records to Supabase
  Future<void> push(AppDatabase db) async {
    try {
      // Check if Supabase is initialized by trying to access the client
      SupabaseClient? supabase;
      try {
        supabase = Supabase.instance.client;
      } catch (e) {
        _logger.w('[SyncService] Supabase not initialized, skipping push');
        return;
      }

      _logger.i('[SyncService] Starting push sync...');

      // 1. Push Products
      await _pushProducts(db, supabase);

      // 2. Push Customers
      await _pushCustomers(db, supabase);

      // 3. Push Invoices
      await _pushInvoices(db, supabase);

      // 4. Push Invoice Items
      await _pushInvoiceItems(db, supabase);

  _logger.i('[SyncService] Push sync completed successfully');
    } catch (e, stackTrace) {
      _logger.e('[SyncService] Push sync failed: $e');
      _logger.e('[SyncService] Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> _pushProducts(AppDatabase db, SupabaseClient supabase) async {
    final dirtyProducts = await db.productDao.findDirty();
    if (dirtyProducts.isEmpty) {
      _logger.i('[SyncService] No dirty products to push');
      return;
    }

    _logger.i('[SyncService] Pushing ${dirtyProducts.length} products...');

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
          _logger.i('[SyncService] Soft deleted product: ${product.name} (set deleted_at timestamp)');
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
          _logger.i('[SyncService] Pushed product: ${product.name}');
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

  _logger.i('[SyncService] Pushed product: ${product.name}');
      } catch (e) {
        _logger.e('[SyncService] Failed to push product ${product.name}: $e');
        // Continue with other products
      }
    }
  }

  Future<void> _pushCustomers(AppDatabase db, SupabaseClient supabase) async {
    final dirtyCustomers = await db.customerDao.findDirty();
    if (dirtyCustomers.isEmpty) {
      _logger.i('[SyncService] No dirty customers to push');
      return;
    }

    _logger.i('[SyncService] Pushing ${dirtyCustomers.length} customers...');

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

  _logger.i('[SyncService] Pushed customer: ${customer.name}');
      } catch (e) {
        _logger.e('[SyncService] Failed to push customer ${customer.name}: $e');
        // Continue with other customers
      }
    }
  }

  Future<void> _pushInvoices(AppDatabase db, SupabaseClient supabase) async {
    final dirtyInvoices = await db.invoiceDao.findDirty();
    if (dirtyInvoices.isEmpty) {
      _logger.i('[SyncService] No dirty invoices to push');
      return;
    }

    _logger.i('[SyncService] Pushing ${dirtyInvoices.length} invoices...');

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
            _logger.i('[SyncService] Invoice number updated: ${invoice.invoiceNumber} -> $serverInvoiceNumber');
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

  _logger.i('[SyncService] Pushed invoice: ${invoice.invoiceNumber}');
      } catch (e) {
        _logger.e('[SyncService] Failed to push invoice ${invoice.invoiceNumber}: $e');
        // Continue with other invoices
      }
    }
  }

  Future<void> _pushInvoiceItems(AppDatabase db, SupabaseClient supabase) async {
    final dirtyItems = await db.invoiceItemDao.findDirty();
    if (dirtyItems.isEmpty) {
      _logger.i('[SyncService] No dirty invoice items to push');
      return;
    }

    _logger.i('[SyncService] Pushing ${dirtyItems.length} invoice items...');

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

  _logger.i('[SyncService] Pushed invoice item: ${item.id}');
      } catch (e) {
        _logger.e('[SyncService] Failed to push invoice item ${item.id}: $e');
        // Continue with other items
      }
    }
  }

  Future<void> pull(AppDatabase db) async {
    try {
      // Check if Supabase is initialized
      SupabaseClient? supabase;
      try {
        supabase = Supabase.instance.client;
      } catch (e) {
        _logger.w('[SyncService] Supabase not initialized, skipping pull');
        return;
      }

      _logger.i('[SyncService] Starting pull sync...');
      
      // Get last sync timestamp
      final lastSync = await getLastSync();
  _logger.i('[SyncService] Last sync was at: $lastSync (${DateTime.fromMillisecondsSinceEpoch(lastSync)})');
      
      // Fetch changes from Supabase
      await _pullProducts(db, supabase, lastSync);
      await _pullCustomers(db, supabase, lastSync);
      await _pullInvoices(db, supabase, lastSync);
      await _pullInvoiceItems(db, supabase, lastSync);
      
      // Update last sync timestamp
      await updateLastSync(DateTime.now().millisecondsSinceEpoch);
  _logger.i('[SyncService] Pull sync completed successfully');
    } catch (e, stack) {
      _logger.e('[SyncService] Pull sync failed: $e');
      _logger.e('[SyncService] Stack trace: $stack');
      rethrow;
    }
  }

  Future<void> _pullProducts(AppDatabase db, SupabaseClient supabase, int lastSync) async {
    try {
      _logger.i('[SyncService] Pulling products since $lastSync...');
      
      // Call RPC function to fetch products since lastSync
      final response = await supabase.rpc('fetch_products_since', 
        params: {'since_timestamp': lastSync}
      ) as List<dynamic>;
      
  _logger.i('[SyncService] Fetched ${response.length} products from Supabase');
      
      // Process each product
      for (final item in response) {
        try {
          // Parse deletedAtMillis from deleted_at timestamp
          int? deletedAtMillis;
          if (item['deleted_at'] != null) {
            deletedAtMillis = DateTime.parse(item['deleted_at'] as String).millisecondsSinceEpoch;
          }
          
          final remoteProduct = ProductEntity(
            id: item['id'] as String,
            name: item['name'] as String,
            price: (item['price'] as num).toDouble(),
            category: item['category'] as String,
            createdAt: DateTime.parse(item['created_at'] as String),
            updatedAt: DateTime.parse(item['updated_at'] as String),
            deletedAtMillis: deletedAtMillis,
            isDirty: false, // Remote data is clean
            isDeleted: deletedAtMillis != null,
          );
          
          // Check if product exists locally by ID
          final localProduct = await db.productDao.findById(remoteProduct.id);
          
          if (localProduct == null) {
            // New product, insert it
            await db.productDao.insertOne(remoteProduct);
            _logger.i('[SyncService] Inserted new product: ${remoteProduct.name}');
          } else {
            // Product exists, check for conflicts
            if (remoteProduct.updatedAt.isAfter(localProduct.updatedAt)) {
              // Remote is newer, update local
              await db.productDao.updateOne(remoteProduct);
              _logger.i('[SyncService] Updated product: ${remoteProduct.name} (remote newer)');
            } else {
              _logger.i('[SyncService] Skipped product: ${remoteProduct.name} (local newer)');
            }
          }
        } catch (e) {
          _logger.e('[SyncService] Failed to process product: $e');
          // Continue with other products
        }
      }
    } catch (e) {
      _logger.e('[SyncService] Failed to pull products: $e');
      rethrow;
    }
  }

  Future<void> _pullCustomers(AppDatabase db, SupabaseClient supabase, int lastSync) async {
    try {
      _logger.i('[SyncService] Pulling customers since $lastSync...');
      
      final response = await supabase.rpc('fetch_customers_since', 
        params: {'since_timestamp': lastSync}
      ) as List<dynamic>;
      
  _logger.i('[SyncService] Fetched ${response.length} customers from Supabase');
      
      for (final item in response) {
        try {
          int? deletedAtMillis;
          if (item['deleted_at'] != null) {
            deletedAtMillis = DateTime.parse(item['deleted_at'] as String).millisecondsSinceEpoch;
          }
          
          final remoteCustomer = CustomerEntity(
            id: item['id'] as String,
            name: item['name'] as String,
            phone: item['phone'] as String? ?? '',
            email: item['email'] as String? ?? '',
            address: item['address'] as String? ?? '',
            createdAt: DateTime.parse(item['created_at'] as String),
            updatedAt: DateTime.parse(item['updated_at'] as String),
            deletedAtMillis: deletedAtMillis,
            isDirty: false,
            isDeleted: deletedAtMillis != null,
          );
          
          // Check if customer exists locally by ID
          final localCustomer = await db.customerDao.findById(remoteCustomer.id);
          
          if (localCustomer == null) {
            await db.customerDao.insertOne(remoteCustomer);
            _logger.i('[SyncService] Inserted new customer: ${remoteCustomer.name}');
          } else {
            if (remoteCustomer.updatedAt.isAfter(localCustomer.updatedAt)) {
              await db.customerDao.updateOne(remoteCustomer);
              _logger.i('[SyncService] Updated customer: ${remoteCustomer.name} (remote newer)');
            } else {
              _logger.i('[SyncService] Skipped customer: ${remoteCustomer.name} (local newer)');
            }
          }
        } catch (e) {
          _logger.e('[SyncService] Failed to process customer: $e');
        }
      }
    } catch (e) {
      _logger.e('[SyncService] Failed to pull customers: $e');
      rethrow;
    }
  }

  Future<void> _pullInvoices(AppDatabase db, SupabaseClient supabase, int lastSync) async {
    try {
      _logger.i('[SyncService] Pulling invoices since $lastSync...');
      
      final response = await supabase.rpc('fetch_invoices_since', 
        params: {'since_timestamp': lastSync}
      ) as List<dynamic>;
      
  _logger.i('[SyncService] Fetched ${response.length} invoices from Supabase');
      
      for (final item in response) {
        try {
          int? deletedAtMillis;
          if (item['deleted_at'] != null) {
            deletedAtMillis = DateTime.parse(item['deleted_at'] as String).millisecondsSinceEpoch;
          }
          
          final remoteInvoice = InvoiceEntity(
            id: item['id'] as String,
            customerId: item['customer_id'] as String,
            invoiceNumber: item['invoice_number'] as String,
            totalAmount: (item['total_amount'] as num).toDouble(),
            createdByUserId: item['created_by_user_id'] as String? ?? 'unknown',
            createdAt: DateTime.parse(item['created_at'] as String),
            updatedAt: DateTime.parse(item['updated_at'] as String),
            deletedAtMillis: deletedAtMillis,
            isDirty: false,
            isDeleted: deletedAtMillis != null,
          );
          
          // Check if invoice exists locally by ID
          final localInvoice = await db.invoiceDao.findById(remoteInvoice.id);
          
          if (localInvoice == null) {
            await db.invoiceDao.insertOne(remoteInvoice);
            _logger.i('[SyncService] Inserted new invoice: ${remoteInvoice.invoiceNumber}');
          } else {
            if (remoteInvoice.updatedAt.isAfter(localInvoice.updatedAt)) {
              await db.invoiceDao.updateOne(remoteInvoice);
              _logger.i('[SyncService] Updated invoice: ${remoteInvoice.invoiceNumber} (remote newer)');
            } else {
              _logger.i('[SyncService] Skipped invoice: ${remoteInvoice.invoiceNumber} (local newer)');
            }
          }
        } catch (e) {
          _logger.e('[SyncService] Failed to process invoice: $e');
        }
      }
    } catch (e) {
      _logger.e('[SyncService] Failed to pull invoices: $e');
      rethrow;
    }
  }

  Future<void> _pullInvoiceItems(AppDatabase db, SupabaseClient supabase, int lastSync) async {
    try {
      _logger.i('[SyncService] Pulling invoice items since $lastSync...');
      
      final response = await supabase.rpc('fetch_invoice_items_since', 
        params: {'since_timestamp': lastSync}
      ) as List<dynamic>;
      
  _logger.i('[SyncService] Fetched ${response.length} invoice items from Supabase');
      
      for (final item in response) {
        try {
          int? deletedAtMillis;
          if (item['deleted_at'] != null) {
            deletedAtMillis = DateTime.parse(item['deleted_at'] as String).millisecondsSinceEpoch;
          }
          
          final remoteItem = InvoiceItemEntity(
            id: item['id'] as String,
            invoiceId: item['invoice_id'] as String,
            productId: item['product_id'] as String,
            quantity: item['quantity'] as int,
            unitPrice: (item['unit_price'] as num).toDouble(),
            createdAt: DateTime.parse(item['created_at'] as String),
            updatedAt: DateTime.parse(item['updated_at'] as String),
            deletedAtMillis: deletedAtMillis,
            isDirty: false,
            isDeleted: deletedAtMillis != null,
          );
          
          // Check if invoice item exists locally by ID
          final localItem = await db.invoiceItemDao.findById(remoteItem.id);
          
          if (localItem == null) {
            await db.invoiceItemDao.insertOne(remoteItem);
            _logger.i('[SyncService] Inserted new invoice item: ${remoteItem.id}');
          } else {
            if (remoteItem.updatedAt.isAfter(localItem.updatedAt)) {
              await db.invoiceItemDao.updateOne(remoteItem);
              _logger.i('[SyncService] Updated invoice item: ${remoteItem.id} (remote newer)');
            } else {
              _logger.i('[SyncService] Skipped invoice item: ${remoteItem.id} (local newer)');
            }
          }
        } catch (e) {
          _logger.e('[SyncService] Failed to process invoice item: $e');
        }
      }
    } catch (e) {
      _logger.e('[SyncService] Failed to pull invoice items: $e');
      rethrow;
    }
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
