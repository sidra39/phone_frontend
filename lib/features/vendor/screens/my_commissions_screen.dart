import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/notification_bell_icon.dart';
import '../../auth/services/auth_provider.dart';
import '../models/commission_model.dart';
import '../services/vendor_service.dart';
import 'commission_payment_screen.dart';

/// MyCommissionsScreen
/// Displays vendor commissions list with status badges and navigation to payment submission.
class MyCommissionsScreen extends StatefulWidget {
  const MyCommissionsScreen({super.key});

  @override
  State<MyCommissionsScreen> createState() => _MyCommissionsScreenState();
}

class _MyCommissionsScreenState extends State<MyCommissionsScreen> {
  final VendorService _vendorService = VendorService();
  List<CommissionModel> _commissions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCommissions();
  }

  Future<void> _loadCommissions() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) return;

    setState(() => _isLoading = true);

    try {
      final list = await _vendorService.getMyCommissions(token);
      setState(() {
        _commissions = list;
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
      case 'paid':
        return const Color(0xff00E676);
      case 'rejected':
        return const Color(0xffFF5252);
      case 'pending':
      default:
        return const Color(0xffFF9100);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff12141C),
      appBar: AppBar(
        backgroundColor: const Color(0xff1A1D27),
        elevation: 0,
        title: const Text('Commission Obligations', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          const NotificationBellIcon(),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadCommissions,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _commissions.isEmpty
              ? const Center(
                  child: Text(
                    'No commission records found',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadCommissions,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: _commissions.length,
                    itemBuilder: (context, index) {
                      final comm = _commissions[index];
                      final isActionable = comm.status.toLowerCase() == 'pending' || comm.status.toLowerCase() == 'rejected';
                      final statusColor = _getStatusColor(comm.status);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16.0),
                        decoration: BoxDecoration(
                          color: const Color(0xff1A1D27),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xff2A2E3D)),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: isActionable
                                ? () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => CommissionPaymentScreen(commission: comm),
                                      ),
                                    );
                                    if (result == true || mounted) {
                                      _loadCommissions();
                                    }
                                  }
                                : null,
                            child: Padding(
                              padding: const EdgeInsets.all(18.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '10% Fee: \$${comm.amount.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xffFF9100),
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
                                          comm.status.toUpperCase(),
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
                                  const SizedBox(height: 10),
                                  Text(
                                    'Component: ${comm.partModelName ?? 'Part #${comm.requestId}'}',
                                    style: TextStyle(color: Colors.grey.shade300, fontSize: 14),
                                  ),
                                  if (comm.paymentProofUrl != null) ...[
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        const Icon(Icons.check_circle_outline_rounded, size: 14, color: Color(0xff00E5FF)),
                                        const SizedBox(width: 6),
                                        Text('Payment Proof Submitted', style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                                      ],
                                    ),
                                  ],
                                  if (isActionable) ...[
                                    const SizedBox(height: 12),
                                    const Divider(color: Color(0xff2A2E3D), height: 1),
                                    const SizedBox(height: 10),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: const [
                                        Text('Submit / Update Proof', style: TextStyle(color: Color(0xffFF9100), fontWeight: FontWeight.bold, fontSize: 13)),
                                        SizedBox(width: 6),
                                        Icon(Icons.arrow_forward_rounded, color: Color(0xffFF9100), size: 16),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
