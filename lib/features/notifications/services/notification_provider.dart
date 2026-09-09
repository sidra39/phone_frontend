import 'dart:async';
import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import 'notification_service.dart';

/// NotificationProvider
/// Manages polling timer, unread badge count, and notification list state.
class NotificationProvider extends ChangeNotifier {
  final NotificationService _service;

  Timer? _pollingTimer;
  int _unreadCount = 0;
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;

  NotificationProvider({NotificationService? service})
      : _service = service ?? NotificationService();

  int get unreadCount => _unreadCount;
  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;

  /// Starts periodic polling timer (30-second interval) to update unread badge count
  void startPolling(String token) {
    stopPolling(); // Cancel any previous timer
    _updateUnreadCount(token); // Initial fetch immediately

    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _updateUnreadCount(token);
    });
  }

  /// Cancels polling timer (e.g. on logout)
  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _unreadCount = 0;
    _notifications = [];
    notifyListeners();
  }

  Future<void> _updateUnreadCount(String token) async {
    try {
      final count = await _service.getUnreadCount(token);
      _unreadCount = count;
      notifyListeners();
    } catch (_) {
      // Ignore network errors during background polling
    }
  }

  /// Fetches full notifications list for notifications screen
  Future<void> fetchNotifications(String token) async {
    _isLoading = true;
    notifyListeners();

    try {
      final list = await _service.getMyNotifications(token);
      _notifications = list;
      await _updateUnreadCount(token);
    } catch (_) {
      // Handle error in screen UI
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Marks a single notification as read
  Future<void> markRead(String token, int id) async {
    try {
      await _service.markAsRead(token, id);
      await fetchNotifications(token);
    } catch (_) {}
  }

  /// Marks all notifications as read
  Future<void> markAllRead(String token) async {
    try {
      await _service.markAllAsRead(token);
      await fetchNotifications(token);
    } catch (_) {}
  }
}
