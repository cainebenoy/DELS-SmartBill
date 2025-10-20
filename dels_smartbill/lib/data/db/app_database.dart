import 'dart:async';
import 'package:floor/floor.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'daos/product_dao.dart';
import 'daos/customer_dao.dart';
import 'entities/product_entity.dart';
import 'entities/customer_entity.dart';
import 'entities/invoice_entity.dart';
import 'daos/invoice_dao.dart';
import 'converters/date_time_converter.dart';

part 'app_database.g.dart';

@TypeConverters([DateTimeConverter])
@Database(version: 2, entities: [ProductEntity, CustomerEntity, InvoiceEntity, InvoiceItemEntity])
abstract class AppDatabase extends FloorDatabase {
  ProductDao get productDao;
  CustomerDao get customerDao;
  InvoiceDao get invoiceDao;
  InvoiceItemDao get invoiceItemDao;
}

Future<AppDatabase> openAppDatabase({String? name}) async {
  final db = await $FloorAppDatabase
      .databaseBuilder(name ?? 'smartbill.db')
      .addMigrations([_migration1to2])
      .build();
  await _seedIfEmpty(db);
  return db;
}

final _migration1to2 = Migration(1, 2, (database) async {
  // Create InvoiceEntity table
  await database.execute('''
    CREATE TABLE IF NOT EXISTS InvoiceEntity (
      id TEXT PRIMARY KEY NOT NULL,
      invoiceNumber TEXT NOT NULL,
      customerId TEXT NOT NULL,
      totalAmount REAL NOT NULL,
      createdByUserId TEXT NOT NULL,
      createdAt INTEGER NOT NULL,
      updatedAt INTEGER NOT NULL,
      deletedAtMillis INTEGER,
      isDirty INTEGER NOT NULL,
      isDeleted INTEGER NOT NULL
    )
  ''');
  
  // Create InvoiceItemEntity table
  await database.execute('''
    CREATE TABLE IF NOT EXISTS InvoiceItemEntity (
      id TEXT PRIMARY KEY NOT NULL,
      invoiceId TEXT NOT NULL,
      productId TEXT NOT NULL,
      quantity INTEGER NOT NULL,
      unitPrice REAL NOT NULL,
      createdAt INTEGER NOT NULL,
      updatedAt INTEGER NOT NULL,
      deletedAtMillis INTEGER,
      isDirty INTEGER NOT NULL,
      isDeleted INTEGER NOT NULL
    )
  ''');
});

Future<void> _seedIfEmpty(AppDatabase db) async {
  final count = await db.productDao.countAll() ?? 0;
  if (count > 0) return;
  final now = DateTime.now();
  await db.productDao.insertAll([
    ProductEntity(
      id: 'p1',
      name: 'Laptop',
      category: 'Electronics',
      price: 1200.00,
      createdAt: now,
      updatedAt: now,
      deletedAtMillis: null,
    ),
    ProductEntity(
      id: 'p2',
      name: 'Notebook',
      category: 'Office Supplies',
      price: 5.00,
      createdAt: now,
      updatedAt: now,
      deletedAtMillis: null,
    ),
    ProductEntity(
      id: 'p3',
      name: 'Mouse',
      category: 'Electronics',
      price: 25.00,
      createdAt: now,
      updatedAt: now,
      deletedAtMillis: null,
    ),
    ProductEntity(
      id: 'p4',
      name: 'Pens',
      category: 'Office Supplies',
      price: 2.50,
      createdAt: now,
      updatedAt: now,
      deletedAtMillis: null,
    ),
    ProductEntity(
      id: 'p5',
      name: 'Keyboard',
      category: 'Electronics',
      price: 75.00,
      createdAt: now,
      updatedAt: now,
      deletedAtMillis: null,
    ),
  ]);
}
