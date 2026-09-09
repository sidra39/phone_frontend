/// CommissionModel
/// Data model for vendor commission payment obligations and proof verification status.
class CommissionModel {
  final int id;
  final int requestId;
  final double amount;
  final String status;
  final String? paymentProofUrl;
  final String? partModelName;
  final double? partPrice;
  final String? vendorShopName;

  CommissionModel({
    required this.id,
    required this.requestId,
    required this.amount,
    required this.status,
    this.paymentProofUrl,
    this.partModelName,
    this.partPrice,
    this.vendorShopName,
  });

  factory CommissionModel.fromJson(Map<String, dynamic> json) {
    return CommissionModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      requestId: json['request_id'] is int ? json['request_id'] : int.parse(json['request_id'].toString()),
      amount: json['amount'] != null ? double.parse(json['amount'].toString()) : 0.0,
      status: json['status'] ?? 'pending',
      paymentProofUrl: json['payment_proof_url'],
      partModelName: json['model_name'],
      partPrice: json['part_price'] != null ? double.parse(json['part_price'].toString()) : null,
      vendorShopName: json['shop_name'],
    );
  }
}
