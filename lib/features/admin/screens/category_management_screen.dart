import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/services/auth_provider.dart';
import '../../vendor/models/category_model.dart';
import '../services/admin_service.dart';

/// CategoryManagementScreen
/// Admin interface for managing Brand and Part Type lookup records with cyber-sleek styling.
class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  State<CategoryManagementScreen> createState() => _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AdminService _adminService = AdminService();

  List<CategoryModel> _brands = [];
  List<CategoryModel> _partTypes = [];

  bool _isLoadingBrands = true;
  bool _isLoadingPartTypes = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _loadBrands();
    _loadPartTypes();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBrands() async {
    setState(() => _isLoadingBrands = true);
    try {
      final list = await _adminService.getBrands();
      setState(() {
        _brands = list;
        _isLoadingBrands = false;
      });
    } catch (e) {
      setState(() => _isLoadingBrands = false);
    }
  }

  Future<void> _loadPartTypes() async {
    setState(() => _isLoadingPartTypes = true);
    try {
      final list = await _adminService.getPartTypes();
      setState(() {
        _partTypes = list;
        _isLoadingPartTypes = false;
      });
    } catch (e) {
      setState(() => _isLoadingPartTypes = false);
    }
  }

  void _showAddEditDialog({required bool isBrand, CategoryModel? itemToEdit}) {
    final title = isBrand
        ? (itemToEdit == null ? 'Add New Brand' : 'Edit Brand')
        : (itemToEdit == null ? 'Add New Part Type' : 'Edit Part Type');

    final nameController = TextEditingController(text: itemToEdit?.name ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: const TextStyle(color: Color(0xff212121), fontWeight: FontWeight.bold)),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: nameController,
            style: const TextStyle(color: Color(0xff212121)),
            decoration: InputDecoration(
              labelText: 'Category Name',
              labelStyle: const TextStyle(color: Colors.grey),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xffCCCCCC)),
              ),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xffFFC400)),
              ),
            ),
            validator: (val) => val == null || val.trim().isEmpty ? 'Please enter a name' : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(dialogCtx);

              final token = Provider.of<AuthProvider>(context, listen: false).token;
              if (token == null) return;

              final name = nameController.text.trim();

              try {
                if (isBrand) {
                  if (itemToEdit == null) {
                    await _adminService.addBrand(token, name);
                  } else {
                    await _adminService.updateBrand(token, itemToEdit.id, name);
                  }
                  _loadBrands();
                } else {
                  if (itemToEdit == null) {
                    await _adminService.addPartType(token, name);
                  } else {
                    await _adminService.updatePartType(token, itemToEdit.id, name);
                  }
                  _loadPartTypes();
                }

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$title succeeded')),
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
            child: const Text('Save Record', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleDelete({required bool isBrand, required CategoryModel item}) async {
    final typeName = isBrand ? 'Brand' : 'Part Type';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete $typeName', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
        content: Text('Are you sure you want to delete "${item.name}"?', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xffDC2626)),
            child: const Text('Delete Record', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;

    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) return;

    try {
      if (isBrand) {
        await _adminService.deleteBrand(token, item.id);
        _loadBrands();
      } else {
        await _adminService.deletePartType(token, item.id);
        _loadPartTypes();
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$typeName "${item.name}" deleted')),
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

  Widget _buildCategoryList({required bool isBrand, required List<CategoryModel> items, required bool isLoading}) {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (items.isEmpty) return const Center(child: Text('No categories found', style: TextStyle(color: Colors.grey)));

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12.0),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xffCCCCCC)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xffFFC400).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isBrand ? Icons.phone_android_rounded : Icons.extension_rounded,
                color: const Color(0xffFFC400),
                size: 20,
              ),
            ),
            title: Text(
              item.name,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xff212121), fontSize: 16),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: Colors.grey),
                  onPressed: () => _showAddEditDialog(isBrand: isBrand, itemToEdit: item),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Color(0xffFF5252)),
                  onPressed: () => _handleDelete(isBrand: isBrand, item: item),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          // Cyber Tab Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border(bottom: BorderSide(color: const Color(0xffCCCCCC))),
            ),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xffCCCCCC)),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: const Color(0xffFFC400).withValues(alpha: 0.2),
                  border: Border.all(color: const Color(0xffFFC400)),
                ),
                labelColor: const Color(0xffFFC400),
                unselectedLabelColor: Colors.grey,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                tabs: const [
                  Tab(text: 'Phone Brands'),
                  Tab(text: 'Part Categories'),
                ],
              ),
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCategoryList(isBrand: true, items: _brands, isLoading: _isLoadingBrands),
                _buildCategoryList(isBrand: false, items: _partTypes, isLoading: _isLoadingPartTypes),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xffFFC400),
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          _tabController.index == 0 ? 'Add Brand' : 'Add Category',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        onPressed: () {
          final isBrandTab = _tabController.index == 0;
          _showAddEditDialog(isBrand: isBrandTab);
        },
      ),
    );
  }
}
