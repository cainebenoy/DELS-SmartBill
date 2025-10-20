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

  CustomerEntity copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? address,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? deletedAtMillis,
    bool? isDirty,
    bool? isDeleted,
  }) {
    return CustomerEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAtMillis: deletedAtMillis ?? this.deletedAtMillis,
      isDirty: isDirty ?? this.isDirty,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}
