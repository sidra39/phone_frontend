import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/notification_bell_icon.dart';
import '../../auth/services/auth_provider.dart';
import '../../reports/screens/submit_report_screen.dart';
import '../models/request_model.dart';
import '../services/customer_service.dart';
import 'add_review_screen.dart';
import 'qr_scanner_screen.dart';

import 'customer_dashboard_screen.dart';

/// MyRequestsScreen
/// Displays customer request history with glowing status badges and review/report actions.
class MyRequestsScreen extends StatefulWidget {
  const MyRequestsScreen({super.key});

  @override
  State<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends State<MyRequestsScreen> {
  final CustomerService _customerService = CustomerService();
  List<RequestModel> _requests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) return;

    setState(() => _isLoading = true);

    try {
      final list = await _customerService.getMyRequests(token);
      setState(() {
        _requests = list;
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return const Color(0xff00E676);
      case 'responded':
        return const Color(0xff00E5FF);
      case 'not_available':
        return const Color(0xffFF5252);
      case 'requested':
      default:
        return const Color(0xffFFC400);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor,
        elevation: 0,
        title: const Text('My Component Requests', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.explore_rounded, color: Color(0xff00E5FF)),
            tooltip: 'Browse Marketplace Page',
            onPressed: () {
              final dashboard = CustomerDashboardScreen.of(context);
              if (dashboard != null) {
                dashboard.setTab(0);
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CustomerDashboardScreen(initialIndex: 0)),
                );
              }
            },
          ),
          const NotificationBellIcon(),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadRequests,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _requests.isEmpty
              ? const Center(
                  child: Text(
                    'No component requests submitted yet',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadRequests,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: _requests.length,
                    itemBuilder: (context, index) {
                      final req = _requests[index];
                      final bool canReview = req.status == 'responded' || req.status == 'available';
                      final statusColor = _getStatusColor(req.status);

                      final theme = Theme.of(context);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16.0),
                        padding: const EdgeInsets.all(18.0),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xffE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    req.modelName,
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      color: theme.textTheme.bodyLarge?.color,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                                  ),
                                  child: Text(
                                    req.status.replaceAll('_', ' ').toUpperCase(),
                                    style: TextStyle(
                                      color: statusColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                             const SizedBox(height: 8),
                             Row(
                               children: [
                                 Container(
                                   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                   decoration: BoxDecoration(
                                     color: req.deliveryType == 'home_delivery'
                                         ? Colors.blue.withValues(alpha: 0.15)
                                         : Colors.purple.withValues(alpha: 0.15),
                                     borderRadius: BorderRadius.circular(6),
                                   ),
                                   child: Text(
                                     req.deliveryType == 'home_delivery' ? '🚚 Home Delivery' : '🏪 Shop Pickup',
                                     style: TextStyle(
                                       fontSize: 10,
                                       fontWeight: FontWeight.bold,
                                       color: req.deliveryType == 'home_delivery' ? Colors.blue.shade800 : Colors.purple.shade800,
                                     ),
                                   ),
                                 ),
                               ],
                             ),
                             const SizedBox(height: 6),
                             Text(
                               'Shop: ${req.shopName} (${req.vendorCity})',
                               style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontWeight: FontWeight.w500, fontSize: 13),
                             ),
                             if (req.vendorAddress.isNotEmpty)
                               Text(
                                 req.vendorAddress,
                                 style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 12),
                               ),
                             if (req.deliveryType == 'home_delivery' && req.deliveryAddress != null) ...[
                               const SizedBox(height: 4),
                               Text(
                                 'Deliver To: ${req.deliveryAddress}, ${req.deliveryCity ?? ''} (Phone: ${req.deliveryPhone ?? 'N/A'})',
                                 style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blueAccent),
                               ),
                             ],
                             if (req.status == 'cancelled' && req.cancellationReason != null) ...[
                               const SizedBox(height: 6),
                               Container(
                                 padding: const EdgeInsets.all(8),
                                 decoration: BoxDecoration(
                                   color: Colors.red.withValues(alpha: 0.1),
                                   borderRadius: BorderRadius.circular(8),
                                   border: Border.all(color: Colors.red.shade300),
                                 ),
                                 child: Text(
                                   '❌ Cancelled by ${req.cancelledBy ?? 'Vendor'}: ${req.cancellationReason}',
                                   style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
                                 ),
                               ),
                             ],
                             const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Price: \$${req.price.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: theme.primaryColor,
                                    fontSize: 15,
                                  ),
                                ),
                                Text(
                                  req.createdAt.split('T').first,
                                  style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 12),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            const Divider(color: Color(0xffE2E8F0), height: 1),
                            const SizedBox(height: 12),

                            Wrap(
                              alignment: WrapAlignment.spaceBetween,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                TextButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => SubmitReportScreen(
                                          reportedUserId: req.vendorUserId ?? req.vendorId,
                                          requestId: req.id,
                                        ),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.report_problem_rounded, size: 16, color: Color(0xffDC2626)),
                                  label: const Text('Report Vendor', style: TextStyle(color: Color(0xffDC2626), fontSize: 12, fontWeight: FontWeight.bold)),
                                ),
                                if (canReview) ...[
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => QrScannerScreen(
                                            partId: req.partId,
                                            requestId: req.id,
                                          ),
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: theme.primaryColor,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    ),
                                    icon: const Icon(Icons.qr_code_scanner_rounded, size: 16),
                                    label: const Text('Verify Delivery', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: () async {
                                      final updated = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => AddReviewScreen(request: req),
                                        ),
                                      );
                                      if (updated == true && mounted) {
                                        _loadRequests();
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.amber,
                                      foregroundColor: Colors.black,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    ),
                                    icon: const Icon(Icons.star_rounded, size: 16, color: Colors.black),
                                    label: const Text('Review', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}