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
        return const Color(0xff16A34A);
      case 'rejected':
        return const Color(0xffDC2626);
      case 'pending':
      default:
        return const Color(0xffD97706);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.cardColor,
        elevation: 1,
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
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xffE2E8F0)),
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
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: theme.primaryColor,
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
                                    style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 14),
                                  ),
                                  if (comm.paymentProofUrl != null) ...[
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Icon(Icons.check_circle_outline_rounded, size: 14, color: theme.primaryColor),
                                        const SizedBox(width: 6),
                                        Text('Payment Proof Submitted', style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 12)),
                                      ],
                                    ),
                                  ],
                                  if (isActionable) ...[
                                    const SizedBox(height: 12),
                                    const Divider(color: Color(0xffE2E8F0), height: 1),
                                    const SizedBox(height: 10),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Text('Submit / Update Proof', style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold, fontSize: 13)),
                                        const SizedBox(width: 6),
                                        Icon(Icons.arrow_forward_rounded, color: theme.primaryColor, size: 16),
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
