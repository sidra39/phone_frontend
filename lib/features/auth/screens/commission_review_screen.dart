import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../auth/services/auth_provider.dart';
import '../../vendor/models/commission_model.dart';
import '../services/admin_service.dart';

/// CommissionReviewScreen
/// Admin interface for filtering vendor commissions, launching payment proof URLs, and verifying/rejecting payments.
class CommissionReviewScreen extends StatefulWidget {
  const CommissionReviewScreen({super.key});

  @override
  State<CommissionReviewScreen> createState() => _CommissionReviewScreenState();
}

class _CommissionReviewScreenState extends State<CommissionReviewScreen> {
  final AdminService _adminService = AdminService();
  String _selectedStatus = 'all';
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
      final list = await _adminService.getAllCommissions(token, statusFilter: _selectedStatus);
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

  Future<void> _openProofUrl(String urlString) async {
    final Uri uri = Uri.parse(urlString);
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open proof URL'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invalid URL: $urlString'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _handleVerify(CommissionModel comm) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Verify Commission Payment', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          'Verify payment of \$${comm.amount.toStringAsFixed(2)} from "${comm.vendorShopName ?? 'Vendor'}" and unlock customer leads?',
          style: const TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xff00E676)),
            child: const Text('Verify & Unlock', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;

    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) return;

    try {
      await _adminService.verifyCommission(token, comm.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Commission verified and customer leads unlocked')),
        );
        _loadCommissions();
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

  Future<void> _handleReject(CommissionModel comm) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Reject Commission Proof', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to reject the payment proof from "${comm.vendorShopName ?? 'Vendor'}"?',
          style: const TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xffDC2626)),
            child: const Text('Reject Proof', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;

    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) return;

    try {
      await _adminService.rejectCommission(token, comm.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Commission payment proof rejected')),
        );
        _loadCommissions();
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
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          // Filter Bar
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border(bottom: BorderSide(color: const Color(0xffCCCCCC))),
            ),
            child: Row(
              children: [
                const Icon(Icons.payments_rounded, color: Color(0xffFF9100), size: 20),
                const SizedBox(width: 10),
                const Text('Commission Status:', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xff212121))),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xffCCCCCC)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedStatus,
                        dropdownColor: Theme.of(context).cardColor,
                        isExpanded: true,
                        style: const TextStyle(color: Color(0xff212121), fontSize: 14),
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('All Commissions')),
                          DropdownMenuItem(value: 'pending', child: Text('Pending Review')),
                          DropdownMenuItem(value: 'paid', child: Text('Verified Paid')),
                          DropdownMenuItem(value: 'rejected', child: Text('Rejected Proofs')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedStatus = val);
                            _loadCommissions();
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Commission List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _commissions.isEmpty
                    ? const Center(
                        child: Text(
                          'No commission records found',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadCommissions,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16.0),
                          itemCount: _commissions.length,
                          itemBuilder: (context, index) {
                            final comm = _commissions[index];
                            final hasProof = comm.paymentProofUrl != null && comm.paymentProofUrl!.isNotEmpty;
                            final isPendingWithProof = comm.status.toLowerCase() == 'pending' && hasProof;
                            final statusColor = _getStatusColor(comm.status);

                            return Container(
                              margin: const EdgeInsets.only(bottom: 16.0),
                              padding: const EdgeInsets.all(18.0),
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xffCCCCCC)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          comm.vendorShopName ?? 'Vendor #${comm.id}',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xff212121),
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
                                  const SizedBox(height: 12),

                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Commission Due: \$${comm.amount.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xffFF9100),
                                        ),
                                      ),
                                      if (comm.partModelName != null)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade800,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            comm.partModelName!,
                                            style: const TextStyle(color: Color(0xff212121), fontSize: 11),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),

                                  Row(
                                    children: [
                                      if (hasProof)
                                        OutlinedButton.icon(
                                          onPressed: () => _openProofUrl(comm.paymentProofUrl!),
                                          icon: const Icon(Icons.open_in_new_rounded, size: 16),
                                          label: const Text('View Payment Proof'),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: const Color(0xff00E5FF),
                                            side: const BorderSide(color: Color(0xff00E5FF)),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          ),
                                        )
                                      else
                                        Text(
                                          'No payment proof submitted yet',
                                          style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontStyle: FontStyle.italic),
                                        ),
                                    ],
                                  ),

                                  if (isPendingWithProof) ...[
                                    const SizedBox(height: 16),
                                    const Divider(color: Color(0xffCCCCCC), height: 1),
                                    const SizedBox(height: 14),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        OutlinedButton.icon(
                                          onPressed: () => _handleReject(comm),
                                          icon: const Icon(Icons.close_rounded, size: 18),
                                          label: const Text('Reject Proof'),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: const Color(0xffFF5252),
                                            side: const BorderSide(color: Color(0xffFF5252)),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        ElevatedButton.icon(
                                          onPressed: () => _handleVerify(comm),
                                          icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                                          label: const Text('Verify & Unlock'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xff00E676),
                                            foregroundColor: Colors.black,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
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