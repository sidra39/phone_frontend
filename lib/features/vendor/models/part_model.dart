/// PartModel
/// Data model representing a mobile phone part listing.
class PartModel {
  final int id;
  final int vendorId;
  final int brandId;
  final int partTypeId;
  final String? brandName;
  final String? partTypeName;
  final String modelName;
  final double price;
  final String conditionType;
  final int stockQuantity;
  final String? imageUrl;
  final String status;
  final String? barcodeNumber;
  final String? originalPhotoUrl;
  final String? barcodePhotoUrl;

  PartModel({
    required this.id,
    required this.vendorId,
    required this.brandId,
    required this.partTypeId,
    this.brandName,
    this.partTypeName,
    required this.modelName,
    required this.price,
    required this.conditionType,
    required this.stockQuantity,
    this.imageUrl,
    required this.status,
    this.barcodeNumber,
    this.originalPhotoUrl,
    this.barcodePhotoUrl,
  });

  factory PartModel.fromJson(Map<String, dynamic> json) {
    return PartModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      vendorId: json['vendor_id'] is int ? json['vendor_id'] : int.parse(json['vendor_id'].toString()),
      brandId: json['brand_id'] is int ? json['brand_id'] : int.parse(json['brand_id'].toString()),
      partTypeId: json['part_type_id'] is int ? json['part_type_id'] : int.parse(json['part_type_id'].toString()),
      brandName: json['brand_name'],
      partTypeName: json['part_type_name'],
      modelName: json['model_name'] ?? '',
      price: json['price'] != null ? double.parse(json['price'].toString()) : 0.0,
      conditionType: json['condition_type'] ?? 'new',
      stockQuantity: json['stock_quantity'] is int ? json['stock_quantity'] : int.parse(json['stock_quantity'].toString()),
      imageUrl: json['image_url'],
      status: json['status'] ?? 'available',
      barcodeNumber: json['barcode_number'],
      originalPhotoUrl: json['original_photo_url'],
      barcodePhotoUrl: json['barcode_photo_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vendor_id': vendorId,
      'brand_id': brandId,
      'part_type_id': partTypeId,
      'brand_name': brandName,
      'part_type_name': partTypeName,
      'model_name': modelName,
      'price': price,
      'condition_type': conditionType,
      'stock_quantity': stockQuantity,
      'image_url': imageUrl,
      'status': status,
      'barcode_number': barcodeNumber,
      'original_photo_url': originalPhotoUrl,
      'barcode_photo_url': barcodePhotoUrl,
    };
  }
}