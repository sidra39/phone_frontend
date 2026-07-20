import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/part_model.dart';

/// PartQrScreen
/// Renders the QR code for a specific part listing with a cyber-glowing card frame.
class PartQrScreen extends StatelessWidget {
  final PartModel part;

  const PartQrScreen({super.key, required this.part});

  @override
  Widget build(BuildContext context) {
    final String token = part.qrToken ?? 'NO_TOKEN_GENERATED';

    return Scaffold(
      backgroundColor: const Color(0xff12141C),
      appBar: AppBar(
        backgroundColor: const Color(0xff1A1D27),
        elevation: 0,
        title: const Text('Part QR Security Pass', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Glowing QR Frame Container
              Container(
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: const Color(0xff1A1D27),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xff00E5FF).withValues(alpha: 0.5), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xff00E5FF).withValues(alpha: 0.15),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: QrImageView(
                    data: token,
                    version: QrVersions.auto,
                    size: 230.0,
                    backgroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 28),

              Text(
                part.modelName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                '${part.brandName ?? 'Brand #${part.brandId}'} • ${part.partTypeName ?? 'Type #${part.partTypeId}'}',
                style: TextStyle(fontSize: 15, color: Colors.grey.shade400),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xff00E5FF).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xff00E5FF).withValues(alpha: 0.5)),
                ),
                child: Text(
                  '\$${part.price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 20,
                    color: Color(0xff00E5FF),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 28),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xff1A1D27),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xff2A2E3D)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified_user_rounded, color: Color(0xff00E676), size: 24),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'Attach or display this QR token with the component so customers can verify authenticity live.',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade300, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
