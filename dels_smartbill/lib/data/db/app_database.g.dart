// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// **************************************************************************
// FloorGenerator
// **************************************************************************

abstract class $AppDatabaseBuilderContract {
  /// Adds migrations to the builder.
  $AppDatabaseBuilderContract addMigrations(List<Migration> migrations);

  /// Adds a database [Callback] to the builder.
  $AppDatabaseBuilderContract addCallback(Callback callback);

  /// Creates the database and initializes it.
  Future<AppDatabase> build();
}

// ignore: avoid_classes_with_only_static_members
class $FloorAppDatabase {
  /// Creates a database builder for a persistent database.
  /// Once a database is built, you should keep a reference to it and re-use it.
  static $AppDatabaseBuilderContract databaseBuilder(String name) =>
      _$AppDatabaseBuilder(name);

  /// Creates a database builder for an in memory database.
  /// Information stored in an in memory database disappears when the process is killed.
  /// Once a database is built, you should keep a reference to it and re-use it.
  static $AppDatabaseBuilderContract inMemoryDatabaseBuilder() =>
      _$AppDatabaseBuilder(null);
}

class _$AppDatabaseBuilder implements $AppDatabaseBuilderContract {
  _$AppDatabaseBuilder(this.name);

  final String? name;

  final List<Migration> _migrations = [];

  Callback? _callback;

  @override
  $AppDatabaseBuilderContract addMigrations(List<Migration> migrations) {
    _migrations.addAll(migrations);
    return this;
  }

  @override
  $AppDatabaseBuilderContract addCallback(Callback callback) {
    _callback = callback;
    return this;
  }

  @override
  Future<AppDatabase> build() async {
    final path = name != null
        ? await sqfliteDatabaseFactory.getDatabasePath(name!)
        : ':memory:';
    final database = _$AppDatabase();
    database.database = await database.open(
      path,
      _migrations,
      _callback,
    );
    return database;
  }
}

class _$AppDatabase extends AppDatabase {
  _$AppDatabase([StreamController<String>? listener]) {
    changeListener = listener ?? StreamController<String>.broadcast();
  }

  ProductDao? _productDaoInstance;

  Future<sqflite.Database> open(
    String path,
    List<Migration> migrations, [
    Callback? callback,
  ]) async {
    final databaseOptions = sqflite.OpenDatabaseOptions(
      version: 1,
      onConfigure: (database) async {
        await database.execute('PRAGMA foreign_keys = ON');
        await callback?.onConfigure?.call(database);
      },
      onOpen: (database) async {
        await callback?.onOpen?.call(database);
      },
      onUpgrade: (database, startVersion, endVersion) async {
        await MigrationAdapter.runMigrations(
            database, startVersion, endVersion, migrations);

        await callback?.onUpgrade?.call(database, startVersion, endVersion);
      },
      onCreate: (database, version) async {
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `ProductEntity` (`id` TEXT NOT NULL, `name` TEXT NOT NULL, `category` TEXT NOT NULL, `price` REAL NOT NULL, `createdAt` INTEGER NOT NULL, `updatedAt` INTEGER NOT NULL, `deletedAtMillis` INTEGER, `isDirty` INTEGER NOT NULL, `isDeleted` INTEGER NOT NULL, PRIMARY KEY (`id`))');

        await callback?.onCreate?.call(database, version);
      },
    );
    return sqfliteDatabaseFactory.openDatabase(path, options: databaseOptions);
  }

  @override
  ProductDao get productDao {
    return _productDaoInstance ??= _$ProductDao(database, changeListener);
  }
}

