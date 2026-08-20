/// ReportModel
/// Data model representing a complaint report item.
class ReportModel {
  final int id;
  final String reason;
  final String description;
  final String status; // 'pending', 'resolved', 'dismissed'
  final int? requestId;
  final String? reporterName;
  final String? reportedName;
  final String createdAt;

  ReportModel({
    required this.id,
    required this.reason,
    required this.description,
    required this.status,
    this.requestId,
    this.reporterName,
    this.reportedName,
    required this.createdAt,
  });

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      reason: json['reason'] ?? '',
      description: json['description'] ?? '',
      status: json['status'] ?? 'pending',
      requestId: json['request_id'] != null
          ? (json['request_id'] is int ? json['request_id'] : int.tryParse(json['request_id'].toString()))
          : null,
      reporterName: json['reporter_name'],
      reportedName: json['reported_name'] ?? json['reported_user_name'],
      createdAt: json['created_at'] ?? '',
    );
  }
}