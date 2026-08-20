import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/widgets/notification_bell_icon.dart';
import '../../auth/services/auth_provider.dart';
import '../models/part_model.dart';
import '../services/vendor_service.dart';
import 'add_edit_part_screen.dart';

import 'vendor_dashboard_screen.dart';

/// MyPartsScreen
/// Displays vendor inventory list with cyber-glassmorphic cards, price tags, QR actions, and stock badges.
class MyPartsScreen extends StatefulWidget {
  const MyPartsScreen({super.key});

  @override
  State<MyPartsScreen> createState() => _MyPartsScreenState();
}

class _MyPartsScreenState extends State<MyPartsScreen> {
  final VendorService _vendorService = VendorService();
  List<PartModel> _parts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadParts();
  }

  Future<void> _loadParts() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) return;

    setState(() => _isLoading = true);

    try {
      final list = await _vendorService.getMyParts(token);
      setState(() {
        _parts = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        final msg = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _handleDelete(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Inventory Part', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to delete this part listing?', style: TextStyle(color: Colors.grey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xffFF5252)),
            child: const Text('Delete Listing', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;

    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) return;

    try {
      await _vendorService.deletePart(token, id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Part deleted successfully')),
        );
        _loadParts();
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor,
        elevation: 0,
        title: const Text('Parts Inventory', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.explore_rounded, color: Color(0xff00E5FF)),
            tooltip: 'Browse Marketplace Page',
            onPressed: () {
              final dashboard = VendorDashboardScreen.of(context);
              if (dashboard != null) {
                dashboard.setTab(0);
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const VendorDashboardScreen(initialIndex: 0)),
                );
              }
            },
          ),
          const NotificationBellIcon(),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadParts,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _parts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.inventory_2_outlined, size: 48, color: Theme.of(context).primaryColor),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No parts listed in inventory',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color),
                      ),
                      const SizedBox(height: 6),
                      Text('Start listing phone components for customer search', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const AddEditPartScreen()),
                          );
                          if (result == true || mounted) {
                            _loadParts();
                          }
                        },
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Add Your First Part'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadParts,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: _parts.length,
                    itemBuilder: (context, index) {
                      final part = _parts[index];
                      final isAvailable = part.status == 'available';
                      final imageUrl = part.originalPhotoUrl != null
                          ? '${ApiConstants.baseUrl}${part.originalPhotoUrl}'
                          : null;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16.0),
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xffCCCCCC)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Thumbnail Image
                                Container(
                                  width: 70,
                                  height: 70,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).scaffoldBackgroundColor,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color(0xffCCCCCC)),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: imageUrl != null
                                        ? Image.network(
                                            imageUrl,
                                            fit: BoxFit.cover,
                                            errorBuilder: (ctx, err, stack) => const Icon(Icons.image_not_supported_rounded, color: Colors.grey),
                                          )
                                        : const Icon(Icons.image_search_rounded, color: Colors.grey),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                // Text Details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              part.modelName,
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Theme.of(context).textTheme.bodyLarge?.color,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Text(
                                            '\$${part.price.toStringAsFixed(2)}',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Theme.of(context).primaryColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${part.brandName ?? 'Brand #${part.brandId}'} • ${part.partTypeName ?? 'Type #${part.partTypeId}'}',
                                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                      ),
                                      if (part.barcodeNumber != null && part.barcodeNumber!.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          'Barcode: ${part.barcodeNumber}',
                                          style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontFamily: 'monospace'),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).primaryColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.4)),
                                  ),
                                  child: Text(
                                    part.conditionType.toUpperCase(),
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text('Stock: ${part.stockQuantity}', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isAvailable
                                        ? const Color(0xff00E676).withValues(alpha: 0.15)
                                        : const Color(0xffFF5252).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isAvailable
                                          ? const Color(0xff00E676).withValues(alpha: 0.4)
                                          : const Color(0xffFF5252).withValues(alpha: 0.4),
                                    ),
                                  ),
                                  child: Text(
                                    part.status.replaceAll('_', ' ').toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: isAvailable ? const Color(0xff00E676) : const Color(0xffFF5252),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            const Divider(color: Color(0xffCCCCCC), height: 1),
                            const SizedBox(height: 12),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => AddEditPartScreen(partToEdit: part),
                                      ),
                                    );
                                    if (result == true || mounted) {
                                      _loadParts();
                                    }
                                  },
                                  icon: const Icon(Icons.edit_outlined, size: 16),
                                  label: const Text('Edit'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    side: const BorderSide(color: Color(0xffCCCCCC)),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, color: Color(0xffFF5252), size: 20),
                                  onPressed: () => _handleDelete(part.id),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xff7C4DFF),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Part', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddEditPartScreen()),
          );
          if (result == true || mounted) {
            _loadParts();
          }
        },
      ),
    );
  }
}