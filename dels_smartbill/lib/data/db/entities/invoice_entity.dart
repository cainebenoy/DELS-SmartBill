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

  InvoiceEntity copyWith({
    String? id,
    String? invoiceNumber,
    String? customerId,
    double? totalAmount,
    String? createdByUserId,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? deletedAtMillis,
    bool? isDirty,
    bool? isDeleted,
  }) {
    return InvoiceEntity(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      customerId: customerId ?? this.customerId,
      totalAmount: totalAmount ?? this.totalAmount,
      createdByUserId: createdByUserId ?? this.createdByUserId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAtMillis: deletedAtMillis ?? this.deletedAtMillis,
      isDirty: isDirty ?? this.isDirty,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
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

  InvoiceItemEntity copyWith({
    String? id,
    String? invoiceId,
    String? productId,
    int? quantity,
    double? unitPrice,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? deletedAtMillis,
    bool? isDirty,
    bool? isDeleted,
  }) {
    return InvoiceItemEntity(
      id: id ?? this.id,
      invoiceId: invoiceId ?? this.invoiceId,
      productId: productId ?? this.productId,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAtMillis: deletedAtMillis ?? this.deletedAtMillis,
      isDirty: isDirty ?? this.isDirty,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}
