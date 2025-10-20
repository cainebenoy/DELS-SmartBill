import 'package:floor/floor.dart';

@entity
class CustomerEntity {
  @primaryKey
  final String id;
  final String name;
  final String phone;
  final String email;
  final String address;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? deletedAtMillis;
  final bool isDirty;
  final bool isDeleted;

  const CustomerEntity({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.address,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAtMillis,
    this.isDirty = false,
    this.isDeleted = false,
  });
}
