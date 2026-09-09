<<<<<<< HEAD
/// UserAdminModel
/// Data model representing a user account for admin user management.
class UserAdminModel {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String role;
  final String status;

  UserAdminModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    required this.status,
  });

  factory UserAdminModel.fromJson(Map<String, dynamic> json) {
    return UserAdminModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      role: json['role'] ?? 'customer',
      status: json['status'] ?? 'active',
    );
  }
}
=======

>>>>>>> 933e2ef9672b79d50dcca3f1bc1666d87b0e4a02
