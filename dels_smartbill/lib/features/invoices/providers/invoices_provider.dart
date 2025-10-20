import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';
import '../../../data/db/app_database.dart';
import '../../../data/db/entities/invoice_entity.dart';
import '../../../data/db/entities/customer_entity.dart';
import '../../../services/auto_sync_service.dart';

/// Invoice with its items and related data
class InvoiceWithDetails {
  final InvoiceEntity invoice;
  final List<InvoiceItemEntity> items;
  final CustomerEntity? customer;

  const InvoiceWithDetails({
    required this.invoice,
    required this.items,
    this.customer,
  });

  double get total => items.fold(0, (sum, item) => sum + (item.quantity * item.unitPrice));
}

/// State class for managing invoices data
class InvoicesState {
  final List<InvoiceWithDetails> invoices;
  final String searchQuery;

  const InvoicesState({
    this.invoices = const [],
    this.searchQuery = '',
  });

  List<InvoiceWithDetails> get filteredInvoices {
    if (searchQuery.isEmpty) return invoices;
    final q = searchQuery.toLowerCase();
    return invoices.where((iwd) {
      return iwd.invoice.invoiceNumber.toLowerCase().contains(q) ||
          (iwd.customer?.name.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  InvoicesState copyWith({
    List<InvoiceWithDetails>? invoices,
    String? searchQuery,
  }) {
    return InvoicesState(
      invoices: invoices ?? this.invoices,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

/// Notifier for managing invoices state using AsyncNotifier pattern
class InvoicesNotifier extends AsyncNotifier<InvoicesState> {
  final _logger = Logger();
  final _uuid = const Uuid();

  @override
  Future<InvoicesState> build() async {
    return await _loadInvoices();
  }

  Future<InvoicesState> _loadInvoices() async {
    try {
      final db = await $FloorAppDatabase.databaseBuilder('smartbill.db').build();
      final invoices = await db.invoiceDao.search('%');
      
      // Load items and customer for each invoice
      final invoicesWithDetails = <InvoiceWithDetails>[];
      for (final invoice in invoices) {
        final items = await db.invoiceItemDao.byInvoice(invoice.id);
        final customer = await db.customerDao.findById(invoice.customerId);
        invoicesWithDetails.add(InvoiceWithDetails(
          invoice: invoice,
          items: items,
          customer: customer,
        ));
      }

      return InvoicesState(invoices: invoicesWithDetails);
    } catch (e, st) {
      _logger.e('Error loading invoices', error: e, stackTrace: st);
      throw Exception('Failed to load invoices: $e');
    }
  }

  Future<void> setSearchQuery(String query) async {
    state = await AsyncValue.guard(() async {
      final currentState = state.requireValue;
      return currentState.copyWith(searchQuery: query);
    });
  }

  Future<void> createInvoice({
    required String customerId,
    required List<InvoiceItemData> items,
    required String userId,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      try {
        final now = DateTime.now();
        final invoiceId = _uuid.v4();
        
        // Generate invoice number (format: INV-YYYYMMDD-XXXX)
        final dateStr = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
        final db = await $FloorAppDatabase.databaseBuilder('smartbill.db').build();
        final count = (await db.invoiceDao.countAll()) ?? 0;
        final invoiceNumber = 'INV-$dateStr-${(count + 1).toString().padLeft(4, '0')}';

        // Calculate total
        final total = items.fold<double>(0, (sum, item) => sum + (item.quantity * item.unitPrice));

        // Create invoice
        final invoice = InvoiceEntity(
          id: invoiceId,
          invoiceNumber: invoiceNumber,
          customerId: customerId,
          totalAmount: total,
          createdByUserId: userId,
          createdAt: now,
          updatedAt: now,
          isDirty: true,
        );

        await db.invoiceDao.insertOne(invoice);

        // Create invoice items
        for (final itemData in items) {
          final item = InvoiceItemEntity(
            id: _uuid.v4(),
            invoiceId: invoiceId,
            productId: itemData.productId,
            quantity: itemData.quantity,
            unitPrice: itemData.unitPrice,
            createdAt: now,
            updatedAt: now,
            isDirty: true,
          );
          await db.invoiceItemDao.insertOne(item);
        }

        // Trigger auto-sync
        final autoSync = AutoSyncService();
        await autoSync.syncNow();

        return await _loadInvoices();
      } catch (e, st) {
        _logger.e('Error creating invoice', error: e, stackTrace: st);
        throw Exception('Failed to create invoice: $e');
      }
    });
  }

  Future<void> deleteInvoice(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      try {
        final db = await $FloorAppDatabase.databaseBuilder('smartbill.db').build();
        final now = DateTime.now().millisecondsSinceEpoch;
        
        // Soft delete invoice
        await db.invoiceDao.softDelete(id, now);
        
        // Soft delete all items
        final items = await db.invoiceItemDao.byInvoice(id);
        for (final item in items) {
          await db.invoiceItemDao.softDelete(item.id, now);
        }

        // Trigger auto-sync
        final autoSync = AutoSyncService();
        await autoSync.syncNow();

        return await _loadInvoices();
      } catch (e, st) {
        _logger.e('Error deleting invoice', error: e, stackTrace: st);
        throw Exception('Failed to delete invoice: $e');
      }
    });
  }
}

/// Data class for creating invoice items
class InvoiceItemData {
  final String productId;
  final int quantity;
  final double unitPrice;

  const InvoiceItemData({
    required this.productId,
    required this.quantity,
    required this.unitPrice,
  });
}

/// Provider for invoices state management
final invoicesProvider = AsyncNotifierProvider<InvoicesNotifier, InvoicesState>(
  InvoicesNotifier.new,
);
