import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/services/auth_provider.dart';
import '../services/notification_provider.dart';

/// NotificationsScreen
/// Displays in-app notifications with type icons, read indicators, and bulk mark-read actions.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadNotifications();
    });
  }

  void _loadNotifications() {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token != null) {
      Provider.of<NotificationProvider>(context, listen: false).fetchNotifications(token);
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'request':
        return Icons.list_alt;
      case 'commission':
        return Icons.payment;
      case 'response':
        return Icons.question_answer;
      case 'system':
      default:
        return Icons.notifications;
    }
  }

  String _formatTime(String rawDate) {
    if (rawDate.isEmpty) return '';
    try {
      final dt = DateTime.parse(rawDate);
      final diff = DateTime.now().difference(dt);

      if (diff.inSeconds < 60) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final token = Provider.of<AuthProvider>(context).token;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: token == null
                ? null
                : () {
                    Provider.of<NotificationProvider>(context, listen: false).markAllRead(token);
                  },
            child: const Text('Mark all as read'),
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, notifProvider, child) {
          if (notifProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final notifications = notifProvider.notifications;

          if (notifications.isEmpty) {
            return const Center(
              child: Text(
                'No notifications yet',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _loadNotifications(),
            child: ListView.builder(
              padding: const EdgeInsets.all(12.0),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notif = notifications[index];
                final bool isUnread = !notif.isRead;

                return Card(
                  margin: const EdgeInsets.only(bottom: 8.0),
                  color: isUnread ? Colors.grey.shade900 : Theme.of(context).cardColor,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    leading: CircleAvatar(
                      backgroundColor: isUnread ? Colors.white24 : Colors.white10,
                      child: Icon(_getTypeIcon(notif.type), color: Colors.white),
                    ),
                    title: Text(
                      notif.message,
                      style: TextStyle(
                        fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6.0),
                      child: Text(
                        _formatTime(notif.createdAt),
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                      ),
                    ),
                    trailing: isUnread
                        ? Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: Colors.redAccent,
                              shape: BoxShape.circle,
                            ),
                          )
                        : null,
                    onTap: isUnread && token != null
                        ? () {
                            notifProvider.markRead(token, notif.id);
                          }
                        : null,
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
