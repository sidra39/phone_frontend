import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/services/auth_provider.dart';
import '../../reports/screens/submit_report_screen.dart';
import '../models/lead_request_model.dart';
import '../services/vendor_service.dart';
import 'my_commissions_screen.dart';

import 'vendor_dashboard_screen.dart';

/// LeadsScreen
/// Vendor interface to view received customer lead requests, respond to unlocked leads, or view locked lead obligations.
class LeadsScreen extends StatefulWidget {
  const LeadsScreen({super.key});

  @override
  State<LeadsScreen> createState() => _LeadsScreenState();
}

class _LeadsScreenState extends State<LeadsScreen> {
  final VendorService _vendorService = VendorService();
  List<LeadRequestModel> _leads = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLeads();
  }

  Future<void> _loadLeads() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    if (token == null) return;

    setState(() => _isLoading = true);

    try {
      await authProvider.refreshProfile();
      final list = await _vendorService.getVendorRequests(token);
      setState(() {
        _leads = list;
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

  Future<void> _handleRespond(LeadRequestModel lead, String status) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    if (token == null) return;

    // Refresh profile state first to verify current database deposit status
    await authProvider.refreshProfile();
    if (!mounted) return;
    final user = authProvider.user;

    if (user != null && user.role == 'vendor' && user.securityDepositStatus?.toLowerCase() != 'paid') {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('⚠️ Security Deposit Pending', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Logged In Account: ${user.email}', style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('Shop Name: ${user.shopName ?? 'Vendor Shop'}'),
              Text('Security Deposit Status: ${user.securityDepositStatus?.toUpperCase() ?? 'UNPAID'}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              const Text(
                'To respond to customer leads, please ensure Admin has verified the Rs. 500 Security Deposit for THIS SPECIFIC account email.',
                style: TextStyle(fontSize: 13),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    try {
      await _vendorService.respondToRequest(token, lead.id, status);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Marked request as $status')),
        );
        _loadLeads();
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
      case 'available':
        return Colors.green;
      case 'not_available':
        return Colors.red;
      case 'requested':
      default:
        return Colors.grey;
    }
  }

  Widget _buildLockedCard(LeadRequestModel lead) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lock, color: Colors.grey, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    lead.partModelName,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  '\$${lead.partPrice.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 16, color: Color(0xff9E9E9E), fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              lead.lockMessage ?? 'Pay commission to view customer details',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MyCommissionsScreen()),
                  );
                },
                icon: const Icon(Icons.payment, size: 18),
                label: const Text('View Commission'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleCancelOrder(LeadRequestModel lead) async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) return;

    final reasonController = TextEditingController();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Order Online', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Are you sure you want to cancel this customer order? Note: Cancelling orders online is tracked. Reaching 3 order cancellations will AUTOMATICALLY BLOCK your account.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Cancellation Reason *',
                hintText: 'e.g. Out of stock / Unable to fulfill',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep Order'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm Cancel'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final res = await _vendorService.cancelOrder(token, lead.id, reasonController.text.trim());
      if (mounted) {
        final bool isAutoBlocked = res['is_auto_blocked'] == true;
        final String message = res['message'] ?? 'Order cancelled successfully';

        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(isAutoBlocked ? '🚨 ACCOUNT BLOCKED!' : 'Order Cancelled'),
            content: Text(message),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        _loadLeads();
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

  Widget _buildUnlockedCard(LeadRequestModel lead) {
    final bool canRespond = lead.status == 'requested';
    final bool canCancel = lead.status != 'cancelled';

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    lead.partModelName,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(lead.status).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _getStatusColor(lead.status)),
                  ),
                  child: Text(
                    lead.status.replaceAll('_', ' ').toUpperCase(),
                    style: TextStyle(
                      color: _getStatusColor(lead.status),
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
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
                    color: lead.deliveryType == 'home_delivery'
                        ? Colors.blue.withValues(alpha: 0.15)
                        : Colors.purple.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    lead.deliveryType == 'home_delivery' ? '🚚 Home Delivery' : '🏪 Shop Pickup',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: lead.deliveryType == 'home_delivery' ? Colors.blue.shade800 : Colors.purple.shade800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Customer: ${lead.customerName ?? 'N/A'}', style: const TextStyle(fontWeight: FontWeight.w600)),
            if (lead.customerPhone != null && lead.customerPhone!.isNotEmpty)
              Text('Phone: ${lead.customerPhone}'),
            if (lead.customerEmail != null) Text('Email: ${lead.customerEmail}'),
            if (lead.customerCity != null) Text('City: ${lead.customerCity}'),
            if (lead.deliveryType == 'home_delivery' && lead.deliveryAddress != null) ...[
              const SizedBox(height: 4),
              Text(
                'Delivery Address: ${lead.deliveryAddress}, ${lead.deliveryCity ?? ''}',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent),
              ),
              if (lead.deliveryNotes != null && lead.deliveryNotes!.isNotEmpty)
                Text('Notes: ${lead.deliveryNotes}', style: const TextStyle(fontStyle: FontStyle.italic)),
            ],
            if (lead.status == 'cancelled' && lead.cancellationReason != null) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '❌ Cancelled Reason: ${lead.cancellationReason}',
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
            Text('Price: \$${lead.partPrice.toStringAsFixed(2)}'),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: () {
                    if (lead.customerUserId == null) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SubmitReportScreen(
                          reportedUserId: lead.customerUserId!,
                          requestId: lead.id,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.report_problem, size: 16, color: Colors.redAccent),
                  label: const Text('Report Customer', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                ),
                Wrap(
                  spacing: 6,
                  children: [
                    if (canRespond) ...[
                      OutlinedButton(
                        onPressed: () => _handleRespond(lead, 'not_available'),
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                        child: const Text('Not Available'),
                      ),
                      ElevatedButton(
                        onPressed: () => _handleRespond(lead, 'available'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        child: const Text('Available'),
                      ),
                    ],
                    if (canCancel)
                      OutlinedButton.icon(
                        onPressed: () => _handleCancelOrder(lead),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                        ),
                        icon: const Icon(Icons.cancel_outlined, size: 14),
                        label: const Text('Cancel Order', style: TextStyle(fontSize: 12)),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Leads'),
        actions: [
          IconButton(
            icon: const Icon(Icons.explore_rounded, color: Color(0xff00E5FF)),
            tooltip: 'Browse Marketplace Page',
            onPressed: () {
              final dashboard = VendorDashboardScreen.of(context);
              if (dashboard != null) {
                dashboard.setTab(0);
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const VendorDashboardScreen(initialIndex: 0)),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLeads,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _leads.isEmpty
              ? const Center(
                  child: Text(
                    'No customer leads received yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadLeads,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: _leads.length,
                    itemBuilder: (context, index) {
                      final lead = _leads[index];
                      return lead.isLocked ? _buildLockedCard(lead) : _buildUnlockedCard(lead);
                    },
                  ),
                ),
    );
  }
}