import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/api_constants.dart';
import '../../auth/services/auth_provider.dart';
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

  Future<void> _startScanner() async {
    try {
      await _scannerController.start();
    } catch (e) {
      debugPrint('Error starting scanner: $e');
    }
  }

  Future<void> _stopScanner() async {
    try {
      await _scannerController.stop();
    } catch (e) {
      debugPrint('Error stopping scanner: $e');
    }
  }

  void _showMockScanDialog() {
    final TextEditingController mockController = TextEditingController(
      text: (_partData?['barcode_number'] ?? '').toString().trim(),
    );

    showDialog(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(context);
        return AlertDialog(
          backgroundColor: theme.cardColor,
          title: Row(
            children: [
              Icon(Icons.developer_mode_rounded, color: theme.primaryColor),
              const SizedBox(width: 8),
              Text(
                'Developer Mock Scan',
                style: TextStyle(
                  color: theme.textTheme.bodyLarge?.color,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter a barcode/QR number to simulate a physical scan. Useful for browser environments without a webcam.',
                style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: mockController,
                autofocus: true,
                style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                decoration: InputDecoration(
                  labelText: 'Scanned Value',
                  hintText: 'e.g. 194252684892',
                  labelStyle: TextStyle(color: theme.textTheme.bodyMedium?.color),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xffCCCCCC)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: theme.primaryColor, width: 2),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                final String val = mockController.text.trim();
                Navigator.pop(ctx);
                _simulateScan(val);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Simulate Scan'),
            ),
          ],
        );
      },
    );
  }

  void _simulateScan(String scannedValue) {
    if (_partData == null) return;
    _isScanProcessing = true;
    _stopScanner();
    _processScanVerification(scannedValue.trim());
  }

  @override
  void dispose() {
    _stopScanner();
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
      Future.delayed(const Duration(milliseconds: 250), () {
        if (mounted) {
          _startScanner();
        }
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

  void _onDetect(BarcodeCapture capture) {
    if (_isScanProcessing || _partData == null) return;
    _isScanProcessing = true;
    _stopScanner();

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) {
      _isScanProcessing = false;
      _startScanner();
      return;
    }

    String? rawValue;
    for (final barcode in barcodes) {
      final val = barcode.rawValue ?? barcode.displayValue;
      if (val != null && val.trim().isNotEmpty) {
        rawValue = val;
        break;
      }
    }
    
    if (rawValue == null) {
      _isScanProcessing = false;
      _startScanner();
      return;
    }

    _processScanVerification(rawValue.trim());
  }

  Future<void> _processScanVerification(String scannedValue) async {
    final String expectedBarcode = (_partData?['barcode_number'] ?? '').toString().trim();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    bool isMatch = scannedValue.toLowerCase() == expectedBarcode.toLowerCase();
    bool isDuplicateReuse = false;
    String serverMsg = '';
    int? prevRequestId;

    if (token != null) {
      try {
        final res = await _customerService.verifyDelivery(token, widget.partId, widget.requestId, scannedValue);
        isMatch = res['is_match'] == true;
        isDuplicateReuse = res['is_duplicate_reuse'] == true;
        serverMsg = res['message'] ?? '';
        if (res['previous_request_id'] != null) {
          prevRequestId = res['previous_request_id'];
        }
      } catch (e) {
        debugPrint('Backend delivery verification error: $e');
      }
    }

    if (isDuplicateReuse) {
      if (mounted) {
        _showFakeQrAlertSheet(
          scannedBarcode: scannedValue,
          previousRequestId: prevRequestId,
          serverMessage: serverMsg,
        );
      }
      return;
    }

    if (isMatch) {
      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        Navigator.pop(context);
        messenger.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.verified_rounded, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    serverMsg.isNotEmpty ? serverMsg : 'Verified: Product is authentic! Go ahead.',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      return;
    }

    if (mounted) {
      _showVerificationResult(
        isMatch: isMatch,
        scannedBarcode: scannedValue,
        expectedBarcode: expectedBarcode,
      );
    }
  }

  void _showFakeQrAlertSheet({
    required String scannedBarcode,
    int? previousRequestId,
    required String serverMessage,
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
                  color: Colors.red.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.gpp_bad_rounded,
                  color: Color(0xffFF5252),
                  size: 54,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '🚨 SECURITY ALERT: FAKE / COPIED PRODUCT',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xffFF5252),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                serverMessage.isNotEmpty
                    ? serverMessage
                    : 'This Barcode/QR Code ($scannedBarcode) was ALREADY scanned & verified in a previous delivery order${previousRequestId != null ? " (#$previousRequestId)" : ""}. Reusing old QR code labels indicates a copied or fake product!',
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 13),
              ),
              const SizedBox(height: 24),
              if (vendorUserId != null) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx, true);
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
                    label: const Text('Report Fraudulent Vendor Now', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xffFF5252),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(ctx, false);
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xffCCCCCC)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Scan Another Package', style: TextStyle(color: Color(0xff212121))),
                ),
              ),
            ],
          ),
        );
      },
    ).then((finished) {
      if (mounted) {
        if (finished == true) return;
        setState(() => _isScanProcessing = false);
        _startScanner();
      }
    });
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
                isMatch ? '✅ Verified — Product is Authentic!' : '⚠️ MISMATCH DETECTED — CODE DOES NOT MATCH',
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
                    ? 'The physically scanned Barcode/QR matches the vendor\'s declared product code. Verification successful!'
                    : 'The scanned code does not match what the vendor declared. Verification failed automatically.',
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(
                          width: 110,
                          child: Text('Declared Code:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ),
                        Expanded(
                          child: Text(
                            expectedBarcode.isEmpty ? 'N/A' : expectedBarcode,
                            textAlign: TextAlign.end,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'monospace', fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 3,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 16, color: Color(0xffCCCCCC)),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(
                          width: 110,
                          child: Text('Scanned Code:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ),
                        Expanded(
                          child: Text(
                            scannedBarcode,
                            textAlign: TextAlign.end,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                              fontSize: 12,
                              color: isMatch ? const Color(0xff00E676) : const Color(0xffFF5252),
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 3,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              if (isMatch) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      final messenger = ScaffoldMessenger.of(context);
                      Navigator.pop(ctx, true);
                      Navigator.pop(context);
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Delivery verified successfully!'), backgroundColor: Colors.green),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Finish Verification', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(ctx, false);
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xffCCCCCC)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Scan Again', style: TextStyle(color: Color(0xff212121))),
                      ),
                    ),
                    if (vendorUserId != null) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx, true);
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
                          icon: const Icon(Icons.report_problem_rounded, size: 16),
                          label: const Text('Report Vendor', style: TextStyle(fontWeight: FontWeight.bold)),
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
            ],
          ),
        );
      },
    ).then((finished) {
      if (mounted) {
        if (finished == true) return;
        setState(() => _isScanProcessing = false);
        _startScanner();
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
        actions: [
          IconButton(
            tooltip: 'Simulate Mock Scan (For testing without camera)',
            icon: const Icon(Icons.developer_mode_rounded, color: Colors.amber),
            onPressed: () => _showMockScanDialog(),
          ),
        ],
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
                            errorBuilder: (context, error, child) {
                              return Container(
                                color: Colors.black87,
                                padding: const EdgeInsets.all(24),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Colors.red.withValues(alpha: 0.15),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.videocam_off_rounded,
                                          color: Colors.redAccent,
                                          size: 54,
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      const Text(
                                        'Camera Error / Permission Required',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        error.errorCode == MobileScannerErrorCode.permissionDenied
                                            ? 'Camera access was denied. If on a browser, click the video camera icon in your browser URL bar to allow camera access.'
                                            : kIsWeb && error.errorCode == MobileScannerErrorCode.unsupported
                                                ? 'Unsupported context. Web browsers restrict camera access to Secure Contexts (HTTPS or localhost). If you are accessing this app via a local network IP address, you must configure SSL/HTTPS or run on localhost.'
                                                : 'Could not initialize camera: ${error.errorDetails?.toString() ?? error.errorCode.name}',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 13,
                                          height: 1.4,
                                        ),
                                      ),
                                      const SizedBox(height: 28),
                                      Wrap(
                                        spacing: 12,
                                        runSpacing: 12,
                                        alignment: WrapAlignment.center,
                                        children: [
                                          ElevatedButton.icon(
                                            onPressed: () => _startScanner(),
                                            icon: const Icon(Icons.refresh_rounded, size: 18),
                                            label: const Text('Try Again'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: theme.primaryColor,
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 16,
                                                vertical: 12,
                                              ),
                                            ),
                                          ),
                                          OutlinedButton.icon(
                                            onPressed: () => _showMockScanDialog(),
                                            icon: const Icon(Icons.developer_mode_rounded, size: 18, color: Colors.amber),
                                            label: const Text('Mock Scan', style: TextStyle(color: Colors.amber)),
                                            style: OutlinedButton.styleFrom(
                                              side: const BorderSide(color: Colors.amber),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 16,
                                                vertical: 12,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                          Center(
                            child: SizedBox(
                              width: 270,
                              height: 180,
                              child: Stack(
                                children: [
                                  Container(
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
                                  const ClipRRect(
                                    borderRadius: BorderRadius.all(Radius.circular(16)),
                                    child: ScannerLaserLine(),
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

class ScannerLaserLine extends StatefulWidget {
  const ScannerLaserLine({super.key});

  @override
  State<ScannerLaserLine> createState() => _ScannerLaserLineState();
}

class _ScannerLaserLineState extends State<ScannerLaserLine> with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return Stack(
          children: [
            Positioned(
              top: 10 + _animController.value * 160, // 180 height - 20 padding
              left: 10,
              right: 10,
              child: Container(
                height: 3,
                decoration: BoxDecoration(
                  color: theme.primaryColor,
                  boxShadow: [
                    BoxShadow(
                      color: theme.primaryColor.withValues(alpha: 0.8),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
