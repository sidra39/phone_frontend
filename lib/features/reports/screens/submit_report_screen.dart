import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/services/auth_provider.dart';
import '../services/report_service.dart';

/// SubmitReportScreen
/// Form for submitting a complaint report against another user.
class SubmitReportScreen extends StatefulWidget {
  final int reportedUserId;
  final int? requestId;

  const SubmitReportScreen({
    super.key,
    required this.reportedUserId,
    this.requestId,
  });

  @override
  State<SubmitReportScreen> createState() => _SubmitReportScreenState();
}

class _SubmitReportScreenState extends State<SubmitReportScreen> {
  final ReportService _reportService = ReportService();
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();

  String _selectedReason = 'Bypassed app to avoid commission';
  bool _isSubmitting = false;

  final List<String> _reasons = const [
    'Bypassed app to avoid commission',
    'Fake/counterfeit part',
    'Fraud or scam',
    'Abusive behavior',
    'Other',
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) return;

    setState(() => _isSubmitting = true);

    try {
      await _reportService.submitReport(
        token,
        reportedUserId: widget.reportedUserId,
        requestId: widget.requestId,
        reason: _selectedReason,
        description: _descriptionController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report submitted successfully')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Submit Report'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Report Unfair Behavior',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Help keep Phone Parts Finder safe by reporting policy violations or fraudulent activity.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),

              DropdownButtonFormField<String>(
                initialValue: _selectedReason,
                decoration: const InputDecoration(labelText: 'Reason for Report'),
                items: _reasons.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedReason = val);
                  }
                },
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _descriptionController,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Provide details about the incident...',
                  alignLabelWithHint: true,
                ),
                validator: (val) =>
                    val == null || val.trim().isEmpty ? 'Please describe what happened' : null,
              ),
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _isSubmitting ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xff212121)),
                      )
                    : const Text('Submit Report'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
