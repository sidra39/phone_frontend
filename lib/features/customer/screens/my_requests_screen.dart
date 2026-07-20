import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/notification_bell_icon.dart';
import '../../auth/services/auth_provider.dart';
import '../../reports/screens/submit_report_screen.dart';
import '../models/request_model.dart';
import '../services/customer_service.dart';
import 'add_review_screen.dart';

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
      backgroundColor: const Color(0xff12141C),
      appBar: AppBar(
        backgroundColor: const Color(0xff1A1D27),
        elevation: 0,
        title: const Text('My Component Requests', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
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

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16.0),
                        padding: const EdgeInsets.all(18.0),
                        decoration: BoxDecoration(
                          color: const Color(0xff1A1D27),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xff2A2E3D)),
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
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
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
                            Text(
                              'Shop: ${req.shopName} (${req.vendorCity})',
                              style: TextStyle(color: Colors.grey.shade300, fontWeight: FontWeight.w500, fontSize: 14),
                            ),
                            if (req.vendorAddress.isNotEmpty)
                              Text(
                                req.vendorAddress,
                                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                              ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Price: \$${req.price.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xff00E5FF),
                                    fontSize: 15,
                                  ),
                                ),
                                Text(
                                  req.createdAt.split('T').first,
                                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            const Divider(color: Color(0xff2A2E3D), height: 1),
                            const SizedBox(height: 12),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                  icon: const Icon(Icons.report_problem_rounded, size: 16, color: Color(0xffFF5252)),
                                  label: const Text('Report Vendor', style: TextStyle(color: Color(0xffFF5252), fontSize: 12, fontWeight: FontWeight.bold)),
                                ),
                                if (canReview)
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
                                    ),
                                    icon: const Icon(Icons.star_rounded, size: 18, color: Colors.black),
                                    label: const Text('Leave Review', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
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
