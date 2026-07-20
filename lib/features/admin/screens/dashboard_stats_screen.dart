import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/services/auth_provider.dart';
import '../services/admin_service.dart';

/// DashboardStatsScreen
/// Displays statistical count cards for total vendors, customers, parts, requests, and pending approvals.
class DashboardStatsScreen extends StatefulWidget {
  const DashboardStatsScreen({super.key});

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
    String? subtitle,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xff1A1D27),
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
      padding: const EdgeInsets.all(18.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 24, color: accentColor),
              ),
              if (subtitle != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value.toString(),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff12141C),
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
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xff1F2332), Color(0xff1A1D27)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xff2A2E3D)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xff00E5FF).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.analytics_rounded, color: Color(0xff00E5FF), size: 28),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Platform Live Analytics',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Real-time metrics for inventory, users & leads',
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.refresh, color: Colors.grey),
                                onPressed: _loadStats,
                                tooltip: 'Refresh Analytics',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        const Text(
                          'Key Performance Metrics',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Stats Grid
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.1,
                          children: [
                            _buildStatCard(
                              label: 'Total Vendors',
                              value: _stats!.totalVendors,
                              icon: Icons.storefront_rounded,
                              accentColor: const Color(0xff7C4DFF),
                              subtitle: 'ACTIVE SHOPS',
                            ),
                            _buildStatCard(
                              label: 'Total Customers',
                              value: _stats!.totalCustomers,
                              icon: Icons.group_rounded,
                              accentColor: const Color(0xff00E676),
                              subtitle: 'BUYERS',
                            ),
                            _buildStatCard(
                              label: 'Parts Listed',
                              value: _stats!.totalParts,
                              icon: Icons.build_circle_rounded,
                              accentColor: const Color(0xff00E5FF),
                              subtitle: 'INVENTORY',
                            ),
                            _buildStatCard(
                              label: 'Part Requests',
                              value: _stats!.totalRequests,
                              icon: Icons.receipt_long_rounded,
                              accentColor: const Color(0xffFF9100),
                              subtitle: 'LEADS',
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Pending Approvals Banner
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: _stats!.pendingVendorApprovals > 0
                                ? const Color(0xffFFC400).withValues(alpha: 0.12)
                                : const Color(0xff1A1D27),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _stats!.pendingVendorApprovals > 0
                                  ? const Color(0xffFFC400).withValues(alpha: 0.4)
                                  : const Color(0xff2A2E3D),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.pending_actions_rounded,
                                color: _stats!.pendingVendorApprovals > 0
                                    ? const Color(0xffFFC400)
                                    : Colors.grey,
                                size: 30,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${_stats!.pendingVendorApprovals} Pending Vendor Approvals',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: _stats!.pendingVendorApprovals > 0
                                            ? const Color(0xffFFC400)
                                            : Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _stats!.pendingVendorApprovals > 0
                                          ? 'Action required: Review documents in Vendor Management'
                                          : 'All vendor applications up to date',
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}
