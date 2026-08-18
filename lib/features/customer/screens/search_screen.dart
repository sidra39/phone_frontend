import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/notification_bell_icon.dart';
import '../../auth/services/auth_provider.dart';
import '../../vendor/models/category_model.dart';
import '../models/search_result_model.dart';
import '../services/customer_service.dart';

import 'customer_dashboard_screen.dart';

/// SearchScreen
/// Allows customers to search for parts by brand, part type, model, and city,
/// featuring cyber-glassmorphism cards, fallback alert banners, and direct request submission.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final CustomerService _customerService = CustomerService();

  int? _selectedBrandId;
  int? _selectedPartTypeId;
  final _modelController = TextEditingController();
  final _cityController = TextEditingController();

  List<CategoryModel> _brands = [];
  List<CategoryModel> _partTypes = [];

  List<SearchResultModel> _searchResults = [];
  bool _isFallback = false;
  String _fallbackMessage = '';

  bool _isLoadingOptions = true;
  bool _isSearching = false;
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  Future<void> _loadOptions() async {
    try {
      final brands = await _customerService.getBrands();
      final partTypes = await _customerService.getPartTypes();

      setState(() {
        _brands = brands;
        _partTypes = partTypes;
        _isLoadingOptions = false;
      });

      if (!mounted) return;

      final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
      final userCity = user?.city;
      if (userCity != null && userCity.isNotEmpty) {
        _cityController.text = userCity;
        _performSearch();
      }
    } catch (e) {
      setState(() => _isLoadingOptions = false);
    }
  }

  @override
  void dispose() {
    _modelController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _performSearch() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) return;

    setState(() {
      _isSearching = true;
      _hasSearched = true;
    });

    try {
      final res = await _customerService.searchParts(
        token,
        brandId: _selectedBrandId,
        partTypeId: _selectedPartTypeId,
        model: _modelController.text,
        city: _cityController.text,
      );

      setState(() {
        _searchResults = res.results;
        _isFallback = res.fallback;
        _fallbackMessage = res.message;
        _isSearching = false;
      });
    } catch (e) {
      setState(() => _isSearching = false);
      if (mounted) {
        final msg = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _handleRequest(SearchResultModel part) async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) return;

    try {
      await _customerService.createRequest(token, part.id);
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: Theme.of(context).cardColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Request Sent to Vendor', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            content: Text(
              'Your request for "${part.modelName}" was sent to ${part.shopName}. Visit the shop to inspect and pay on the spot.',
              style: const TextStyle(color: Colors.grey),
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xff00E5FF)),
                child: const Text('Got It', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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
    }
  }

  InputDecoration _buildInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.grey, fontSize: 13),
      isDense: true,
      filled: true,
      fillColor: Theme.of(context).scaffoldBackgroundColor,
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xffCCCCCC)),
      ),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xff00E5FF)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor,
        elevation: 0,
        title: const Text('Search Phone Parts', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.explore_rounded, color: Color(0xff00E5FF)),
            tooltip: 'Browse Marketplace Page',
            onPressed: () {
              final dashboard = CustomerDashboardScreen.of(context);
              if (dashboard != null) {
                dashboard.setTab(0);
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CustomerDashboardScreen(initialIndex: 0)),
                );
              }
            },
          ),
          const NotificationBellIcon(),
        ],
      ),
      body: _isLoadingOptions
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Filter Panel
                Container(
                  color: Theme.of(context).cardColor,
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              initialValue: _selectedBrandId,
                              dropdownColor: Theme.of(context).cardColor,
                              style: const TextStyle(color: Color(0xff212121), fontSize: 13),
                              decoration: _buildInputDecoration('Brand'),
                              items: [
                                const DropdownMenuItem<int>(value: null, child: Text('All Brands')),
                                ..._brands.map((b) => DropdownMenuItem<int>(value: b.id, child: Text(b.name))),
                              ],
                              onChanged: (val) => setState(() => _selectedBrandId = val),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              initialValue: _selectedPartTypeId,
                              dropdownColor: Theme.of(context).cardColor,
                              style: const TextStyle(color: Color(0xff212121), fontSize: 13),
                              decoration: _buildInputDecoration('Part Type'),
                              items: [
                                const DropdownMenuItem<int>(value: null, child: Text('All Types')),
                                ..._partTypes.map((pt) => DropdownMenuItem<int>(value: pt.id, child: Text(pt.name))),
                              ],
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
                              style: const TextStyle(color: Color(0xff212121), fontSize: 13),
                              decoration: _buildInputDecoration('Model Name'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _cityController,
                              style: const TextStyle(color: Color(0xff212121), fontSize: 13),
                              decoration: _buildInputDecoration('City'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton.icon(
                          onPressed: _isSearching ? null : _performSearch,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff00E5FF),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.search_rounded, color: Colors.black),
                          label: _isSearching
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                                )
                              : const Text('Search Component Inventory', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),

                // Fallback Out-of-City Alert Banner
                if (_isFallback)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xffFF9100).withValues(alpha: 0.15),
                      border: const Border(
                        bottom: BorderSide(color: Color(0xffFF9100), width: 1),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded, color: Color(0xffFF9100), size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _fallbackMessage,
                            style: const TextStyle(color: Color(0xffFF9100), fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Search Results List
                Expanded(
                  child: _isSearching
                      ? const Center(child: CircularProgressIndicator())
                      : !_hasSearched
                          ? const Center(child: Text('Filter by model or city above to search', style: TextStyle(color: Colors.grey)))
                          : _searchResults.isEmpty
                              ? const Center(child: Text('No matching parts found', style: TextStyle(color: Colors.grey)))
                              : ListView.builder(
                                  padding: const EdgeInsets.all(16.0),
                                  itemCount: _searchResults.length,
                                  itemBuilder: (context, index) {
                                    final part = _searchResults[index];
                                    final theme = Theme.of(context);
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 16.0),
                                      padding: const EdgeInsets.all(18.0),
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
                                              Expanded(
                                                child: Text(
                                                  part.modelName,
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: theme.textTheme.bodyLarge?.color,
                                                  ),
                                                ),
                                              ),
                                              Text(
                                                '\$${part.price.toStringAsFixed(2)}',
                                                style: TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                  color: theme.primaryColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            '${part.brandName ?? 'Brand'} • ${part.partTypeName ?? 'Type'} • ${part.conditionType.toUpperCase()}',
                                            style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 13),
                                          ),
                                          const SizedBox(height: 12),
                                          Row(
                                            children: [
                                              const Icon(Icons.storefront_rounded, size: 16, color: Colors.grey),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  '${part.shopName} (${part.vendorCity})',
                                                  style: TextStyle(fontWeight: FontWeight.w600, color: theme.textTheme.bodyLarge?.color),
                                                ),
                                              ),
                                              const Icon(Icons.star_rounded, size: 18, color: Colors.amber),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${part.averageRating} ★ (${part.reviewCount})',
                                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.amber),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 14),
                                          const Divider(color: Color(0xffE2E8F0), height: 1),
                                          const SizedBox(height: 12),
                                          Align(
                                            alignment: Alignment.centerRight,
                                            child: ElevatedButton.icon(
                                              onPressed: () => _handleRequest(part),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: theme.primaryColor,
                                                foregroundColor: Colors.white,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                              ),
                                              icon: const Icon(Icons.send_rounded, size: 16),
                                              label: const Text('Request This Part', style: TextStyle(fontWeight: FontWeight.bold)),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                ),
              ],
            ),
    );
  }
}
