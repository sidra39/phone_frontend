import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/widgets/app_logo.dart';
import '../../../core/widgets/notification_bell_icon.dart';
import '../../admin/screens/admin_dashboard_screen.dart';
import '../../auth/screens/login_screen.dart';
import '../../auth/services/auth_provider.dart';
import '../../customer/screens/customer_dashboard_screen.dart';
import '../../vendor/models/category_model.dart';
import '../../vendor/screens/vendor_dashboard_screen.dart';
import '../models/browse_part_model.dart';
import '../services/browse_service.dart';
import 'part_detail_screen.dart';

/// BrowseHomeScreen
/// OLX-style public marketplace homepage. Displays all available phone parts for public browsing with search filters.
class BrowseHomeScreen extends StatefulWidget {
  const BrowseHomeScreen({super.key});

  @override
  State<BrowseHomeScreen> createState() => _BrowseHomeScreenState();
}

class _BrowseHomeScreenState extends State<BrowseHomeScreen> {
  final BrowseService _browseService = BrowseService();

  List<BrowsePartModel> _parts = [];
  List<CategoryModel> _brands = [];
  List<CategoryModel> _partTypes = [];

  bool _isLoadingParts = true;
  bool _showFilters = false;

  int? _selectedBrandId;
  int? _selectedPartTypeId;
  final _modelController = TextEditingController();
  final _cityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _modelController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    _loadCategories();
    _performSearch();
  }

  Future<void> _loadCategories() async {
    try {
      final brands = await _browseService.getBrands();
      final partTypes = await _browseService.getPartTypes();
      if (mounted) {
        setState(() {
          _brands = brands;
          _partTypes = partTypes;
        });
      }
    } catch (_) {}
  }

  Future<void> _performSearch() async {
    setState(() => _isLoadingParts = true);
    try {
      final results = await _browseService.searchParts(
        brandId: _selectedBrandId,
        partTypeId: _selectedPartTypeId,
        model: _modelController.text.trim().isEmpty ? null : _modelController.text.trim(),
        city: _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
      );
      if (mounted) {
        setState(() {
          _parts = results;
          _isLoadingParts = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingParts = false);
      }
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedBrandId = null;
      _selectedPartTypeId = null;
      _modelController.clear();
      _cityController.clear();
    });
    _performSearch();
  }

  void _navigateToDashboard(String role) {
    Widget screen;
    if (role == 'admin') {
      screen = const AdminDashboardScreen();
    } else if (role == 'vendor') {
      screen = const VendorDashboardScreen();
    } else {
      screen = const CustomerDashboardScreen();
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final bool isLoggedIn = authProvider.token != null && authProvider.currentUser != null;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.cardColor,
        elevation: 1,
        titleSpacing: 16,
        title: const AppLogo(iconSize: 32, fontSize: 18),
        actions: [
          IconButton(
            icon: Icon(_showFilters ? Icons.filter_alt_off_rounded : Icons.tune_rounded),
            tooltip: 'Filter Parts',
            onPressed: () => setState(() => _showFilters = !_showFilters),
          ),
          if (isLoggedIn) ...[
            const NotificationBellIcon(),
            IconButton(
              icon: Icon(Icons.dashboard_rounded, color: theme.primaryColor),
              tooltip: 'Go to Dashboard',
              onPressed: () => _navigateToDashboard(authProvider.currentUser!.role.toLowerCase()),
            ),
          ] else ...[
            TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
              icon: const Icon(Icons.login_rounded, size: 18),
              label: const Text('Login', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _performSearch,
        child: Column(
          children: [
            // Expandable Filter Bar
            if (_showFilters)
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  border: const Border(bottom: BorderSide(color: Color(0xffE2E8F0))),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            initialValue: _selectedBrandId,
                            decoration: const InputDecoration(labelText: 'Brand', isDense: true),
                            items: _brands.map((b) => DropdownMenuItem(value: b.id, child: Text(b.name))).toList(),
                            onChanged: (val) => setState(() => _selectedBrandId = val),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            initialValue: _selectedPartTypeId,
                            decoration: const InputDecoration(labelText: 'Part Type', isDense: true),
                            items: _partTypes.map((pt) => DropdownMenuItem(value: pt.id, child: Text(pt.name))).toList(),
                            onChanged: (val) => setState(() => _selectedPartTypeId = val),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _modelController,
                            decoration: const InputDecoration(labelText: 'Model Name', hintText: 'e.g. S21 / iPhone 13', isDense: true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _cityController,
                            decoration: const InputDecoration(labelText: 'City', hintText: 'e.g. Lahore', isDense: true),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(onPressed: _clearFilters, child: const Text('Clear')),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: _performSearch,
                          icon: const Icon(Icons.search_rounded, size: 16),
                          label: const Text('Search'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            // Parts Catalog Grid (OLX-Style 2 Columns)
            Expanded(
              child: _isLoadingParts
                  ? const Center(child: CircularProgressIndicator())
                  : _parts.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.search_off_rounded, size: 54, color: Colors.grey),
                              const SizedBox(height: 12),
                              const Text('No parts matching your browse criteria', style: TextStyle(fontSize: 16, color: Colors.grey)),
                              const SizedBox(height: 12),
                              ElevatedButton(onPressed: _clearFilters, child: const Text('Show All Parts')),
                            ],
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(14.0),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.72,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: _parts.length,
                          itemBuilder: (ctx, index) {
                            final part = _parts[index];
                            final String? fullImageUrl = part.imageUrl != null && part.imageUrl!.isNotEmpty
                                ? '${ApiConstants.baseUrl}${part.imageUrl}'
                                : null;

                            return InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => PartDetailScreen(partId: part.id),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: theme.cardColor,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xffE2E8F0)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Product Image Thumbnail
                                    Expanded(
                                      child: Container(
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          color: theme.scaffoldBackgroundColor,
                                          borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                                          child: fullImageUrl != null
                                              ? Image.network(
                                                  fullImageUrl,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (c, e, s) => const Icon(Icons.image_not_supported_rounded, color: Colors.grey, size: 36),
                                                )
                                              : const Icon(Icons.image_search_rounded, color: Colors.grey, size: 36),
                                        ),
                                      ),
                                    ),

                                    // Part Details Info Panel
                                    Padding(
                                      padding: const EdgeInsets.all(10.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            part.modelName,
                                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: theme.textTheme.bodyLarge?.color),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${part.brandName ?? ''} • ${part.partTypeName ?? ''}',
                                            style: TextStyle(fontSize: 11, color: theme.textTheme.bodyMedium?.color),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                '\$${part.price.toStringAsFixed(2)}',
                                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: theme.primaryColor),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: theme.primaryColor.withValues(alpha: 0.12),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  part.conditionType.toUpperCase(),
                                                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: theme.primaryColor),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              const Icon(Icons.location_on_rounded, size: 12, color: Colors.grey),
                                              const SizedBox(width: 2),
                                              Expanded(
                                                child: Text(
                                                  part.vendorCity.isEmpty ? 'Marketplace' : part.vendorCity,
                                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              if (part.averageRating > 0) ...[
                                                const Icon(Icons.star_rounded, size: 12, color: Colors.amber),
                                                Text(
                                                  part.averageRating.toStringAsFixed(1),
                                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
