import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/services/auth_provider.dart';
import '../models/user_admin_model.dart';
import '../services/admin_service.dart';

/// UserManagementScreen
/// Allows admins to view registered users, filter by role, and toggle account status between active and blocked.
class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final AdminService _adminService = AdminService();
  String _selectedRole = 'all';
  List<UserAdminModel> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) return;

    setState(() => _isLoading = true);

    try {
      final list = await _adminService.getAllUsers(token, roleFilter: _selectedRole);
      setState(() {
        _users = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        final msg = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _handleBlockToggle(UserAdminModel user) async {
    final bool isBlocking = user.status.toLowerCase() == 'active';
    final actionName = isBlocking ? 'Block' : 'Unblock';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xff1A1D27),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('$actionName Account Access', style: const TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to $actionName user "${user.name}"?',
          style: const TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isBlocking ? const Color(0xffFF5252) : const Color(0xff00E676),
            ),
            child: Text(
              actionName,
              style: TextStyle(
                color: isBlocking ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;

    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) return;

    try {
      if (isBlocking) {
        await _adminService.blockUser(token, user.id);
      } else {
        await _adminService.unblockUser(token, user.id);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User "${user.name}" $actionName\'d successfully')),
        );
        _loadUsers();
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
      }
    }
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return const Color(0xff00E5FF);
      case 'vendor':
        return const Color(0xff7C4DFF);
      case 'customer':
      default:
        return const Color(0xff00E676);
    }
  }

  Color _getStatusColor(String status) {
    return status.toLowerCase() == 'active' ? const Color(0xff00E676) : const Color(0xffFF5252);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff12141C),
      body: Column(
        children: [
          // Cyber Segment Filter Bar
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: const BoxDecoration(
              color: Color(0xff1A1D27),
              border: Border(bottom: BorderSide(color: Color(0xff2A2E3D))),
            ),
            child: Row(
              children: [
                const Icon(Icons.group_work_rounded, color: Color(0xff00E676), size: 20),
                const SizedBox(width: 10),
                const Text('Role Filter:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xff12141C),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xff2A2E3D)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedRole,
                        dropdownColor: const Color(0xff1A1D27),
                        isExpanded: true,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('All Account Roles')),
                          DropdownMenuItem(value: 'customer', child: Text('Customers Only')),
                          DropdownMenuItem(value: 'vendor', child: Text('Vendors Only')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedRole = val);
                            _loadUsers();
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // User Cards List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _users.isEmpty
                    ? const Center(
                        child: Text(
                          'No users found for selected filter',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadUsers,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16.0),
                          itemCount: _users.length,
                          itemBuilder: (context, index) {
                            final user = _users[index];
                            final bool isActive = user.status.toLowerCase() == 'active';
                            final roleColor = _getRoleColor(user.role);
                            final statusColor = _getStatusColor(user.status);

                            return Container(
                              margin: const EdgeInsets.only(bottom: 14.0),
                              padding: const EdgeInsets.all(16.0),
                              decoration: BoxDecoration(
                                color: const Color(0xff1A1D27),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xff2A2E3D)),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 22,
                                    backgroundColor: roleColor.withValues(alpha: 0.15),
                                    child: Icon(
                                      user.role == 'vendor'
                                          ? Icons.storefront_rounded
                                          : user.role == 'admin'
                                              ? Icons.admin_panel_settings_rounded
                                              : Icons.person_rounded,
                                      color: roleColor,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 14),

                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              user.name,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: roleColor.withValues(alpha: 0.15),
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(color: roleColor.withValues(alpha: 0.5)),
                                              ),
                                              child: Text(
                                                user.role.toUpperCase(),
                                                style: TextStyle(
                                                  color: roleColor,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 10,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(user.email, style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
                                        if (user.phone != null && user.phone!.isNotEmpty)
                                          Text('Phone: ${user.phone}', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: statusColor.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                                        ),
                                        child: Text(
                                          user.status.toUpperCase(),
                                          style: TextStyle(
                                            color: statusColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      if (user.role != 'admin')
                                        InkWell(
                                          onTap: () => _handleBlockToggle(user),
                                          borderRadius: BorderRadius.circular(8),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                            decoration: BoxDecoration(
                                              color: isActive
                                                  ? const Color(0xffFF5252).withValues(alpha: 0.15)
                                                  : const Color(0xff00E676).withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(
                                                color: isActive
                                                    ? const Color(0xffFF5252).withValues(alpha: 0.5)
                                                    : const Color(0xff00E676).withValues(alpha: 0.5),
                                              ),
                                            ),
                                            child: Text(
                                              isActive ? 'Block' : 'Unblock',
                                              style: TextStyle(
                                                color: isActive ? const Color(0xffFF5252) : const Color(0xff00E676),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
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
}
