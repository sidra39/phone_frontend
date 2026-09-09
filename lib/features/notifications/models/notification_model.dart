/// NotificationModel
/// Data model representing an in-app notification item.
class NotificationModel {
  final int id;
  final String message;
  final String type; // 'request', 'commission', 'response', 'system'
  final bool isRead;
  final String createdAt;

  NotificationModel({
    required this.id,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      message: json['message'] ?? '',
      type: json['type'] ?? 'system',
      isRead: json['is_read'] == 1 || json['is_read'] == true,
      createdAt: json['created_at'] ?? '',
    );
  }
}