class _$ProductDao extends ProductDao {
  _$ProductDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database, changeListener),
        _productEntityInsertionAdapter = InsertionAdapter(
            database,
            'ProductEntity',
            (ProductEntity item) => <String, Object?>{
                  'id': item.id,
                  'name': item.name,
                  'category': item.category,
                  'price': item.price,
                  'createdAt': _dateTimeConverter.encode(item.createdAt),
                  'updatedAt': _dateTimeConverter.encode(item.updatedAt),
                  'deletedAtMillis': item.deletedAtMillis,
                  'isDirty': item.isDirty ? 1 : 0,
                  'isDeleted': item.isDeleted ? 1 : 0
                },
            changeListener),
        _productEntityUpdateAdapter = UpdateAdapter(
            database,
            'ProductEntity',
            ['id'],
            (ProductEntity item) => <String, Object?>{
                  'id': item.id,
                  'name': item.name,
                  'category': item.category,
                  'price': item.price,
                  'createdAt': _dateTimeConverter.encode(item.createdAt),
                  'updatedAt': _dateTimeConverter.encode(item.updatedAt),
                  'deletedAtMillis': item.deletedAtMillis,
                  'isDirty': item.isDirty ? 1 : 0,
                  'isDeleted': item.isDeleted ? 1 : 0
                },
            changeListener);

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<ProductEntity> _productEntityInsertionAdapter;

  final UpdateAdapter<ProductEntity> _productEntityUpdateAdapter;

  @override
  Stream<List<ProductEntity>> watchAll() {
    return _queryAdapter.queryListStream(
        'SELECT * FROM ProductEntity WHERE isDeleted = 0 ORDER BY name ASC',
        mapper: (Map<String, Object?> row) => ProductEntity(
            id: row['id'] as String,
            name: row['name'] as String,
            category: row['category'] as String,
            price: row['price'] as double,
            createdAt: _dateTimeConverter.decode(row['createdAt'] as int),
            updatedAt: _dateTimeConverter.decode(row['updatedAt'] as int),
            deletedAtMillis: row['deletedAtMillis'] as int?,
            isDirty: (row['isDirty'] as int) != 0,
            isDeleted: (row['isDeleted'] as int) != 0),
        queryableName: 'ProductEntity',
        isView: false);
  }

  @override
  Future<List<ProductEntity>> search(String q) async {
    return _queryAdapter.queryList(
        'SELECT * FROM ProductEntity WHERE isDeleted = 0 AND (name LIKE ?1 OR category LIKE ?1) ORDER BY name ASC',
        mapper: (Map<String, Object?> row) => ProductEntity(id: row['id'] as String, name: row['name'] as String, category: row['category'] as String, price: row['price'] as double, createdAt: _dateTimeConverter.decode(row['createdAt'] as int), updatedAt: _dateTimeConverter.decode(row['updatedAt'] as int), deletedAtMillis: row['deletedAtMillis'] as int?, isDirty: (row['isDirty'] as int) != 0, isDeleted: (row['isDeleted'] as int) != 0),
        arguments: [q]);
  }

  @override
  Future<int?> countAll() async {
    return _queryAdapter.query('SELECT COUNT(*) FROM ProductEntity',
        mapper: (Map<String, Object?> row) => row.values.first as int);
  }

  @override
  Future<void> softDelete(
    String id,
    int deletedAtMillis,
  ) async {
    await _queryAdapter.queryNoReturn(
        'UPDATE ProductEntity SET isDeleted = 1, deletedAtMillis = ?2, isDirty = 1 WHERE id = ?1',
        arguments: [id, deletedAtMillis]);
  }

  @override
  Future<void> insertAll(List<ProductEntity> items) async {
    await _productEntityInsertionAdapter.insertList(
        items, OnConflictStrategy.abort);
  }

  @override
  Future<void> insertOne(ProductEntity item) async {
    await _productEntityInsertionAdapter.insert(item, OnConflictStrategy.abort);
  }

  @override
  Future<void> updateOne(ProductEntity item) async {
    await _productEntityUpdateAdapter.update(item, OnConflictStrategy.abort);
  }
}

// ignore_for_file: unused_element
final _dateTimeConverter = DateTimeConverter();
