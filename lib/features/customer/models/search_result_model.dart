/// SearchResultModel
/// Data model representing a part search result with part details, vendor info, and average rating.
class SearchResultModel {
  final int id;
  final String modelName;
  final double price;
  final String conditionType;
  final int stockQuantity;
  final String? imageUrl;
  final String status;
  final int vendorId;
  final String shopName;
  final String vendorCity;
  final String vendorAddress;
  final String? brandName;
  final String? partTypeName;
  final double averageRating;
  final int reviewCount;

  SearchResultModel({
    required this.id,
    required this.modelName,
    required this.price,
    required this.conditionType,
    required this.stockQuantity,
    this.imageUrl,
    required this.status,
    required this.vendorId,
    required this.shopName,
    required this.vendorCity,
    required this.vendorAddress,
    this.brandName,
    this.partTypeName,
    required this.averageRating,
    required this.reviewCount,
  });

  factory SearchResultModel.fromJson(Map<String, dynamic> json) {
    return SearchResultModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      modelName: json['model_name'] ?? '',
      price: json['price'] != null ? double.parse(json['price'].toString()) : 0.0,
      conditionType: json['condition_type'] ?? 'new',
      stockQuantity: json['stock_quantity'] is int
          ? json['stock_quantity']
          : int.parse((json['stock_quantity'] ?? 0).toString()),
      imageUrl: json['image_url'],
      status: json['status'] ?? 'available',
      vendorId: json['vendor_id'] is int ? json['vendor_id'] : int.parse(json['vendor_id'].toString()),
      shopName: json['shop_name'] ?? '',
      vendorCity: json['vendor_city'] ?? '',
      vendorAddress: json['vendor_address'] ?? '',
      brandName: json['brand_name'],
      partTypeName: json['part_type_name'],
      averageRating: json['average_rating'] != null ? double.parse(json['average_rating'].toString()) : 0.0,
      reviewCount: json['review_count'] is int
          ? json['review_count']
          : int.parse((json['review_count'] ?? 0).toString()),
    );
  }
}