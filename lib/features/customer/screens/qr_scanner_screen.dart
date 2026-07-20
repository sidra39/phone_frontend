import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/customer_service.dart';

/// QrScannerScreen
/// Uses live camera feed with a glowing cyber target box to scan QR codes on phone parts and verify authenticity.
class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final CustomerService _customerService = CustomerService();
  final MobileScannerController _scannerController = MobileScannerController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? token = barcodes.first.rawValue;
    if (token == null || token.trim().isEmpty) return;

    setState(() => _isProcessing = true);

    try {
      final verificationData = await _customerService.verifyPartByQr(token.trim());
      if (mounted) {
        _showResultDialog(isValid: true, data: verificationData);
      }
    } catch (e) {
      if (mounted) {
        _showResultDialog(isValid: false, errorMessage: 'Invalid QR — component could not be verified in registry');
      }
    }
  }

  void _showResultDialog({
    required bool isValid,
    Map<String, dynamic>? data,
    String? errorMessage,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xff1A1D27),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        if (!isValid) {
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xffFF5252).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.cancel_rounded, color: Color(0xffFF5252), size: 54),
                ),
                const SizedBox(height: 16),
                Text(
                  errorMessage ?? 'Invalid QR — this part could not be verified',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xffFF5252),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      setState(() => _isProcessing = false);
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xffFF5252)),
                    child: const Text('Scan Again', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          );
        }

        final part = data?['part'] ?? {};
        final vendor = data?['vendor'] ?? {};

        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xff00E676).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xff00E676)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified_rounded, color: Color(0xff00E676), size: 20),
                      SizedBox(width: 8),
                      Text(
                        'GENUINE PART VERIFIED',
                        style: TextStyle(color: Color(0xff00E676), fontWeight: FontWeight.bold, letterSpacing: 0.5),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                part['model_name'] ?? 'Phone Component',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 6),
              Text(
                'Brand: ${part['brand_name'] ?? 'N/A'} • Type: ${part['part_type_name'] ?? 'N/A'}',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              ),
              Text(
                'Condition: ${(part['condition_type'] ?? 'new').toString().toUpperCase()}',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              ),
              const SizedBox(height: 10),
              Text(
                'Listed Price: \$${double.tryParse(part['price'].toString())?.toStringAsFixed(2) ?? '0.00'}',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xff00E5FF)),
              ),
              const SizedBox(height: 16),
              const Divider(color: Color(0xff2A2E3D), height: 1),
              const SizedBox(height: 14),
              const Text(
                'Registered Vendor Shop',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
              ),
              const SizedBox(height: 6),
              Text('Shop: ${vendor['shop_name'] ?? 'N/A'}', style: TextStyle(color: Colors.grey.shade300)),
              Text('City: ${vendor['city'] ?? 'N/A'}', style: TextStyle(color: Colors.grey.shade400)),
              Text('Address: ${vendor['address'] ?? 'N/A'}', style: TextStyle(color: Colors.grey.shade400)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    setState(() => _isProcessing = false);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff00E5FF),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Scan Another Part', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    ).then((_) {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff12141C),
      appBar: AppBar(
        backgroundColor: const Color(0xff1A1D27),
        elevation: 0,
        title: const Text('Verify QR Code', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _scannerController,
            onDetect: _onDetect,
          ),
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xff00E5FF), width: 3),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xff00E5FF).withValues(alpha: 0.2),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xff1A1D27).withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xff2A2E3D)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.qr_code_scanner_rounded, color: Color(0xff00E5FF), size: 20),
                    SizedBox(width: 10),
                    Text(
                      'Align part QR code inside box to verify',
                      style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
