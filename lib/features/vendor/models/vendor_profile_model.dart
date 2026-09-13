/// VendorProfileModel
/// Data model representing detailed vendor shop profile information.
class VendorProfileModel {
  final int id;
  final int userId;
  final String shopName;
  final String city;
  final String address;
  final double? latitude;
  final double? longitude;
  final String verificationStatus;

  VendorProfileModel({
    required this.id,
    required this.userId,
    required this.shopName,
    required this.city,
    required this.address,
    this.latitude,
    this.longitude,
    required this.verificationStatus,
  });

  factory VendorProfileModel.fromJson(Map<String, dynamic> json) {
    return VendorProfileModel(
      id: json['vendor_id'] ?? (json['id'] is int ? json['id'] : int.parse(json['id'].toString())),
      userId: json['user_id'] is int
          ? json['user_id']
          : (json['id'] is int ? json['id'] : int.parse(json['id'].toString())),
      shopName: json['shop_name'] ?? '',
      city: json['city'] ?? '',
      address: json['address'] ?? '',
      latitude: json['latitude'] != null ? double.tryParse(json['latitude'].toString()) : null,
      longitude: json['longitude'] != null ? double.tryParse(json['longitude'].toString()) : null,
      verificationStatus: json['verification_status'] ?? 'pending',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'shop_name': shopName,
      'city': city,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'verification_status': verificationStatus,
    };
  }
}
