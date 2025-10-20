import 'package:floor/floor.dart';

@entity
class InvoiceEntity {
  @primaryKey
  final String id;
  final String invoiceNumber;
  final String customerId;
  final double totalAmount;
  final String createdByUserId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? deletedAtMillis;
  final bool isDirty;
  final bool isDeleted;

  const InvoiceEntity({
    required this.id,
    required this.invoiceNumber,
    required this.customerId,
    required this.totalAmount,
    required this.createdByUserId,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAtMillis,
    this.isDirty = false,
    this.isDeleted = false,
  });
}

@entity
class InvoiceItemEntity {
  @primaryKey
  final String id;
  final String invoiceId;
  final String productId;
  final int quantity;
  final double unitPrice;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? deletedAtMillis;
  final bool isDirty;
  final bool isDeleted;

  const InvoiceItemEntity({
    required this.id,
    required this.invoiceId,
    required this.productId,
    required this.quantity,
    required this.unitPrice,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAtMillis,
    this.isDirty = false,
    this.isDeleted = false,
  });
}
