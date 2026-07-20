import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/services/auth_provider.dart';
import '../models/commission_model.dart';
import '../services/vendor_service.dart';

/// CommissionPaymentScreen
/// Screen for vendors to view commission details and submit/resubmit payment proof URLs.
class CommissionPaymentScreen extends StatefulWidget {
  final CommissionModel commission;

  const CommissionPaymentScreen({super.key, required this.commission});

  @override
  State<CommissionPaymentScreen> createState() => _CommissionPaymentScreenState();
}

class _CommissionPaymentScreenState extends State<CommissionPaymentScreen> {
  final VendorService _vendorService = VendorService();
  final _proofController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.commission.paymentProofUrl != null) {
      _proofController.text = widget.commission.paymentProofUrl!;
    }
  }

  @override
  void dispose() {
    _proofController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmitProof() async {
    if (!_formKey.currentState!.validate()) return;

    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) return;

    setState(() => _isSubmitting = true);

    try {
      await _vendorService.uploadCommissionProof(
        token,
        widget.commission.id,
        _proofController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment proof submitted successfully')),
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final comm = widget.commission;
    final isRejected = comm.status == 'rejected';
    final isPaid = comm.status == 'paid';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Commission Payment'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Amount & Status Header Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Commission Due',
                          style: TextStyle(fontSize: 16, color: Colors.white70),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatusColor(comm.status).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _getStatusColor(comm.status)),
                          ),
                          child: Text(
                            comm.status.toUpperCase(),
                            style: TextStyle(
                              color: _getStatusColor(comm.status),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '\$${comm.amount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff9E9E9E),
                      ),
                    ),
                    if (comm.partModelName != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Part: ${comm.partModelName}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            if (isRejected)
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Your previous payment proof was rejected. Please review and resubmit.',
                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),

            // Payment Instructions
            const Text(
              'Payment Instructions',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade700),
              ),
              child: const Text(
                'Pay this amount via Bank Transfer / JazzCash / EasyPaisa to account:\n'
                '• Bank: HBL Account # 1234-5678-9012\n'
                '• JazzCash / EasyPaisa: 0300-0000000\n'
                'Then paste your payment receipt image URL below.',
                style: TextStyle(color: Color(0xffB0B0B0), fontSize: 13, height: 1.4),
              ),
            ),
            const SizedBox(height: 24),

            if (!isPaid) ...[
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _proofController,
                      decoration: const InputDecoration(
                        labelText: 'Payment Proof Image URL',
                        hintText: 'http://example.com/receipt.jpg',
                      ),
                      validator: (val) =>
                          val == null || val.trim().isEmpty ? 'Please enter receipt URL' : null,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _handleSubmitProof,
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(isRejected ? 'Resubmit Payment Proof' : 'Submit Payment Proof'),
                    ),
                  ],
                ),
              ),
            ] else
              const Center(
                child: Text(
                  'Payment Verified & Paid',
                  style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
