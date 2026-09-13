import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/services/auth_provider.dart';
import '../services/admin_service.dart';

/// AdminNotificationCenterScreen
/// Enables System Admins to audit all system notifications across all users,
/// filter by role, and send broadcast announcements directly to users or groups.
class AdminNotificationCenterScreen extends StatefulWidget {
  const AdminNotificationCenterScreen({super.key});

  @override
  State<AdminNotificationCenterScreen> createState() => _AdminNotificationCenterScreenState();
}

class _AdminNotificationCenterScreenState extends State<AdminNotificationCenterScreen> {
  final AdminService _adminService = AdminService();
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _notifications = [];
  String _selectedFilter = 'all'; // 'all', 'vendor', 'customer'

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) {
      setState(() {
        _errorMessage = 'Authentication token missing. Please log in again.';
        _isLoading = false;
      });
      return;
    }

    try {
      final notifs = await _adminService.getAllNotifications(token);
      if (mounted) {
        setState(() {
          _notifications = notifs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> get _filteredNotifications {
    if (_selectedFilter == 'all') return _notifications;
    return _notifications.where((n) {
      final role = (n['user_role'] ?? '').toString().toLowerCase();
      return role == _selectedFilter;
    }).toList();
  }

  void _showBroadcastDialog() {
    final messageController = TextEditingController();
    final userIdController = TextEditingController();
    String targetAudience = 'all'; // 'all', 'vendor', 'customer', 'user'
    String notifType = 'system';
    bool isSending = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Icon(Icons.campaign_rounded, color: Color(0xff00E676)),
                  SizedBox(width: 10),
                  Text('Send System Broadcast', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Target Audience:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: targetAudience,
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('🌐 All Users (Vendors & Customers)')),
                        DropdownMenuItem(value: 'vendor', child: Text('🏪 All Registered Vendors')),
                        DropdownMenuItem(value: 'customer', child: Text('🛒 All Customer Accounts')),
                        DropdownMenuItem(value: 'user', child: Text('👤 Specific User (By User ID)')),
                      ],
                      onChanged: (val) {
                        if (val != null) setDialogState(() => targetAudience = val);
                      },
                    ),
                    if (targetAudience == 'user') ...[
                      const SizedBox(height: 12),
                      const Text('User ID:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: userIdController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'Enter User ID (e.g. 5)',
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    const Text('Notification Type:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: notifType,
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'system', child: Text('⚠️ System Alert / Notice')),
                        DropdownMenuItem(value: 'request', child: Text('📦 Request Update')),
                        DropdownMenuItem(value: 'commission', child: Text('💳 Commission Notice')),
                        DropdownMenuItem(value: 'response', child: Text('💬 General Response')),
                      ],
                      onChanged: (val) {
                        if (val != null) setDialogState(() => notifType = val);
                      },
                    ),
                    const SizedBox(height: 14),
                    const Text('Notification Message:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: messageController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Enter broadcast announcement text...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSending ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton.icon(
                  icon: isSending
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                      : const Icon(Icons.send_rounded, size: 18),
                  label: Text(isSending ? 'Sending...' : 'Broadcast Now'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff00E676),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: isSending
                      ? null
                      : () async {
                          final msg = messageController.text.trim();
                          if (msg.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please enter a message text.')),
                            );
                            return;
                          }

                          setDialogState(() => isSending = true);

                          final token = Provider.of<AuthProvider>(context, listen: false).token;
                          if (token == null) return;

                          try {
                            final Map<String, dynamic> payload = {
                              'message': msg,
                              'type': notifType,
                            };
                            if (targetAudience == 'user') {
                              final uid = int.tryParse(userIdController.text.trim());
                              if (uid == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Please enter a valid numeric User ID.')),
                                );
                                setDialogState(() => isSending = false);
                                return;
                              }
                              payload['target_user_id'] = uid;
                            } else {
                              payload['target_role'] = targetAudience;
                            }

                            await _adminService.broadcastNotification(token, payload);
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('✅ Broadcast notification sent successfully!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              _loadNotifications();
                            }
                          } catch (err) {
                            setDialogState(() => isSending = false);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: ${err.toString()}')),
                              );
                            }
                          }
                        },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          // Header Card with Actions
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              border: const Border(bottom: BorderSide(color: Color(0xffCCCCCC), width: 1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Notification Oversight & Logs',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Total System Logs: ${_notifications.length}',
                          style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: _showBroadcastDialog,
                      icon: const Icon(Icons.campaign_rounded, size: 18),
                      label: const Text('Send Broadcast'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff00E676),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('all', 'All Notifications (${_notifications.length})'),
                      const SizedBox(width: 8),
                      _buildFilterChip('vendor', 'Vendors'),
                      const SizedBox(width: 8),
                      _buildFilterChip('customer', 'Customers'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Main Body Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline_rounded, color: Colors.red, size: 48),
                            const SizedBox(height: 12),
                            Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14)),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _loadNotifications,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _filteredNotifications.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.notifications_off_outlined, size: 56, color: Colors.grey),
                                SizedBox(height: 12),
                                Text('No notification logs found.', style: TextStyle(fontSize: 16, color: Colors.grey)),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadNotifications,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _filteredNotifications.length,
                              itemBuilder: (context, index) {
                                final notif = _filteredNotifications[index];
                                final role = (notif['user_role'] ?? 'user').toString().toUpperCase();
                                final name = notif['user_name'] ?? 'User #${notif['user_id']}';
                                final email = notif['user_email'] ?? '';
                                final message = notif['message'] ?? '';
                                final type = (notif['type'] ?? 'system').toString().toUpperCase();
                                final isRead = notif['is_read'] == true || notif['is_read'] == 1;
                                final dateStr = notif['created_at'] != null ? notif['created_at'].toString().split('T')[0] : 'Just now';

                                Color roleColor = Colors.blue;
                                if (role == 'VENDOR') roleColor = Colors.orange;
                                if (role == 'ADMIN') roleColor = Colors.purple;

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 1,
                                  child: Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: roleColor.withValues(alpha: 0.15),
                                                    borderRadius: BorderRadius.circular(6),
                                                    border: Border.all(color: roleColor.withValues(alpha: 0.4)),
                                                  ),
                                                  child: Text(
                                                    role,
                                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: roleColor),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  name,
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                                ),
                                              ],
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.grey.withValues(alpha: 0.15),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                type,
                                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey),
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (email.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            email,
                                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                                          ),
                                        ],
                                        const Divider(height: 16),
                                        Text(
                                          message,
                                          style: const TextStyle(fontSize: 13, height: 1.4),
                                        ),
                                        const SizedBox(height: 10),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Sent: $dateStr',
                                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                                            ),
                                            Row(
                                              children: [
                                                Icon(
                                                  isRead ? Icons.mark_email_read_rounded : Icons.mark_email_unread_rounded,
                                                  size: 14,
                                                  color: isRead ? Colors.green : Colors.amber.shade800,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  isRead ? 'Read by user' : 'Unread',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    color: isRead ? Colors.green : Colors.amber.shade800,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      selected: isSelected,
      label: Text(label),
      selectedColor: const Color(0xff00E676).withValues(alpha: 0.2),
      checkmarkColor: Colors.black,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? Colors.black : Colors.grey.shade700,
      ),
      onSelected: (_) {
        setState(() => _selectedFilter = value);
      },
    );
  }
}
