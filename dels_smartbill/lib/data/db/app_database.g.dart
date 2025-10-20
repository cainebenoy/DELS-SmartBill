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

  CustomerDao? _customerDaoInstance;

  InvoiceDao? _invoiceDaoInstance;

  InvoiceItemDao? _invoiceItemDaoInstance;

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
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `CustomerEntity` (`id` TEXT NOT NULL, `name` TEXT NOT NULL, `phone` TEXT NOT NULL, `email` TEXT NOT NULL, `address` TEXT NOT NULL, `createdAt` INTEGER NOT NULL, `updatedAt` INTEGER NOT NULL, `deletedAtMillis` INTEGER, `isDirty` INTEGER NOT NULL, `isDeleted` INTEGER NOT NULL, PRIMARY KEY (`id`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `InvoiceEntity` (`id` TEXT NOT NULL, `invoiceNumber` TEXT NOT NULL, `customerId` TEXT NOT NULL, `totalAmount` REAL NOT NULL, `createdByUserId` TEXT NOT NULL, `createdAt` INTEGER NOT NULL, `updatedAt` INTEGER NOT NULL, `deletedAtMillis` INTEGER, `isDirty` INTEGER NOT NULL, `isDeleted` INTEGER NOT NULL, PRIMARY KEY (`id`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `InvoiceItemEntity` (`id` TEXT NOT NULL, `invoiceId` TEXT NOT NULL, `productId` TEXT NOT NULL, `quantity` INTEGER NOT NULL, `unitPrice` REAL NOT NULL, `createdAt` INTEGER NOT NULL, `updatedAt` INTEGER NOT NULL, `deletedAtMillis` INTEGER, `isDirty` INTEGER NOT NULL, `isDeleted` INTEGER NOT NULL, PRIMARY KEY (`id`))');

        await callback?.onCreate?.call(database, version);
      },
    );
    return sqfliteDatabaseFactory.openDatabase(path, options: databaseOptions);
  }

  @override
  ProductDao get productDao {
    return _productDaoInstance ??= _$ProductDao(database, changeListener);
  }

  @override
  CustomerDao get customerDao {
    return _customerDaoInstance ??= _$CustomerDao(database, changeListener);
  }

  @override
  InvoiceDao get invoiceDao {
    return _invoiceDaoInstance ??= _$InvoiceDao(database, changeListener);
  }

  @override
  InvoiceItemDao get invoiceItemDao {
    return _invoiceItemDaoInstance ??=
        _$InvoiceItemDao(database, changeListener);
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

class _$CustomerDao extends CustomerDao {
  _$CustomerDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database, changeListener),
        _customerEntityInsertionAdapter = InsertionAdapter(
            database,
            'CustomerEntity',
            (CustomerEntity item) => <String, Object?>{
                  'id': item.id,
                  'name': item.name,
                  'phone': item.phone,
                  'email': item.email,
                  'address': item.address,
                  'createdAt': _dateTimeConverter.encode(item.createdAt),
                  'updatedAt': _dateTimeConverter.encode(item.updatedAt),
                  'deletedAtMillis': item.deletedAtMillis,
                  'isDirty': item.isDirty ? 1 : 0,
                  'isDeleted': item.isDeleted ? 1 : 0
                },
            changeListener),
        _customerEntityUpdateAdapter = UpdateAdapter(
            database,
            'CustomerEntity',
            ['id'],
            (CustomerEntity item) => <String, Object?>{
                  'id': item.id,
                  'name': item.name,
                  'phone': item.phone,
                  'email': item.email,
                  'address': item.address,
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

  final InsertionAdapter<CustomerEntity> _customerEntityInsertionAdapter;

  final UpdateAdapter<CustomerEntity> _customerEntityUpdateAdapter;

  @override
  Stream<List<CustomerEntity>> watchAll() {
    return _queryAdapter.queryListStream(
        'SELECT * FROM CustomerEntity WHERE isDeleted = 0 ORDER BY name ASC',
        mapper: (Map<String, Object?> row) => CustomerEntity(
            id: row['id'] as String,
            name: row['name'] as String,
            phone: row['phone'] as String,
            email: row['email'] as String,
            address: row['address'] as String,
            createdAt: _dateTimeConverter.decode(row['createdAt'] as int),
            updatedAt: _dateTimeConverter.decode(row['updatedAt'] as int),
            deletedAtMillis: row['deletedAtMillis'] as int?,
            isDirty: (row['isDirty'] as int) != 0,
            isDeleted: (row['isDeleted'] as int) != 0),
        queryableName: 'CustomerEntity',
        isView: false);
  }

  @override
  Future<List<CustomerEntity>> search(String q) async {
    return _queryAdapter.queryList(
        'SELECT * FROM CustomerEntity WHERE isDeleted = 0 AND (name LIKE ?1 OR phone LIKE ?1 OR email LIKE ?1) ORDER BY name ASC',
        mapper: (Map<String, Object?> row) => CustomerEntity(id: row['id'] as String, name: row['name'] as String, phone: row['phone'] as String, email: row['email'] as String, address: row['address'] as String, createdAt: _dateTimeConverter.decode(row['createdAt'] as int), updatedAt: _dateTimeConverter.decode(row['updatedAt'] as int), deletedAtMillis: row['deletedAtMillis'] as int?, isDirty: (row['isDirty'] as int) != 0, isDeleted: (row['isDeleted'] as int) != 0),
        arguments: [q]);
  }

  @override
  Future<int?> countAll() async {
    return _queryAdapter.query('SELECT COUNT(*) FROM CustomerEntity',
        mapper: (Map<String, Object?> row) => row.values.first as int);
  }

  @override
  Future<void> softDelete(
    String id,
    int deletedAtMillis,
  ) async {
    await _queryAdapter.queryNoReturn(
        'UPDATE CustomerEntity SET isDeleted = 1, deletedAtMillis = ?2, isDirty = 1 WHERE id = ?1',
        arguments: [id, deletedAtMillis]);
  }

  @override
  Future<void> insertAll(List<CustomerEntity> items) async {
    await _customerEntityInsertionAdapter.insertList(
        items, OnConflictStrategy.abort);
  }

  @override
  Future<void> insertOne(CustomerEntity item) async {
    await _customerEntityInsertionAdapter.insert(
        item, OnConflictStrategy.abort);
  }

  @override
  Future<void> updateOne(CustomerEntity item) async {
    await _customerEntityUpdateAdapter.update(item, OnConflictStrategy.abort);
  }
}

class _$InvoiceDao extends InvoiceDao {
  _$InvoiceDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database, changeListener),
        _invoiceEntityInsertionAdapter = InsertionAdapter(
            database,
            'InvoiceEntity',
            (InvoiceEntity item) => <String, Object?>{
                  'id': item.id,
                  'invoiceNumber': item.invoiceNumber,
                  'customerId': item.customerId,
                  'totalAmount': item.totalAmount,
                  'createdByUserId': item.createdByUserId,
                  'createdAt': _dateTimeConverter.encode(item.createdAt),
                  'updatedAt': _dateTimeConverter.encode(item.updatedAt),
                  'deletedAtMillis': item.deletedAtMillis,
                  'isDirty': item.isDirty ? 1 : 0,
                  'isDeleted': item.isDeleted ? 1 : 0
                },
            changeListener),
        _invoiceEntityUpdateAdapter = UpdateAdapter(
            database,
            'InvoiceEntity',
            ['id'],
            (InvoiceEntity item) => <String, Object?>{
                  'id': item.id,
                  'invoiceNumber': item.invoiceNumber,
                  'customerId': item.customerId,
                  'totalAmount': item.totalAmount,
                  'createdByUserId': item.createdByUserId,
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

  final InsertionAdapter<InvoiceEntity> _invoiceEntityInsertionAdapter;

  final UpdateAdapter<InvoiceEntity> _invoiceEntityUpdateAdapter;

  @override
  Stream<List<InvoiceEntity>> watchAll() {
    return _queryAdapter.queryListStream(
        'SELECT * FROM InvoiceEntity WHERE isDeleted = 0 ORDER BY createdAt DESC',
        mapper: (Map<String, Object?> row) => InvoiceEntity(
            id: row['id'] as String,
            invoiceNumber: row['invoiceNumber'] as String,
            customerId: row['customerId'] as String,
            totalAmount: row['totalAmount'] as double,
            createdByUserId: row['createdByUserId'] as String,
            createdAt: _dateTimeConverter.decode(row['createdAt'] as int),
            updatedAt: _dateTimeConverter.decode(row['updatedAt'] as int),
            deletedAtMillis: row['deletedAtMillis'] as int?,
            isDirty: (row['isDirty'] as int) != 0,
            isDeleted: (row['isDeleted'] as int) != 0),
        queryableName: 'InvoiceEntity',
        isView: false);
  }

  @override
  Future<List<InvoiceEntity>> search(String q) async {
    return _queryAdapter.queryList(
        'SELECT * FROM InvoiceEntity WHERE isDeleted = 0 AND (invoiceNumber LIKE ?1) ORDER BY createdAt DESC',
        mapper: (Map<String, Object?> row) => InvoiceEntity(id: row['id'] as String, invoiceNumber: row['invoiceNumber'] as String, customerId: row['customerId'] as String, totalAmount: row['totalAmount'] as double, createdByUserId: row['createdByUserId'] as String, createdAt: _dateTimeConverter.decode(row['createdAt'] as int), updatedAt: _dateTimeConverter.decode(row['updatedAt'] as int), deletedAtMillis: row['deletedAtMillis'] as int?, isDirty: (row['isDirty'] as int) != 0, isDeleted: (row['isDeleted'] as int) != 0),
        arguments: [q]);
  }

  @override
  Future<int?> countAll() async {
    return _queryAdapter.query('SELECT COUNT(*) FROM InvoiceEntity',
        mapper: (Map<String, Object?> row) => row.values.first as int);
  }

  @override
  Future<void> softDelete(
    String id,
    int deletedAtMillis,
  ) async {
    await _queryAdapter.queryNoReturn(
        'UPDATE InvoiceEntity SET isDeleted = 1, deletedAtMillis = ?2, isDirty = 1 WHERE id = ?1',
        arguments: [id, deletedAtMillis]);
  }

  @override
  Future<void> insertAll(List<InvoiceEntity> items) async {
    await _invoiceEntityInsertionAdapter.insertList(
        items, OnConflictStrategy.abort);
  }

  @override
  Future<void> insertOne(InvoiceEntity item) async {
    await _invoiceEntityInsertionAdapter.insert(item, OnConflictStrategy.abort);
  }

  @override
  Future<void> updateOne(InvoiceEntity item) async {
    await _invoiceEntityUpdateAdapter.update(item, OnConflictStrategy.abort);
  }
}

class _$InvoiceItemDao extends InvoiceItemDao {
  _$InvoiceItemDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database, changeListener),
        _invoiceItemEntityInsertionAdapter = InsertionAdapter(
            database,
            'InvoiceItemEntity',
            (InvoiceItemEntity item) => <String, Object?>{
                  'id': item.id,
                  'invoiceId': item.invoiceId,
                  'productId': item.productId,
                  'quantity': item.quantity,
                  'unitPrice': item.unitPrice,
                  'createdAt': _dateTimeConverter.encode(item.createdAt),
                  'updatedAt': _dateTimeConverter.encode(item.updatedAt),
                  'deletedAtMillis': item.deletedAtMillis,
                  'isDirty': item.isDirty ? 1 : 0,
                  'isDeleted': item.isDeleted ? 1 : 0
                },
            changeListener),
        _invoiceItemEntityUpdateAdapter = UpdateAdapter(
            database,
            'InvoiceItemEntity',
            ['id'],
            (InvoiceItemEntity item) => <String, Object?>{
                  'id': item.id,
                  'invoiceId': item.invoiceId,
                  'productId': item.productId,
                  'quantity': item.quantity,
                  'unitPrice': item.unitPrice,
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

  final InsertionAdapter<InvoiceItemEntity> _invoiceItemEntityInsertionAdapter;

  final UpdateAdapter<InvoiceItemEntity> _invoiceItemEntityUpdateAdapter;

  @override
  Stream<List<InvoiceItemEntity>> watchByInvoice(String invoiceId) {
    return _queryAdapter.queryListStream(
        'SELECT * FROM InvoiceItemEntity WHERE isDeleted = 0 AND invoiceId = ?1 ORDER BY createdAt ASC',
        mapper: (Map<String, Object?> row) => InvoiceItemEntity(
            id: row['id'] as String,
            invoiceId: row['invoiceId'] as String,
            productId: row['productId'] as String,
            quantity: row['quantity'] as int,
            unitPrice: row['unitPrice'] as double,
            createdAt: _dateTimeConverter.decode(row['createdAt'] as int),
            updatedAt: _dateTimeConverter.decode(row['updatedAt'] as int),
            deletedAtMillis: row['deletedAtMillis'] as int?,
            isDirty: (row['isDirty'] as int) != 0,
            isDeleted: (row['isDeleted'] as int) != 0),
        arguments: [invoiceId],
        queryableName: 'InvoiceItemEntity',
        isView: false);
  }

  @override
  Future<List<InvoiceItemEntity>> byInvoice(String invoiceId) async {
    return _queryAdapter.queryList(
        'SELECT * FROM InvoiceItemEntity WHERE isDeleted = 0 AND invoiceId = ?1 ORDER BY createdAt ASC',
        mapper: (Map<String, Object?> row) => InvoiceItemEntity(id: row['id'] as String, invoiceId: row['invoiceId'] as String, productId: row['productId'] as String, quantity: row['quantity'] as int, unitPrice: row['unitPrice'] as double, createdAt: _dateTimeConverter.decode(row['createdAt'] as int), updatedAt: _dateTimeConverter.decode(row['updatedAt'] as int), deletedAtMillis: row['deletedAtMillis'] as int?, isDirty: (row['isDirty'] as int) != 0, isDeleted: (row['isDeleted'] as int) != 0),
        arguments: [invoiceId]);
  }

  @override
  Future<List<InvoiceItemEntity>> getAll() async {
    return _queryAdapter.queryList(
        'SELECT * FROM InvoiceItemEntity WHERE isDeleted = 0 ORDER BY createdAt ASC',
        mapper: (Map<String, Object?> row) => InvoiceItemEntity(
            id: row['id'] as String,
            invoiceId: row['invoiceId'] as String,
            productId: row['productId'] as String,
            quantity: row['quantity'] as int,
            unitPrice: row['unitPrice'] as double,
            createdAt: _dateTimeConverter.decode(row['createdAt'] as int),
            updatedAt: _dateTimeConverter.decode(row['updatedAt'] as int),
            deletedAtMillis: row['deletedAtMillis'] as int?,
            isDirty: (row['isDirty'] as int) != 0,
            isDeleted: (row['isDeleted'] as int) != 0));
  }

  @override
  Future<void> softDelete(
    String id,
    int deletedAtMillis,
  ) async {
    await _queryAdapter.queryNoReturn(
        'UPDATE InvoiceItemEntity SET isDeleted = 1, deletedAtMillis = ?2, isDirty = 1 WHERE id = ?1',
        arguments: [id, deletedAtMillis]);
  }

  @override
  Future<void> insertAll(List<InvoiceItemEntity> items) async {
    await _invoiceItemEntityInsertionAdapter.insertList(
        items, OnConflictStrategy.abort);
  }

  @override
  Future<void> insertOne(InvoiceItemEntity item) async {
    await _invoiceItemEntityInsertionAdapter.insert(
        item, OnConflictStrategy.abort);
  }

  @override
  Future<void> updateOne(InvoiceItemEntity item) async {
    await _invoiceItemEntityUpdateAdapter.update(
        item, OnConflictStrategy.abort);
  }
}

// ignore_for_file: unused_element
final _dateTimeConverter = DateTimeConverter();
