import 'dart:async';
import 'package:floor/floor.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'daos/product_dao.dart';
import 'entities/product_entity.dart';
import 'converters/date_time_converter.dart';

part 'app_database.g.dart';

@TypeConverters([DateTimeConverter])
@Database(version: 1, entities: [ProductEntity])
abstract class AppDatabase extends FloorDatabase {
  ProductDao get productDao;
}

Future<AppDatabase> openAppDatabase({String? name}) async {
  final db = await $FloorAppDatabase
      .databaseBuilder(name ?? 'smartbill.db')
      .build();
  await _seedIfEmpty(db);
  return db;
}

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
