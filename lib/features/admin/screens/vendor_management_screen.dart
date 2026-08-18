import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/api_constants.dart';
import '../../auth/services/auth_provider.dart';
import '../models/vendor_admin_model.dart';
import '../services/admin_service.dart';

/// VendorManagementScreen
/// Allows admins to view vendor applications, filter by verification status, and approve or reject accounts.
class VendorManagementScreen extends StatefulWidget {
  const VendorManagementScreen({super.key});

  @override
  State<VendorManagementScreen> createState() => _VendorManagementScreenState();
}

class _VendorManagementScreenState extends State<VendorManagementScreen> {
  final AdminService _adminService = AdminService();
  String _selectedStatus = 'all';
  List<VendorAdminModel> _vendors = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVendors();
  }

  Future<void> _loadVendors() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) return;

    setState(() => _isLoading = true);

    try {
      final list = await _adminService.getAllVendors(token, statusFilter: _selectedStatus);
      setState(() {
        _vendors = list;
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

  Future<void> _handleApprove(VendorAdminModel vendor) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Approve Vendor Application', style: TextStyle(color: Color(0xff212121))),
        content: Text(
          'Are you sure you want to approve "${vendor.shopName}"?',
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
            child: const Text('Approve Vendor', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;

    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) return;

    try {
      await _adminService.approveVendor(token, vendor.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Vendor "${vendor.shopName}" approved')),
        );
        _loadVendors();
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

  Future<void> _handleReject(VendorAdminModel vendor) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Reject Vendor Application', style: TextStyle(color: Color(0xff212121))),
        content: Text(
          'Are you sure you want to reject "${vendor.shopName}"?',
          style: const TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xffFF5252)),
            child: const Text('Reject Vendor', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;

    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) return;

    try {
      await _adminService.rejectVendor(token, vendor.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Vendor "${vendor.shopName}" rejected')),
        );
        _loadVendors();
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

  Future<void> _handleVerifyDeposit(VendorAdminModel vendor) async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) return;

    try {
      await _adminService.verifyVendorDeposit(token, vendor.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Security deposit for "${vendor.shopName}" marked as PAID & verified!'),
            backgroundColor: Colors.green,
          ),
        );
        _loadVendors();
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

  void _showDepositReceiptViewer(VendorAdminModel vendor) {
    if (vendor.securityDepositProof == null || vendor.securityDepositProof!.isEmpty) return;

    String proofUrl = vendor.securityDepositProof!;
    if (proofUrl.startsWith('/')) {
      proofUrl = '${ApiConstants.baseUrl}$proofUrl';
    }

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${vendor.shopName} - Security Deposit Receipt',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Owner: ${vendor.ownerName} (${vendor.phone ?? vendor.email})',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            Flexible(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 450),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    proofUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Container(
                      padding: const EdgeInsets.all(24),
                      color: Colors.red.withValues(alpha: 0.1),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.broken_image_rounded, color: Colors.red, size: 48),
                          const SizedBox(height: 8),
                          Text('Unable to load receipt photo: $error', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Colors.red)),
                          const SizedBox(height: 8),
                          SelectableText(proofUrl, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  if (vendor.securityDepositStatus?.toLowerCase() != 'paid')
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _handleVerifyDeposit(vendor);
                        },
                        icon: const Icon(Icons.check_circle_rounded),
                        label: const Text('Approve & Verify Security Deposit', style: TextStyle(fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  if (vendor.securityDepositStatus?.toLowerCase() != 'paid') const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return const Color(0xff16A34A);
      case 'rejected':
        return const Color(0xffDC2626);
      case 'pending':
      default:
        return const Color(0xffD97706);
    }
  }

  Color _getDepositColor(String? status) {
    switch ((status ?? '').toLowerCase()) {
      case 'paid':
        return const Color(0xff16A34A);
      case 'pending_verification':
        return const Color(0xffD97706);
      case 'unpaid':
      default:
        return const Color(0xffDC2626);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          // Segment Filter Bar
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: theme.cardColor,
              border: const Border(bottom: BorderSide(color: Color(0xffE2E8F0))),
            ),
            child: Row(
              children: [
                Icon(Icons.filter_alt_rounded, color: theme.primaryColor, size: 20),
                const SizedBox(width: 10),
                Text('Status Filter:', style: TextStyle(fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)),
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
                          DropdownMenuItem(value: 'all', child: Text('All Vendor Applications')),
                          DropdownMenuItem(value: 'pending', child: Text('Pending Approval')),
                          DropdownMenuItem(value: 'approved', child: Text('Approved Applications')),
                          DropdownMenuItem(value: 'rejected', child: Text('Rejected Applications')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedStatus = val);
                            _loadVendors();
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Vendor Cards List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _vendors.isEmpty
                    ? const Center(
                        child: Text(
                          'No vendors found for selected filter',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadVendors,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16.0),
                          itemCount: _vendors.length,
                          itemBuilder: (context, index) {
                            final vendor = _vendors[index];
                            final isPending = vendor.verificationStatus.toLowerCase() == 'pending';
                            final statusColor = _getStatusColor(vendor.verificationStatus);

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
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: const Color(0xff7C4DFF).withValues(alpha: 0.15),
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: const Icon(Icons.storefront_rounded, color: Color(0xff7C4DFF), size: 20),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                vendor.shopName,
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xff212121),
                                                ),
                                              ),
                                            ),
                                          ],
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
                                          vendor.verificationStatus.toUpperCase(),
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
                                  const SizedBox(height: 14),

                                  // Owner Info Row
                                  Row(
                                    children: [
                                      const Icon(Icons.person_outline_rounded, size: 16, color: Colors.grey),
                                      const SizedBox(width: 8),
                                      Text(
                                        vendor.ownerName,
                                        style: const TextStyle(color: Color(0xff212121), fontWeight: FontWeight.w500),
                                      ),
                                      const SizedBox(width: 8),
                                      Text('(${vendor.email})', style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
                                    ],
                                  ),
                                  const SizedBox(height: 6),

                                  // Location & Address Row
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade800,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          vendor.city,
                                          style: const TextStyle(color: Color(0xff212121), fontSize: 11, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          vendor.address,
                                          style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),

                                  if (vendor.phone != null && vendor.phone!.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        const Icon(Icons.phone_outlined, size: 16, color: Colors.grey),
                                        const SizedBox(width: 8),
                                        Text(vendor.phone!, style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
                                      ],
                                    ),
                                  ],

                                  // Security Deposit Status & Receipt Preview Box
                                  Container(
                                    margin: const EdgeInsets.only(top: 12),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: theme.scaffoldBackgroundColor,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: const Color(0xffCCCCCC)),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Row(
                                              children: [
                                                Icon(Icons.shield_outlined, size: 18, color: Colors.amber),
                                                SizedBox(width: 6),
                                                Text('Security Deposit:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                              ],
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: _getDepositColor(vendor.securityDepositStatus).withValues(alpha: 0.2),
                                                borderRadius: BorderRadius.circular(10),
                                                border: Border.all(color: _getDepositColor(vendor.securityDepositStatus)),
                                              ),
                                              child: Text(
                                                (vendor.securityDepositStatus ?? 'UNPAID').replaceAll('_', ' ').toUpperCase(),
                                                style: TextStyle(
                                                  color: _getDepositColor(vendor.securityDepositStatus),
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (vendor.securityDepositProof != null && vendor.securityDepositProof!.isNotEmpty) ...[
                                          const SizedBox(height: 10),
                                          SizedBox(
                                            width: double.infinity,
                                            child: ElevatedButton.icon(
                                              onPressed: () => _showDepositReceiptViewer(vendor),
                                              icon: const Icon(Icons.image_outlined, size: 18),
                                              label: const Text('📷 View Security Deposit Receipt Photo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xff00E5FF),
                                                foregroundColor: Colors.black,
                                                padding: const EdgeInsets.symmetric(vertical: 10),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                              ),
                                            ),
                                          ),
                                        ],
                                        if (vendor.securityDepositStatus?.toLowerCase() != 'paid' &&
                                            vendor.securityDepositProof != null &&
                                            vendor.securityDepositProof!.isNotEmpty) ...[
                                          const SizedBox(height: 8),
                                          SizedBox(
                                            width: double.infinity,
                                            child: ElevatedButton.icon(
                                              onPressed: () => _handleVerifyDeposit(vendor),
                                              icon: const Icon(Icons.check_circle_outline, size: 18),
                                              label: const Text('Approve & Verify Security Deposit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.green,
                                                foregroundColor: Colors.white,
                                                padding: const EdgeInsets.symmetric(vertical: 10),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),

                                  if (isPending) ...[
                                    const SizedBox(height: 16),
                                    const Divider(color: Color(0xffCCCCCC), height: 1),
                                    const SizedBox(height: 14),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        OutlinedButton.icon(
                                          onPressed: () => _handleReject(vendor),
                                          icon: const Icon(Icons.close_rounded, size: 18),
                                          label: const Text('Reject'),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: const Color(0xffFF5252),
                                            side: const BorderSide(color: Color(0xffFF5252)),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        ElevatedButton.icon(
                                          onPressed: () => _handleApprove(vendor),
                                          icon: const Icon(Icons.check_rounded, size: 18),
                                          label: const Text('Approve Application'),
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
