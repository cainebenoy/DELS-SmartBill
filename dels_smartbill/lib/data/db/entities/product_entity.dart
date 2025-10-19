import 'package:floor/floor.dart';

@entity
class ProductEntity {
  @primaryKey
  final String id;
  final String name;
  final String category;
  final double price;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? deletedAtMillis;
  final bool isDirty;
  final bool isDeleted;

  const ProductEntity({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAtMillis,
    this.isDirty = false,
    this.isDeleted = false,
  });
}
