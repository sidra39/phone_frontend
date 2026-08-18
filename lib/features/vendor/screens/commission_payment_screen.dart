import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../auth/services/auth_provider.dart';
import '../models/commission_model.dart';
import '../services/vendor_service.dart';

/// CommissionPaymentScreen
/// Screen for vendors to view commission details and upload payment receipt photo from device.
class CommissionPaymentScreen extends StatefulWidget {
  final CommissionModel commission;

  const CommissionPaymentScreen({super.key, required this.commission});

  @override
  State<CommissionPaymentScreen> createState() => _CommissionPaymentScreenState();
}

class _CommissionPaymentScreenState extends State<CommissionPaymentScreen> {
  final VendorService _vendorService = VendorService();
  final ImagePicker _picker = ImagePicker();

  XFile? _selectedPhoto;
  final _urlFallbackController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.commission.paymentProofUrl != null) {
      _urlFallbackController.text = widget.commission.paymentProofUrl!;
    }
  }

  @override
  void dispose() {
    _urlFallbackController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source, imageQuality: 85);
      if (picked != null) {
        setState(() {
          _selectedPhoto = picked;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick photo: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _handleSubmitProof() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) return;

    if (_selectedPhoto == null && _urlFallbackController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a receipt photo to upload'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      List<int>? bytes;
      String? filename;
      if (_selectedPhoto != null) {
        bytes = await _selectedPhoto!.readAsBytes();
        filename = _selectedPhoto!.name;
      }

      await _vendorService.uploadCommissionProof(
        token,
        widget.commission.id,
        bytes: bytes,
        filename: filename,
        proofPath: _selectedPhoto?.path,
        proofUrl: _urlFallbackController.text.trim().isNotEmpty ? _urlFallbackController.text.trim() : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Receipt photo uploaded successfully!'), backgroundColor: Colors.green),
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
        return Colors.amber;
    }
  }

  @override
  Widget build(BuildContext context) {
    final comm = widget.commission;
    final isRejected = comm.status.toLowerCase() == 'rejected';
    final isPaid = comm.status.toLowerCase() == 'paid';
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Commission Payment Upload'),
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
                          style: TextStyle(fontSize: 16, color: Colors.grey),
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
                      'Rs. ${comm.amount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff00E5FF),
                      ),
                    ),
                    if (comm.partModelName != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Part: ${comm.partModelName}',
                        style: theme.textTheme.bodyMedium,
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
                        'Your previous receipt photo was rejected. Please upload a clear photo of your payment receipt.',
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
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xffCCCCCC)),
              ),
              child: const Text(
                'Pay this amount via Bank Transfer / JazzCash / EasyPaisa:\n'
                '• Bank: HBL Account # 1234-5678-9012\n'
                '• JazzCash / EasyPaisa: +92 311 7595866\n'
                'Take a screenshot or photo of your payment receipt and upload it below.',
                style: TextStyle(color: Color(0xff212121), fontSize: 13, height: 1.4),
              ),
            ),
            const SizedBox(height: 24),

            if (!isPaid) ...[
              const Text(
                'Upload Payment Receipt Photo',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              // Image Selector Container
              GestureDetector(
                onTap: () => _pickPhoto(ImageSource.gallery),
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _selectedPhoto != null ? const Color(0xff00E676) : const Color(0xffCCCCCC), width: 2),
                  ),
                  child: _selectedPhoto != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: kIsWeb
                              ? Image.network(_selectedPhoto!.path, fit: BoxFit.cover)
                              : Image.file(File(_selectedPhoto!.path), fit: BoxFit.cover),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.add_a_photo_rounded, size: 48, color: Color(0xff00E5FF)),
                            const SizedBox(height: 10),
                            const Text(
                              'Tap to Select Receipt Photo from Device',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            Text('Supports JPG, PNG (Max 5MB)', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickPhoto(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_rounded),
                      label: const Text('From Gallery'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickPhoto(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt_rounded),
                      label: const Text('Take Camera Photo'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _handleSubmitProof,
                  icon: _isSubmitting
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.cloud_upload_rounded),
                  label: Text(
                    _isSubmitting ? 'Uploading Receipt Photo...' : (isRejected ? 'Resubmit Receipt Photo' : 'Upload Receipt Photo & Submit'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff00E676),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ] else
              const Center(
                child: Text(
                  '✅ Payment Verified & Paid',
                  style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
