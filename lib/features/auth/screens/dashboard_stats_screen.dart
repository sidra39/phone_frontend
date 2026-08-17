import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/services/auth_provider.dart';
import '../services/admin_service.dart';

/// DashboardStatsScreen
/// Displays statistical count cards for total vendors, customers, parts, requests, and pending approvals.
class DashboardStatsScreen extends StatefulWidget {
  final Function(int)? onTabChanged;

  const DashboardStatsScreen({super.key, this.onTabChanged});

  @override
  State<DashboardStatsScreen> createState() => _DashboardStatsScreenState();
}

class _DashboardStatsScreenState extends State<DashboardStatsScreen> {
  final AdminService _adminService = AdminService();
  AdminDashboardStats? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) return;

    setState(() => _isLoading = true);

    try {
      final stats = await _adminService.getDashboardStats(token);
      setState(() {
        _stats = stats;
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

  Widget _buildStatCard({
    required String label,
    required int value,
    required IconData icon,
    required Color accentColor,
    required VoidCallback onTap,
    String? subtitle,
  }) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: accentColor.withValues(alpha: 0.25), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: 0.05),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 20, color: accentColor),
                  ),
                  if (subtitle != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: accentColor,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value.toString(),
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.bodyLarge?.color,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: theme.textTheme.bodyMedium?.color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _stats == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Failed to load stats', style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 12),
                      ElevatedButton(onPressed: _loadStats, child: const Text('Retry')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadStats,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // System Status Header Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xffE2E8F0)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: theme.primaryColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(Icons.analytics_rounded, color: theme.primaryColor, size: 24),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Platform Live Analytics',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: theme.textTheme.bodyLarge?.color,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Real-time metrics for inventory, users & leads',
                                      style: TextStyle(fontSize: 11, color: theme.textTheme.bodyMedium?.color),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.refresh, color: Colors.grey, size: 20),
                                onPressed: _loadStats,
                                tooltip: 'Refresh Analytics',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        Text(
                          'Key Performance Metrics',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: theme.textTheme.bodyLarge?.color,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Stats Grid (optimized childAspectRatio to 1.35 to prevent text overflow on mobile)
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          childAspectRatio: 1.35,
                          children: [
                            _buildStatCard(
                              label: 'Total Vendors',
                              value: _stats!.totalVendors,
                              icon: Icons.storefront_rounded,
                              accentColor: theme.primaryColor,
                              subtitle: 'ACTIVE SHOPS',
                              onTap: () => widget.onTabChanged?.call(1), // Navigates to Vendor Management
                            ),
                            _buildStatCard(
                              label: 'Total Customers',
                              value: _stats!.totalCustomers,
                              icon: Icons.group_rounded,
                              accentColor: theme.primaryColor,
                              subtitle: 'BUYERS',
                              onTap: () => widget.onTabChanged?.call(2), // Navigates to User Directory
                            ),
                            _buildStatCard(
                              label: 'Parts Listed',
                              value: _stats!.totalParts,
                              icon: Icons.build_circle_rounded,
                              accentColor: theme.primaryColor,
                              subtitle: 'INVENTORY',
                              onTap: () => widget.onTabChanged?.call(3), // Navigates to Category Manager
                            ),
                            _buildStatCard(
                              label: 'Part Requests',
                              value: _stats!.totalRequests,
                              icon: Icons.receipt_long_rounded,
                              accentColor: theme.primaryColor,
                              subtitle: 'LEADS',
                              onTap: () => widget.onTabChanged?.call(4), // Navigates to Commission Review
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Pending Approvals Banner (Clickable)
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => widget.onTabChanged?.call(1), // Navigates to Vendor Management
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: _stats!.pendingVendorApprovals > 0
                                    ? const Color(0xffD97706).withValues(alpha: 0.12)
                                    : theme.cardColor,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: _stats!.pendingVendorApprovals > 0
                                      ? const Color(0xffD97706).withValues(alpha: 0.4)
                                      : const Color(0xffE2E8F0),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.pending_actions_rounded,
                                    color: _stats!.pendingVendorApprovals > 0
                                        ? const Color(0xffD97706)
                                        : Colors.grey,
                                    size: 26,
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${_stats!.pendingVendorApprovals} Pending Vendor Approvals',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: _stats!.pendingVendorApprovals > 0
                                                ? const Color(0xffD97706)
                                                : theme.textTheme.bodyLarge?.color,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          _stats!.pendingVendorApprovals > 0
                                              ? 'Action required: Review documents in Vendor Management'
                                              : 'All vendor applications up to date',
                                          style: TextStyle(fontSize: 11, color: theme.textTheme.bodyMedium?.color),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 20),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}