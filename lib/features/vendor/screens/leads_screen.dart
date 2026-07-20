import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/services/auth_provider.dart';
import '../../reports/screens/submit_report_screen.dart';
import '../models/lead_request_model.dart';
import '../services/vendor_service.dart';
import 'my_commissions_screen.dart';

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
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) return;

    setState(() => _isLoading = true);

    try {
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
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) return;

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

  Widget _buildUnlockedCard(LeadRequestModel lead) {
    final bool canRespond = lead.status == 'requested';

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
            const SizedBox(height: 12),
            Text('Customer: ${lead.customerName ?? 'N/A'}', style: const TextStyle(fontWeight: FontWeight.w600)),
            if (lead.customerPhone != null && lead.customerPhone!.isNotEmpty)
              Text('Phone: ${lead.customerPhone}'),
            if (lead.customerEmail != null) Text('Email: ${lead.customerEmail}'),
            if (lead.customerCity != null) Text('City: ${lead.customerCity}'),
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
                if (canRespond)
                  Row(
                    children: [
                      OutlinedButton(
                        onPressed: () => _handleRespond(lead, 'not_available'),
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                        child: const Text('Not Available'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => _handleRespond(lead, 'available'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        child: const Text('Available'),
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
