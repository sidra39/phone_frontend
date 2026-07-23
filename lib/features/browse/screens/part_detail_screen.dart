import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/api_constants.dart';
import '../../auth/screens/login_screen.dart';
import '../../auth/screens/register_customer_screen.dart';
import '../../auth/services/auth_provider.dart';
import '../../customer/models/review_model.dart';
import '../../customer/services/customer_service.dart';
import '../services/browse_service.dart';

/// PartDetailScreen
/// Displays comprehensive details for a specific phone part, vendor shop information, customer reviews,
/// and a login-gated "Request This Part" ordering workflow.
class PartDetailScreen extends StatefulWidget {
  final int partId;

  const PartDetailScreen({super.key, required this.partId});

  @override
  State<PartDetailScreen> createState() => _PartDetailScreenState();
}

class _PartDetailScreenState extends State<PartDetailScreen> {
  final BrowseService _browseService = BrowseService();
  final CustomerService _customerService = CustomerService();

  Map<String, dynamic>? _partData;
  List<ReviewModel> _reviews = [];

  bool _isLoading = true;
  bool _isRequesting = false;
  int _galleryIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadPartDetailsAndReviews();
  }

  Future<void> _loadPartDetailsAndReviews() async {
    try {
      final part = await _browseService.getPartDetails(widget.partId);
      final vendorId = part['vendor_id'];

      List<ReviewModel> reviews = [];
      if (vendorId != null) {
        try {
          reviews = await _browseService.getVendorReviews(vendorId);
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          _partData = part;
          _reviews = reviews;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        final msg = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _handleRequestAction() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (authProvider.token == null || authProvider.currentUser == null) {
      // Guest User -> Prompt Login/Signup Dialog
      _showAuthPromptDialog();
    } else {
      final role = authProvider.currentUser!.role.toLowerCase();
      if (role == 'customer') {
        _submitPartRequest(authProvider.token!);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Only customer accounts can request parts'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  void _showAuthPromptDialog() {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Account Required', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
          'Please sign in or create a customer account to request phone components directly from vendors.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RegisterCustomerScreen(returnToPartId: widget.partId),
                ),
              );
            },
            child: const Text('Sign Up'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LoginScreen(returnToPartId: widget.partId),
                ),
              );
            },
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitPartRequest(String token) async {
    setState(() => _isRequesting = true);
    try {
      await _customerService.createRequest(token, widget.partId);
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: Theme.of(ctx).cardColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('✅ Request Sent!'),
            content: const Text(
              'Your component request has been sent to the vendor. You will be notified as soon as they confirm availability.',
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
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
        setState(() => _isRequesting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loading Details...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_partData == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Part Details')),
        body: const Center(child: Text('Part listing not found')),
      );
    }

    final relativePhotoUrl = _partData!['original_photo_url'] ?? _partData!['image_url'];
    final String? fullPhotoUrl = relativePhotoUrl != null && relativePhotoUrl.toString().isNotEmpty
        ? '${ApiConstants.baseUrl}$relativePhotoUrl'
        : null;

    final relativeBarcodePhotoUrl = _partData!['barcode_photo_url'];
    final String? fullBarcodePhotoUrl = relativeBarcodePhotoUrl != null && relativeBarcodePhotoUrl.toString().isNotEmpty
        ? '${ApiConstants.baseUrl}$relativeBarcodePhotoUrl'
        : null;
    final String barcodeNumber = _partData!['barcode_number'] ?? 'N/A';

    final double price = double.tryParse((_partData!['price'] ?? 0).toString()) ?? 0.0;
    final String condition = (_partData!['condition_type'] ?? 'new').toString().toUpperCase();
    final int stock = int.tryParse((_partData!['stock_quantity'] ?? 1).toString()) ?? 1;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.cardColor,
        elevation: 1,
        title: Text(_partData!['model_name'] ?? 'Part Details', style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Swipeable Image Gallery (Product Photo & Barcode Photo)
            Column(
              children: [
                Container(
                  height: 220,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xffE2E8F0)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: PageView(
                      onPageChanged: (idx) {
                        setState(() {
                          _galleryIndex = idx;
                        });
                      },
                      children: [
                        // Slide 1: Original Product Photo
                        fullPhotoUrl != null
                            ? Image.network(
                                fullPhotoUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (c, e, s) => const Icon(Icons.broken_image_rounded, size: 60, color: Colors.grey),
                              )
                            : const Icon(Icons.image_search_rounded, size: 60, color: Colors.grey),
                        // Slide 2: Barcode Packaging Photo
                        fullBarcodePhotoUrl != null
                            ? Image.network(
                                fullBarcodePhotoUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (c, e, s) => const Icon(Icons.broken_image_rounded, size: 60, color: Colors.grey),
                              )
                            : const Icon(Icons.qr_code_2_rounded, size: 60, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Dot Indicators
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _galleryIndex == 0 ? theme.primaryColor : Colors.grey.shade400,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _galleryIndex == 1 ? theme.primaryColor : Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Title & Price Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _partData!['model_name'] ?? '',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_partData!['brand_name'] ?? ''} • ${_partData!['part_type_name'] ?? ''}',
                        style: TextStyle(fontSize: 14, color: theme.textTheme.bodyMedium?.color),
                      ),
                    ],
                  ),
                ),
                Text(
                  '\$${price.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: theme.primaryColor),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Specs Pill Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.primaryColor.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    'CONDITION: $condition',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: theme.primaryColor),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xffE2E8F0)),
                  ),
                  child: Text(
                    'STOCK: $stock AVAILABLE',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: theme.textTheme.bodyMedium?.color),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Vendor Shop Info Card
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xffE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.storefront_rounded, color: theme.primaryColor, size: 24),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _partData!['shop_name'] ?? 'Vendor Shop',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Location: ${_partData!['vendor_address'] ?? ''}, ${_partData!['vendor_city'] ?? ''}',
                    style: TextStyle(fontSize: 13, color: theme.textTheme.bodyMedium?.color),
                  ),
                ],
              ),
            ),
            // Authenticity Verification Details Card
            const Text(
              'Authenticity Verification Details',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xffE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Manufacturer Barcode / QR:',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.primaryColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          barcodeNumber,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: theme.primaryColor,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      // Product Photo preview
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              height: 120,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: theme.scaffoldBackgroundColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xffE2E8F0)),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: fullPhotoUrl != null
                                    ? Image.network(fullPhotoUrl, fit: BoxFit.cover)
                                    : const Icon(Icons.image_rounded, color: Colors.grey),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text('Original Product Photo', style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Barcode Photo preview
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              height: 120,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: theme.scaffoldBackgroundColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xffE2E8F0)),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: fullBarcodePhotoUrl != null
                                    ? Image.network(fullBarcodePhotoUrl, fit: BoxFit.cover)
                                    : const Icon(Icons.qr_code_2_rounded, color: Colors.grey, size: 36),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text('Barcode Packaging Photo', style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Customer Reviews Header
            Text(
              'Vendor Reviews & Feedback',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color),
            ),
            const SizedBox(height: 12),

            _reviews.isEmpty
                ? Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xffCCCCCC)),
                    ),
                    child: const Center(
                      child: Text('No reviews submitted for this vendor yet', style: TextStyle(color: Colors.grey)),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _reviews.length,
                    itemBuilder: (ctx, idx) {
                      final rev = _reviews[idx];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xffCCCCCC)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  rev.customerName ?? 'Verified Customer',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                Row(
                                  children: [
                                    const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                                    const SizedBox(width: 2),
                                    Text('${rev.rating}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  ],
                                ),
                              ],
                            ),
                            if (rev.comment != null && rev.comment!.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(rev.comment!, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
            const SizedBox(height: 80), // Space for bottom fixed bar
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: theme.cardColor,
          border: const Border(top: BorderSide(color: Color(0xffCCCCCC))),
        ),
        child: SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed: _isRequesting ? null : _handleRequestAction,
            child: _isRequesting
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text(
                    'Request This Part',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
      ),
    );
  }
}
