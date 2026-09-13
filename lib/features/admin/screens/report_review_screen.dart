import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/services/auth_provider.dart';
import '../../reports/models/report_model.dart';
import '../services/admin_service.dart';

/// ReportReviewScreen
/// Admin interface for reviewing user complaints, filtering by status, and resolving/dismissing reports.
class ReportReviewScreen extends StatefulWidget {
  const ReportReviewScreen({super.key});

  @override
  State<ReportReviewScreen> createState() => _ReportReviewScreenState();
}

class _ReportReviewScreenState extends State<ReportReviewScreen> {
  final AdminService _adminService = AdminService();
  List<ReportModel> _reports = [];
  bool _isLoading = true;
  String _selectedStatusFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) return;

    setState(() => _isLoading = true);

    try {
      final list = await _adminService.getAllReports(token, statusFilter: _selectedStatusFilter);
      setState(() {
        _reports = list;
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

  Future<void> _handleAction(int id, String action) async {
    final bool isResolve = action == 'resolve';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('${isResolve ? 'Resolve' : 'Dismiss'} Report', style: const TextStyle(color: Color(0xff212121), fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to mark this complaint as $action?',
          style: const TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isResolve ? const Color(0xff00E676) : const Color(0xffFF5252),
            ),
            child: Text(
              isResolve ? 'Resolve' : 'Dismiss',
              style: TextStyle(
                color: isResolve ? Colors.black : Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;

    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) return;

    try {
      if (isResolve) {
        await _adminService.resolveReport(token, id);
      } else {
        await _adminService.dismissReport(token, id);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Report marked as $action')),
        );
        _loadReports();
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
      case 'resolved':
        return const Color(0xff16A34A);
      case 'dismissed':
        return const Color(0xff64748B);
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
      body: Column(
        children: [
          // Filter Bar
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: theme.cardColor,
              border: const Border(bottom: BorderSide(color: Color(0xffE2E8F0))),
            ),
            child: Row(
              children: [
                const Icon(Icons.shield_outlined, color: Color(0xffDC2626), size: 20),
                const SizedBox(width: 10),
                Text('Complaint Status:', style: TextStyle(fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: theme.scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xffE2E8F0)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedStatusFilter,
                        dropdownColor: theme.cardColor,
                        isExpanded: true,
                        style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 14),
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('All Complaint Reports')),
                          DropdownMenuItem(value: 'pending', child: Text('Pending Review')),
                          DropdownMenuItem(value: 'resolved', child: Text('Resolved Cases')),
                          DropdownMenuItem(value: 'dismissed', child: Text('Dismissed Cases')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedStatusFilter = val);
                            _loadReports();
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Reports List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _reports.isEmpty
                    ? const Center(
                        child: Text(
                          'No complaint reports found',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadReports,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16.0),
                          itemCount: _reports.length,
                          itemBuilder: (context, index) {
                            final report = _reports[index];
                            final bool isPending = report.status.toLowerCase() == 'pending';
                            final statusColor = _getStatusColor(report.status);

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
                                          report.reason,
                                          style: const TextStyle(
                                            fontSize: 17,
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
                                          report.status.toUpperCase(),
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

                                  // Reporter / Reported Pills
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xff00E5FF).withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: const Color(0xff00E5FF).withValues(alpha: 0.3)),
                                        ),
                                        child: Text(
                                          'Reporter: ${report.reporterName ?? 'User #${report.id}'}',
                                          style: const TextStyle(color: Color(0xff00E5FF), fontSize: 12, fontWeight: FontWeight.w500),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xffFF5252).withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: const Color(0xffFF5252).withValues(alpha: 0.3)),
                                        ),
                                        child: Text(
                                          'Reported: ${report.reportedName ?? 'N/A'}',
                                          style: const TextStyle(color: Color(0xffFF5252), fontSize: 12, fontWeight: FontWeight.w500),
                                        ),
                                      ),
                                      if (report.requestId != null)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade800,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            'Request #${report.requestId}',
                                            style: const TextStyle(color: Color(0xff212121), fontSize: 12),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),

                                  // Description Box
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).scaffoldBackgroundColor,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: const Color(0xffCCCCCC)),
                                    ),
                                    child: Text(
                                      report.description,
                                      style: TextStyle(color: Colors.grey.shade300, fontSize: 14, height: 1.4),
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
                                          onPressed: () => _handleAction(report.id, 'dismiss'),
                                          icon: const Icon(Icons.close_rounded, size: 18),
                                          label: const Text('Dismiss'),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: const Color(0xffFF5252),
                                            side: const BorderSide(color: Color(0xffFF5252)),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        ElevatedButton.icon(
                                          onPressed: () => _handleAction(report.id, 'resolve'),
                                          icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                                          label: const Text('Resolve Complaint'),
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
