/// BrowsePartModel
/// Data model representing a publicly listed phone part in the marketplace.
class BrowsePartModel {
  final int id;
  final String modelName;
  final double price;
  final String conditionType;
  final String? imageUrl;
  final String? originalPhotoUrl;
  final String? barcodePhotoUrl;
  final String? barcodeNumber;
  final int? brandId;
  final String? brandName;
  final int? partTypeId;
  final String? partTypeName;
  final int vendorId;
  final String shopName;
  final String vendorCity;
  final String vendorAddress;
  final double averageRating;
  final int reviewCount;

  BrowsePartModel({
    required this.id,
    required this.modelName,
    required this.price,
    required this.conditionType,
    this.imageUrl,
    this.originalPhotoUrl,
    this.barcodePhotoUrl,
    this.barcodeNumber,
    this.brandId,
    this.brandName,
    this.partTypeId,
    this.partTypeName,
    required this.vendorId,
    required this.shopName,
    required this.vendorCity,
    required this.vendorAddress,
    required this.averageRating,
    required this.reviewCount,
  });

  factory BrowsePartModel.fromJson(Map<String, dynamic> json) {
    return BrowsePartModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      modelName: json['model_name'] ?? '',
      price: json['price'] != null ? double.parse(json['price'].toString()) : 0.0,
      conditionType: json['condition_type'] ?? 'new',
      imageUrl: json['original_photo_url'] ?? json['image_url'],
      originalPhotoUrl: json['original_photo_url'],
      barcodePhotoUrl: json['barcode_photo_url'],
      barcodeNumber: json['barcode_number'],
      brandId: json['brand_id'] is int ? json['brand_id'] : (json['brand_id'] != null ? int.parse(json['brand_id'].toString()) : null),
      brandName: json['brand_name'],
      partTypeId: json['part_type_id'] is int ? json['part_type_id'] : (json['part_type_id'] != null ? int.parse(json['part_type_id'].toString()) : null),
      partTypeName: json['part_type_name'],
      vendorId: json['vendor_id'] is int ? json['vendor_id'] : int.parse((json['vendor_id'] ?? 0).toString()),
      shopName: json['shop_name'] ?? '',
      vendorCity: json['vendor_city'] ?? json['city'] ?? '',
      vendorAddress: json['vendor_address'] ?? json['address'] ?? '',
      averageRating: json['average_rating'] != null ? double.parse(json['average_rating'].toString()) : 0.0,
      reviewCount: json['review_count'] is int ? json['review_count'] : int.parse((json['review_count'] ?? 0).toString()),
    );
  }
}