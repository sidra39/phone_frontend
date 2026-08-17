/// VendorAdminModel
/// Data model representing a vendor with linked user owner account details for admin management.
class VendorAdminModel {
  final int id;
  final int userId;
  final String shopName;
  final String city;
  final String address;
  final String verificationStatus;
  final String ownerName;
  final String email;
  final String? phone;

  VendorAdminModel({
    required this.id,
    required this.userId,
    required this.shopName,
    required this.city,
    required this.address,
    required this.verificationStatus,
    required this.ownerName,
    required this.email,
    this.phone,
  });

  factory VendorAdminModel.fromJson(Map<String, dynamic> json) {
    return VendorAdminModel(
      id: json['vendor_id'] is int ? json['vendor_id'] : int.parse(json['vendor_id'].toString()),
      userId: json['user_id'] is int ? json['user_id'] : int.parse(json['user_id'].toString()),
      shopName: json['shop_name'] ?? '',
      city: json['city'] ?? '',
      address: json['address'] ?? '',
      verificationStatus: json['verification_status'] ?? 'pending',
      ownerName: json['owner_name'] ?? '',
      email: json['owner_email'] ?? '',
      phone: json['owner_phone'],
    );
  }
}