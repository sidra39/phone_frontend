/// LeadRequestModel
/// Data model representing a customer request received by a vendor, with lead locking parameters.
class LeadRequestModel {
  final int id;
  final String status;
  final bool isLocked;
  final String? lockMessage;
  final int? customerUserId;
  final String? customerName;
  final String? customerPhone;
  final String? customerEmail;
  final String? customerCity;
  final String partModelName;
  final double partPrice;

  LeadRequestModel({
    required this.id,
    required this.status,
    required this.isLocked,
    this.lockMessage,
    this.customerUserId,
    this.customerName,
    this.customerPhone,
    this.customerEmail,
    this.customerCity,
    required this.partModelName,
    required this.partPrice,
  });

  factory LeadRequestModel.fromJson(Map<String, dynamic> json) {
    return LeadRequestModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      status: json['status'] ?? 'requested',
      isLocked: json['is_locked'] == 1 || json['is_locked'] == true,
      lockMessage: json['message'],
      customerUserId: json['customer_user_id'] != null
          ? (json['customer_user_id'] is int ? json['customer_user_id'] : int.tryParse(json['customer_user_id'].toString()))
          : null,
      customerName: json['customer_name'],
      customerPhone: json['customer_phone'],
      customerEmail: json['customer_email'],
      customerCity: json['customer_city'],
      partModelName: json['model_name'] ?? 'Part #${json['part_id']}',
      partPrice: json['price'] != null ? double.parse(json['price'].toString()) : 0.0,
    );
  }
}
