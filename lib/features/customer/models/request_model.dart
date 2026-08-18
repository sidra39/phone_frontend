/// RequestModel
/// Data model representing a customer's part request, including vendor & part summary details.
class RequestModel {
  final int id;
  final int partId;
  final int vendorId;
  final int? vendorUserId;
  final int sequenceNumber;
  final bool isLocked;
  final String status;
  final String createdAt;
  final String modelName;
  final double price;
  final String? imageUrl;
  final String shopName;
  final String vendorCity;
  final String vendorAddress;
  final String? brandName;
  final String? partTypeName;
  final String deliveryType;
  final String? deliveryAddress;
  final String? deliveryCity;
  final String? deliveryPhone;
  final String? deliveryNotes;
  final String? cancellationReason;
  final String? cancelledBy;
  final String? cancelledAt;

  RequestModel({
    required this.id,
    required this.partId,
    required this.vendorId,
    this.vendorUserId,
    required this.sequenceNumber,
    required this.isLocked,
    required this.status,
    required this.createdAt,
    required this.modelName,
    required this.price,
    this.imageUrl,
    required this.shopName,
    required this.vendorCity,
    required this.vendorAddress,
    this.brandName,
    this.partTypeName,
    this.deliveryType = 'shop_pickup',
    this.deliveryAddress,
    this.deliveryCity,
    this.deliveryPhone,
    this.deliveryNotes,
    this.cancellationReason,
    this.cancelledBy,
    this.cancelledAt,
  });

  factory RequestModel.fromJson(Map<String, dynamic> json) {
    return RequestModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      partId: json['part_id'] is int ? json['part_id'] : int.parse(json['part_id'].toString()),
      vendorId: json['vendor_id'] is int ? json['vendor_id'] : int.parse(json['vendor_id'].toString()),
      vendorUserId: json['vendor_user_id'] != null
          ? (json['vendor_user_id'] is int ? json['vendor_user_id'] : int.tryParse(json['vendor_user_id'].toString()))
          : null,
      sequenceNumber: json['sequence_number'] is int
          ? json['sequence_number']
          : int.parse((json['sequence_number'] ?? 1).toString()),
      isLocked: json['is_locked'] == 1 || json['is_locked'] == true,
      status: json['status'] ?? 'requested',
      createdAt: json['created_at'] ?? '',
      modelName: json['model_name'] ?? 'Part #${json['part_id']}',
      price: json['price'] != null ? double.parse(json['price'].toString()) : 0.0,
      imageUrl: json['image_url'],
      shopName: json['shop_name'] ?? 'Vendor #${json['vendor_id']}',
      vendorCity: json['vendor_city'] ?? '',
      vendorAddress: json['vendor_address'] ?? '',
      brandName: json['brand_name'],
      partTypeName: json['part_type_name'],
      deliveryType: json['delivery_type'] ?? 'shop_pickup',
      deliveryAddress: json['delivery_address'],
      deliveryCity: json['delivery_city'],
      deliveryPhone: json['delivery_phone'],
      deliveryNotes: json['delivery_notes'],
      cancellationReason: json['cancellation_reason'],
      cancelledBy: json['cancelled_by'],
      cancelledAt: json['cancelled_at'],
    );
  }
}
