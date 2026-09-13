import '../../../core/network/api_client.dart';
import '../models/notification_model.dart';

/// NotificationService
/// Handles HTTP communications for user notification endpoints.
class NotificationService {
  final ApiClient _apiClient;

  NotificationService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// Fetches all notifications for the authenticated user
  Future<List<NotificationModel>> getMyNotifications(String token) async {
    final response = await _apiClient.get('/notifications', token: token);
    final List list = response['data'] ?? [];
    return list.map((item) => NotificationModel.fromJson(item)).toList();
  }

  /// Gets unread notification count
  Future<int> getUnreadCount(String token) async {
    final response = await _apiClient.get('/notifications/unread-count', token: token);
    final data = response['data'];
    return data != null && data['count'] != null ? data['count'] as int : 0;
  }

  /// Marks a single notification as read
  Future<void> markAsRead(String token, int id) async {
    await _apiClient.put('/notifications/$id/read', {}, token: token);
  }

  /// Marks all notifications for user as read
  Future<void> markAllAsRead(String token) async {
    await _apiClient.put('/notifications/read-all', {}, token: token);
  }
}
