// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/api_constants.dart';
import '../../auth/screens/login_screen.dart';
import '../../auth/screens/register_customer_screen.dart';
import '../../auth/services/auth_provider.dart';
import '../../customer/models/review_model.dart';
import '../../customer/services/customer_service.dart';
import '../services/browse_service.dart';
import '../../chat/services/chat_service.dart';
import '../../chat/screens/chat_screen.dart';

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

  void _handleChatAction() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (authProvider.token == null || authProvider.currentUser == null) {
      // Guest User -> Prompt Login/Signup Dialog
      _showAuthPromptDialog();
    } else {
      final role = authProvider.currentUser!.role.toLowerCase();
      if (role == 'customer') {
        _startChatSession(authProvider.token!);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Only customer accounts can chat with vendors'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _startChatSession(String token) async {
    setState(() => _isRequesting = true);
    try {
      final chatService = ChatService();
      final room = await chatService.createOrGetRoom(token, widget.partId);
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              roomId: room.id,
              roomTitle: room.modelName,
              otherPartyName: room.otherName ?? 'Vendor',
            ),
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
    final theme = Theme.of(context);
    String selectedDeliveryType = 'home_delivery';
    final addressController = TextEditingController();
    final cityController = TextEditingController();
    final phoneController = TextEditingController();
    final notesController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Select Delivery Method',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ChoiceChip(
                              avatar: const Icon(Icons.local_shipping_rounded, size: 18),
                              label: const Text('Home Delivery'),
                              selected: selectedDeliveryType == 'home_delivery',
                              selectedColor: theme.primaryColor.withValues(alpha: 0.2),
                              onSelected: (val) {
                                if (val) setModalState(() => selectedDeliveryType = 'home_delivery');
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ChoiceChip(
                              avatar: const Icon(Icons.storefront_rounded, size: 18),
                              label: const Text('Shop Pickup'),
                              selected: selectedDeliveryType == 'shop_pickup',
                              selectedColor: theme.primaryColor.withValues(alpha: 0.2),
                              onSelected: (val) {
                                if (val) setModalState(() => selectedDeliveryType = 'shop_pickup');
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (selectedDeliveryType == 'home_delivery') ...[
                        TextFormField(
                          controller: addressController,
                          decoration: InputDecoration(
                            labelText: 'Delivery Address *',
                            hintText: 'House/Street/Area Address',
                            prefixIcon: Icon(Icons.home_rounded, color: theme.primaryColor),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          validator: (val) => val == null || val.trim().isEmpty ? 'Please enter delivery address' : null,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: cityController,
                                decoration: InputDecoration(
                                  labelText: 'City *',
                                  hintText: 'e.g. Lahore / Karachi',
                                  prefixIcon: Icon(Icons.location_city_rounded, color: theme.primaryColor),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                validator: (val) => val == null || val.trim().isEmpty ? 'Enter city' : null,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                controller: phoneController,
                                keyboardType: TextInputType.phone,
                                decoration: InputDecoration(
                                  labelText: 'Contact Phone *',
                                  hintText: '03001234567',
                                  prefixIcon: Icon(Icons.phone_rounded, color: theme.primaryColor),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                validator: (val) => val == null || val.trim().isEmpty ? 'Enter contact phone' : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: notesController,
                          decoration: InputDecoration(
                            labelText: 'Delivery Instructions (Optional)',
                            hintText: 'Call before arriving / Deliver between 10am-5pm',
                            prefixIcon: Icon(Icons.note_alt_rounded, color: theme.primaryColor),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.primaryColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () async {
                            if (selectedDeliveryType == 'home_delivery') {
                              if (!formKey.currentState!.validate()) return;
                            }
                            final parentContext = context;
                            Navigator.pop(ctx);
                            setState(() => _isRequesting = true);
                            try {
                              await _customerService.createRequest(
                                token,
                                widget.partId,
                                deliveryType: selectedDeliveryType,
                                deliveryAddress: addressController.text.trim(),
                                deliveryCity: cityController.text.trim(),
                                deliveryPhone: phoneController.text.trim(),
                                deliveryNotes: notesController.text.trim(),
                              );
                              if (mounted) {
                                showDialog(
                                  context: parentContext,
                                  builder: (c) => AlertDialog(
                                    backgroundColor: theme.cardColor,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                    title: Text(
                                      selectedDeliveryType == 'home_delivery'
                                          ? '🚚 Home Delivery Requested!'
                                          : '🏪 Shop Pickup Requested!',
                                    ),
                                    content: Text(
                                      selectedDeliveryType == 'home_delivery'
                                          ? 'Your component request with Home Delivery details has been sent to the vendor. You will be notified as soon as they confirm availability & dispatch.'
                                          : 'Your component request has been sent to the vendor for shop pickup.',
                                    ),
                                    actions: [
                                      ElevatedButton(
                                        onPressed: () => Navigator.pop(c),
                                        child: const Text('OK'),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                final msg = e.toString().replaceAll('Exception: ', '');
                                ScaffoldMessenger.of(parentContext).showSnackBar(
                                  SnackBar(content: Text(msg), backgroundColor: Colors.red),
                                );
                              }
                            } finally {
                              if (mounted) {
                                setState(() => _isRequesting = false);
                              }
                            }
                          },
                          child: const Text('Confirm Request', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
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
                    color: (stock <= 0 || (_partData!['status'] ?? '').toString().toLowerCase() == 'out_of_stock')
                        ? Colors.red.withValues(alpha: 0.15)
                        : Colors.green.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: (stock <= 0 || (_partData!['status'] ?? '').toString().toLowerCase() == 'out_of_stock')
                          ? Colors.red
                          : Colors.green,
                    ),
                  ),
                  child: Text(
                    (stock <= 0 || (_partData!['status'] ?? '').toString().toLowerCase() == 'out_of_stock')
                        ? '🚫 SOLD OUT'
                        : '📦 IN STOCK: $stock AVAILABLE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: (stock <= 0 || (_partData!['status'] ?? '').toString().toLowerCase() == 'out_of_stock')
                          ? Colors.red
                          : Colors.green.shade800,
                    ),
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
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isRequesting ? null : _handleChatAction,
                  icon: const Icon(Icons.chat_bubble_outline_rounded),
                  label: const Text(
                    'Chat with Vendor',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: theme.primaryColor, width: 1.5),
                    foregroundColor: theme.primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: (_isRequesting || stock <= 0 || (_partData!['status'] ?? '').toString().toLowerCase() == 'out_of_stock')
                      ? null
                      : _handleRequestAction,
                  icon: Icon(
                    (stock <= 0 || (_partData!['status'] ?? '').toString().toLowerCase() == 'out_of_stock')
                        ? Icons.block_rounded
                        : Icons.receipt_long_rounded,
                  ),
                  label: _isRequesting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          (stock <= 0 || (_partData!['status'] ?? '').toString().toLowerCase() == 'out_of_stock')
                              ? 'SOLD OUT'
                              : 'Request Part',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: (stock <= 0 || (_partData!['status'] ?? '').toString().toLowerCase() == 'out_of_stock')
                        ? Colors.red.shade700
                        : theme.primaryColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.red.shade200,
                    disabledForegroundColor: Colors.red.shade800,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}