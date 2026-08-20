/// UserModel
/// Data class representing user profile info returned upon login.
class UserModel {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String role;
  final String? city;
  final String? shopName;
  final String? verificationStatus;
  final String? securityDepositStatus;
  final double? securityDepositAmount;
  final String? securityDepositProof;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    this.city,
    this.shopName,
    this.verificationStatus,
    this.securityDepositStatus,
    this.securityDepositAmount,
    this.securityDepositProof,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      role: json['role'] ?? '',
      city: json['city'],
      shopName: json['shop_name'],
      verificationStatus: json['verification_status'],
      securityDepositStatus: json['security_deposit_status'],
      securityDepositAmount: json['security_deposit_amount'] != null
          ? double.tryParse(json['security_deposit_amount'].toString())
          : null,
      securityDepositProof: json['security_deposit_proof'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'city': city,
      'shop_name': shopName,
      'verification_status': verificationStatus,
      'security_deposit_status': securityDepositStatus,
      'security_deposit_amount': securityDepositAmount,
      'security_deposit_proof': securityDepositProof,
    };
  }
}