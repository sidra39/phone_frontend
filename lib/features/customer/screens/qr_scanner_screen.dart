import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/constants/api_constants.dart';
import '../../reports/screens/submit_report_screen.dart';
import '../services/customer_service.dart';

/// QrScannerScreen
/// Rebuilt as Delivery Verification flow: compares physically scanned barcode against the vendor's declared listing & reference photos.
class QrScannerScreen extends StatefulWidget {
  final int partId;
  final int? requestId;

  const QrScannerScreen({
    super.key,
    required this.partId,
    this.requestId,
  });

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final CustomerService _customerService = CustomerService();
  final MobileScannerController _scannerController = MobileScannerController();

  Map<String, dynamic>? _partData;
  bool _isLoading = true;
  bool _isScanProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadPartDetails();
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _loadPartDetails() async {
    try {
      final data = await _customerService.getPartDetails(widget.partId);
      setState(() {
        _partData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        final msg = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load part details: $msg'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isScanProcessing || _partData == null) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? rawValue = barcodes.first.rawValue;
    if (rawValue == null || rawValue.trim().isEmpty) return;

    setState(() => _isScanProcessing = true);

    final String scannedValue = rawValue.trim();
    final String expectedBarcode = (_partData!['barcode_number'] ?? '').toString().trim();

    final bool isMatch = scannedValue.toLowerCase() == expectedBarcode.toLowerCase();

    if (mounted) {
      _showVerificationResult(
        isMatch: isMatch,
        scannedBarcode: scannedValue,
        expectedBarcode: expectedBarcode,
      );
    }
  }

  void _showVerificationResult({
    required bool isMatch,
    required String scannedBarcode,
    required String expectedBarcode,
  }) {
    final theme = Theme.of(context);
    final int? vendorUserId = _partData?['vendor_user_id'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: (isMatch ? const Color(0xff00E676) : const Color(0xffFF5252)).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isMatch ? Icons.verified_rounded : Icons.warning_amber_rounded,
                  color: isMatch ? const Color(0xff00E676) : const Color(0xffFF5252),
                  size: 54,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isMatch
                    ? '✅ Verified — Barcode Matches Listing'
                    : '⚠️ Mismatch — Barcode Does Not Match',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isMatch ? const Color(0xff00E676) : const Color(0xffFF5252),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                isMatch
                    ? 'The physically scanned barcode matches the vendor\'s declared product listing.'
                    : 'The scanned barcode ($scannedBarcode) does not match what the vendor declared ($expectedBarcode).',
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 13),
              ),
              const SizedBox(height: 20),

              // Expected vs Scanned Comparison Table
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xffCCCCCC)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Declared Barcode:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        Text(
                          expectedBarcode.isEmpty ? 'N/A' : expectedBarcode,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'monospace', fontSize: 13),
                        ),
                      ],
                    ),
                    const Divider(height: 16, color: Color(0xffCCCCCC)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Scanned Barcode:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        Text(
                          scannedBarcode,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                            fontSize: 13,
                            color: isMatch ? const Color(0xff00E676) : const Color(0xffFF5252),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        setState(() => _isScanProcessing = false);
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xffCCCCCC)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Scan Again', style: TextStyle(color: Color(0xff212121))),
                    ),
                  ),
                  if (!isMatch && vendorUserId != null) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SubmitReportScreen(
                                reportedUserId: vendorUserId,
                                requestId: widget.requestId,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.report_problem_rounded, size: 18),
                        label: const Text('Report Vendor'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xffFF5252),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    ).then((_) {
      if (mounted) {
        setState(() => _isScanProcessing = false);
      }
    });
  }

  Widget _buildReferencePhoto(String label, String? relativeUrl) {
    final theme = Theme.of(context);
    final String? fullUrl = relativeUrl != null && relativeUrl.isNotEmpty
        ? '${ApiConstants.baseUrl}$relativeUrl'
        : null;

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 6),
          Container(
            height: 90,
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xffCCCCCC)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: fullUrl != null
                  ? Image.network(
                      fullUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (ctx, err, stack) => const Center(
                        child: Icon(Icons.broken_image_rounded, color: Colors.grey),
                      ),
                    )
                  : const Center(
                      child: Icon(Icons.image_search_rounded, color: Colors.grey),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.cardColor,
        elevation: 1,
        title: const Text('Verify Delivery Authenticity', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _partData == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Failed to load part info for verification'),
                      const SizedBox(height: 12),
                      ElevatedButton(onPressed: _loadPartDetails, child: const Text('Retry')),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Reference Photos & Info Panel
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        border: const Border(
                          bottom: BorderSide(color: Color(0xffCCCCCC)),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _partData!['model_name'] ?? 'Part Item',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xff212121)),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: theme.primaryColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'EXPECTED: ${_partData!['barcode_number'] ?? 'N/A'}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: theme.primaryColor,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Visual Reference Photos Row
                          Row(
                            children: [
                              _buildReferencePhoto(
                                'Vendor Listing Photo',
                                _partData!['original_photo_url'],
                              ),
                              const SizedBox(width: 12),
                              _buildReferencePhoto(
                                'Vendor Barcode Photo',
                                _partData!['barcode_photo_url'],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Barcode Live Camera Scanner Section
                    Expanded(
                      child: Stack(
                        children: [
                          MobileScanner(
                            controller: _scannerController,
                            onDetect: _onDetect,
                          ),
                          Center(
                            child: Container(
                              width: 270,
                              height: 180,
                              decoration: BoxDecoration(
                                border: Border.all(color: theme.primaryColor, width: 3),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: theme.primaryColor.withValues(alpha: 0.25),
                                    blurRadius: 16,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 30,
                            left: 20,
                            right: 20,
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: theme.cardColor.withValues(alpha: 0.95),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: const Color(0xffE2E8F0)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.qr_code_scanner_rounded, color: theme.primaryColor, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Align package barcode inside box to verify',
                                      style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 12, fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}
