import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/notification_bell_icon.dart';
import '../../auth/screens/login_screen.dart';
import '../../auth/services/auth_provider.dart';
import '../../notifications/services/notification_provider.dart';
import 'category_management_screen.dart';
import 'commission_review_screen.dart';
import 'dashboard_stats_screen.dart';
import 'report_review_screen.dart';
import 'user_management_screen.dart';
import 'vendor_management_screen.dart';

/// AdminDashboardScreen
/// Premium shell for administrative control featuring a cyber-sleek Drawer navigation menu across all 6 sections.
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _currentIndex = 0;

  final List<String> _titles = const [
    'Admin Overview',
    'Vendor Management',
    'User Directory',
    'Category Management',
    'Commission Review',
    'Reports & Complaints',
  ];

  final List<Widget> _screens = const [
    DashboardStatsScreen(),
    VendorManagementScreen(),
    UserManagementScreen(),
    CategoryManagementScreen(),
    CommissionReviewScreen(),
    ReportReviewScreen(),
  ];

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required int index,
    required Color accentColor,
  }) {
    final isSelected = _currentIndex == index;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            setState(() => _currentIndex = index);
            Navigator.pop(context);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: isSelected
                  ? accentColor.withValues(alpha: 0.15)
                  : Colors.transparent,
              border: isSelected
                  ? Border.all(color: accentColor.withValues(alpha: 0.5), width: 1)
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected ? accentColor : Colors.grey.shade400,
                  size: 22,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? Colors.white : Colors.grey.shade300,
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accentColor,
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withValues(alpha: 0.8),
                          blurRadius: 6,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).currentUser;

    return Scaffold(
      backgroundColor: const Color(0xff12141C),
      appBar: AppBar(
        backgroundColor: const Color(0xff1A1D27),
        elevation: 0,
        centerTitle: false,
        title: Text(
          _titles[_currentIndex],
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 8.0),
            child: NotificationBellIcon(),
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: const Color(0xff161822),
        child: Column(
          children: [
            // Modern Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 50, bottom: 20, left: 20, right: 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xff1F2332), Color(0xff161822)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                border: Border(
                  bottom: BorderSide(color: Color(0xff2A2E3D), width: 1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xff00E5FF), Color(0xff7C4DFF)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xff00E5FF).withValues(alpha: 0.3),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const CircleAvatar(
                          radius: 28,
                          backgroundColor: Color(0xff1A1D27),
                          child: Icon(Icons.admin_panel_settings, size: 30, color: Color(0xff00E5FF)),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.name ?? 'Super Admin',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xff00E5FF).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xff00E5FF).withValues(alpha: 0.5)),
                              ),
                              child: const Text(
                                'SYSTEM ADMIN',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xff00E5FF),
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user?.email ?? 'admin@phonepartsfinder.com',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Navigation Items
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildDrawerItem(
                    icon: Icons.grid_view_rounded,
                    title: 'Dashboard Overview',
                    index: 0,
                    accentColor: const Color(0xff00E5FF),
                  ),
                  _buildDrawerItem(
                    icon: Icons.storefront_rounded,
                    title: 'Vendor Management',
                    index: 1,
                    accentColor: const Color(0xff7C4DFF),
                  ),
                  _buildDrawerItem(
                    icon: Icons.group_rounded,
                    title: 'User Directory',
                    index: 2,
                    accentColor: const Color(0xff00E676),
                  ),
                  _buildDrawerItem(
                    icon: Icons.category_rounded,
                    title: 'Category Manager',
                    index: 3,
                    accentColor: const Color(0xffFFC400),
                  ),
                  _buildDrawerItem(
                    icon: Icons.payments_rounded,
                    title: 'Commissions Review',
                    index: 4,
                    accentColor: const Color(0xffFF9100),
                  ),
                  _buildDrawerItem(
                    icon: Icons.shield_outlined,
                    title: 'Reports & Complaints',
                    index: 5,
                    accentColor: const Color(0xffFF5252),
                  ),
                ],
              ),
            ),

            const Divider(color: Color(0xff2A2E3D), height: 1),

            // Logout Footer
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                tileColor: Colors.red.withValues(alpha: 0.1),
                leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                title: const Text(
                  'Sign Out',
                  style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                onTap: () async {
                  final authProvider = Provider.of<AuthProvider>(context, listen: false);
                  final notifProvider = Provider.of<NotificationProvider>(context, listen: false);
                  await authProvider.logout(notificationProvider: notifProvider);
                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
    );
  }
}
