import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';
import '../../../data/db/app_database.dart';
import '../../../data/db/entities/customer_entity.dart';
import '../../../services/auto_sync_service.dart';

/// State class for managing customers data
class CustomersState {
  final List<CustomerEntity> customers;
  final String searchQuery;

  const CustomersState({
    this.customers = const [],
    this.searchQuery = '',
  });

  List<CustomerEntity> get filteredCustomers {
    if (searchQuery.isEmpty) return customers;
    final q = searchQuery.toLowerCase();
    return customers.where((c) {
      return c.name.toLowerCase().contains(q) ||
          c.phone.toLowerCase().contains(q) ||
          c.email.toLowerCase().contains(q);
    }).toList();
  }

  CustomersState copyWith({
    List<CustomerEntity>? customers,
    String? searchQuery,
  }) {
    return CustomersState(
      customers: customers ?? this.customers,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

/// Notifier for managing customers state using AsyncNotifier pattern
class CustomersNotifier extends AsyncNotifier<CustomersState> {
  final _logger = Logger();
  final _uuid = const Uuid();

  @override
  Future<CustomersState> build() async {
    return await _loadCustomers();
  }

  Future<CustomersState> _loadCustomers() async {
    try {
      final db = await $FloorAppDatabase.databaseBuilder('smartbill.db').build();
      final customers = await db.customerDao.search('%');
      return CustomersState(customers: customers);
    } catch (e, st) {
      _logger.e('Error loading customers', error: e, stackTrace: st);
      throw Exception('Failed to load customers: $e');
    }
  }

  Future<void> setSearchQuery(String query) async {
    state = await AsyncValue.guard(() async {
      final currentState = state.requireValue;
      return currentState.copyWith(searchQuery: query);
    });
  }

  Future<void> addCustomer({
    required String name,
    required String phone,
    required String email,
    required String address,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      try {
        final now = DateTime.now();
        final customer = CustomerEntity(
          id: _uuid.v4(),
          name: name,
          phone: phone,
          email: email,
          address: address,
          createdAt: now,
          updatedAt: now,
          isDirty: true,
        );

        final db = await $FloorAppDatabase.databaseBuilder('smartbill.db').build();
        await db.customerDao.insertOne(customer);

        // Trigger auto-sync
        final autoSync = AutoSyncService();
        await autoSync.syncNow();

        return await _loadCustomers();
      } catch (e, st) {
        _logger.e('Error adding customer', error: e, stackTrace: st);
        throw Exception('Failed to add customer: $e');
      }
    });
  }

  Future<void> updateCustomer(CustomerEntity customer) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      try {
        final updated = customer.copyWith(
          updatedAt: DateTime.now(),
          isDirty: true,
        );

        final db = await $FloorAppDatabase.databaseBuilder('smartbill.db').build();
        await db.customerDao.updateOne(updated);

        // Trigger auto-sync
        final autoSync = AutoSyncService();
        await autoSync.syncNow();

        return await _loadCustomers();
      } catch (e, st) {
        _logger.e('Error updating customer', error: e, stackTrace: st);
        throw Exception('Failed to update customer: $e');
      }
    });
  }

  Future<void> deleteCustomer(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      try {
        final db = await $FloorAppDatabase.databaseBuilder('smartbill.db').build();
        await db.customerDao.softDelete(id, DateTime.now().millisecondsSinceEpoch);

        // Trigger auto-sync
        final autoSync = AutoSyncService();
        await autoSync.syncNow();

        return await _loadCustomers();
      } catch (e, st) {
        _logger.e('Error deleting customer', error: e, stackTrace: st);
        throw Exception('Failed to delete customer: $e');
      }
    });
  }

  Future<void> restoreCustomer(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      try {
        final db = await $FloorAppDatabase.databaseBuilder('smartbill.db').build();
        final customer = await db.customerDao.findById(id);
        
        if (customer != null) {
          final restored = customer.copyWith(
            isDeleted: false,
            deletedAtMillis: null,
            isDirty: true,
            updatedAt: DateTime.now(),
          );
          await db.customerDao.updateOne(restored);

          // Trigger auto-sync
          final autoSync = AutoSyncService();
          await autoSync.syncNow();
        }

        return await _loadCustomers();
      } catch (e, st) {
        _logger.e('Error restoring customer', error: e, stackTrace: st);
        throw Exception('Failed to restore customer: $e');
      }
    });
  }
}

/// Provider for customers state management
final customersProvider = AsyncNotifierProvider<CustomersNotifier, CustomersState>(
  CustomersNotifier.new,
);
