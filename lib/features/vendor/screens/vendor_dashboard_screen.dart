import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../auth/services/auth_provider.dart';
import '../services/vendor_service.dart';
import 'leads_screen.dart';
import 'my_commissions_screen.dart';
import 'my_parts_screen.dart';
import 'vendor_profile_screen.dart';
import '../../browse/screens/browse_home_screen.dart';
import '../../chat/screens/chat_rooms_screen.dart';

/// VendorDashboardScreen
/// Permanent shell navigation bar for Vendor across Browse, My Parts, Leads, Commissions, Chats, and Profile.
/// Automatically displays a 15-second delayed Security Deposit Notice popup modal for newly registered/unpaid vendors.
class VendorDashboardScreen extends StatefulWidget {
  final int initialIndex;
  const VendorDashboardScreen({super.key, this.initialIndex = 0});

  static VendorDashboardScreenState? of(BuildContext context) {
    return context.findAncestorStateOfType<VendorDashboardScreenState>();
  }

  @override
  State<VendorDashboardScreen> createState() => VendorDashboardScreenState();
}

class VendorDashboardScreenState extends State<VendorDashboardScreen> {
  late int _currentIndex;
  Timer? _depositPopupTimer;
  bool _hasPopupBeenShown = false;

  final List<Widget> _screens = const [
    BrowseHomeScreen(),
    MyPartsScreen(),
    LeadsScreen(),
    MyCommissionsScreen(),
    ChatRoomsScreen(),
    VendorProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _start15SecondSecurityDepositTimer();
  }

  @override
  void dispose() {
    _depositPopupTimer?.cancel();
    super.dispose();
  }

  void _start15SecondSecurityDepositTimer() {
    _depositPopupTimer?.cancel();
    _depositPopupTimer = Timer(const Duration(seconds: 15), () {
      if (mounted && !_hasPopupBeenShown) {
        _checkAndShowSecurityDepositPopup();
      }
    });
  }

  void _checkAndShowSecurityDepositPopup() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.refreshProfile();
    if (!mounted) return;
    final user = authProvider.user;

    if (user != null && user.role == 'vendor') {
      final depositStatus = user.securityDepositStatus?.toLowerCase();
      if (depositStatus != 'paid') {
        _hasPopupBeenShown = true;
        _showSecurityDepositModalSheet();
      }
    }
  }

  void _showSecurityDepositModalSheet() {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    final depositAmount = user?.securityDepositAmount ?? 500.00;
    const depositPhone = '+92 311 7595866';

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
                  color: Colors.amber.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  color: Colors.amber,
                  size: 54,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '🛡️ Vendor Security Deposit Required',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.amber,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber),
                ),
                child: Text(
                  'Rs. ${depositAmount.toStringAsFixed(0)} Security Deposit — Refundable',
                  style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
              const SizedBox(height: 16),

              // Exact Urdu/English Message as requested
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xffCCCCCC)),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Please send the refundable Security Deposit to the number below via JazzCash or EasyPaisa ONLY. Once deposited, your vendor account will be enabled to respond to customer leads.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, height: 1.4, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xff00E5FF)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.phone_android_rounded, color: Color(0xff00E5FF), size: 20),
                              SizedBox(width: 8),
                              SelectableText(
                                depositPhone,
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xff00E5FF)),
                              ),
                            ],
                          ),
                          ElevatedButton.icon(
                            onPressed: () {
                              Clipboard.setData(const ClipboardData(text: depositPhone));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Phone number copied to clipboard!')),
                              );
                            },
                            icon: const Icon(Icons.copy_rounded, size: 14),
                            label: const Text('Copy', style: TextStyle(fontSize: 12)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xff00E5FF),
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Accepted Payment Methods: JazzCash & EasyPaisa ONLY',
                      style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showDepositProofUploadDialog();
                      },
                      icon: const Icon(Icons.upload_file_rounded, size: 18),
                      label: const Text('Submit Payment Receipt URL', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xffCCCCCC)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Remind Me Later', style: TextStyle(color: Color(0xff212121))),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDepositProofUploadDialog() {
    XFile? pickedPhoto;
    final vendorService = VendorService();
    final ImagePicker picker = ImagePicker();

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Upload Deposit Receipt Photo', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Select a clear screenshot or photo of your JazzCash/EasyPaisa deposit receipt:',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 14),
              GestureDetector(
                onTap: () async {
                  final img = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
                  if (img != null) {
                    setDialogState(() => pickedPhoto = img);
                  }
                },
                child: Container(
                  height: 140,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: pickedPhoto != null ? const Color(0xff00E676) : const Color(0xffCCCCCC),
                      width: 2,
                    ),
                  ),
                  child: pickedPhoto != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: kIsWeb
                              ? Image.network(pickedPhoto!.path, fit: BoxFit.cover)
                              : Image.file(File(pickedPhoto!.path), fit: BoxFit.cover),
                        )
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo_rounded, size: 36, color: Colors.amber),
                            SizedBox(height: 8),
                            Text('Tap to Select Receipt Photo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final img = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
                        if (img != null) {
                          setDialogState(() => pickedPhoto = img);
                        }
                      },
                      icon: const Icon(Icons.photo_library_rounded, size: 16),
                      label: const Text('Gallery', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final img = await picker.pickImage(source: ImageSource.camera, imageQuality: 85);
                        if (img != null) {
                          setDialogState(() => pickedPhoto = img);
                        }
                      },
                      icon: const Icon(Icons.camera_alt_rounded, size: 16),
                      label: const Text('Camera', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (pickedPhoto == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select a receipt photo first'), backgroundColor: Colors.red),
                  );
                  return;
                }

                final token = Provider.of<AuthProvider>(context, listen: false).token;
                if (token == null) return;

                Navigator.pop(dialogCtx);
                try {
                  final bytes = await pickedPhoto!.readAsBytes();
                  final filename = pickedPhoto!.name;
                  await vendorService.submitSecurityDepositProof(
                    token,
                    depositProofBytes: bytes,
                    filename: filename,
                    depositProofPath: pickedPhoto!.path,
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✅ Security Deposit receipt photo uploaded! Admin will verify shortly.'),
                        backgroundColor: Colors.green,
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
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black),
              child: const Text('Upload & Submit Proof', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void setTab(int index) {
    if (index >= 0 && index < _screens.length) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          border: const Border(
            top: BorderSide(color: Color(0xffCCCCCC), width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: Theme.of(context).primaryColor,
          unselectedItemColor: Colors.grey.shade600,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
          unselectedLabelStyle: const TextStyle(fontSize: 9),
          type: BottomNavigationBarType.fixed,
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.explore_outlined),
              activeIcon: Icon(Icons.explore_rounded, color: Theme.of(context).primaryColor),
              label: 'Browse',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.inventory_2_outlined),
              activeIcon: Icon(Icons.inventory_2_rounded, color: Theme.of(context).primaryColor),
              label: 'My Parts',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.receipt_long_rounded),
              activeIcon: Icon(Icons.receipt_long_rounded, color: Theme.of(context).primaryColor),
              label: 'Leads',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.payments_rounded),
              activeIcon: Icon(Icons.payments_rounded, color: Theme.of(context).primaryColor),
              label: 'Commissions',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.chat_bubble_outline_rounded),
              activeIcon: Icon(Icons.chat_bubble_rounded, color: Theme.of(context).primaryColor),
              label: 'Chats',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.storefront_rounded),
              activeIcon: Icon(Icons.storefront_rounded, color: Theme.of(context).primaryColor),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
