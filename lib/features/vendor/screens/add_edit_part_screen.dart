import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/services/auth_provider.dart';
import '../models/category_model.dart';
import '../models/part_model.dart';
import '../services/vendor_service.dart';
import 'part_qr_screen.dart';

/// AddEditPartScreen
/// Form screen to create a new part listing or edit an existing part with cyber-sleek styling.
class AddEditPartScreen extends StatefulWidget {
  final PartModel? partToEdit;

  const AddEditPartScreen({super.key, this.partToEdit});

  @override
  State<AddEditPartScreen> createState() => _AddEditPartScreenState();
}

class _AddEditPartScreenState extends State<AddEditPartScreen> {
  final _formKey = GlobalKey<FormState>();
  final VendorService _vendorService = VendorService();

  int? _selectedBrandId;
  int? _selectedPartTypeId;
  String _selectedCondition = 'new';

  final _modelNameController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockQuantityController = TextEditingController(text: '1');
  final _imageUrlController = TextEditingController();

  List<CategoryModel> _brands = [];
  List<CategoryModel> _partTypes = [];

  bool _isLoadingCategories = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadCategoriesAndInit();
  }

  Future<void> _loadCategoriesAndInit() async {
    try {
      final brands = await _vendorService.getBrands();
      final partTypes = await _vendorService.getPartTypes();

      setState(() {
        _brands = brands;
        _partTypes = partTypes;
        _isLoadingCategories = false;

        if (widget.partToEdit != null) {
          final p = widget.partToEdit!;
          _selectedBrandId = p.brandId;
          _selectedPartTypeId = p.partTypeId;
          _selectedCondition = p.conditionType;
          _modelNameController.text = p.modelName;
          _priceController.text = p.price.toString();
          _stockQuantityController.text = p.stockQuantity.toString();
          _imageUrlController.text = p.imageUrl ?? '';
        } else {
          if (_brands.isNotEmpty) _selectedBrandId = _brands.first.id;
          if (_partTypes.isNotEmpty) _selectedPartTypeId = _partTypes.first.id;
        }
      });
    } catch (e) {
      setState(() {
        _isLoadingCategories = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading options: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  void dispose() {
    _modelNameController.dispose();
    _priceController.dispose();
    _stockQuantityController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBrandId == null || _selectedPartTypeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select Brand and Part Type')),
      );
      return;
    }

    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) return;

    setState(() {
      _isSubmitting = true;
    });

    final fields = {
      'brand_id': _selectedBrandId,
      'part_type_id': _selectedPartTypeId,
      'model_name': _modelNameController.text.trim(),
      'price': double.parse(_priceController.text.trim()),
      'condition_type': _selectedCondition,
      'stock_quantity': int.parse(_stockQuantityController.text.trim()),
      'image_url': _imageUrlController.text.trim().isEmpty ? null : _imageUrlController.text.trim(),
    };

    try {
      if (widget.partToEdit != null) {
        await _vendorService.updatePart(token, widget.partToEdit!.id, fields);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Part updated successfully')),
          );
          Navigator.pop(context, true);
        }
      } else {
        final newPart = await _vendorService.addPart(token, fields);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Part added successfully')),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => PartQrScreen(part: newPart),
            ),
          );
        }
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
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  InputDecoration _buildInputDecoration(String label, {String? hint, IconData? icon}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon != null ? Icon(icon, color: const Color(0xff7C4DFF), size: 20) : null,
      labelStyle: const TextStyle(color: Colors.grey),
      hintStyle: TextStyle(color: Colors.grey.shade600),
      filled: true,
      fillColor: const Color(0xff1A1D27),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xff2A2E3D)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xff7C4DFF)),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isEditing = widget.partToEdit != null;

    return Scaffold(
      backgroundColor: const Color(0xff12141C),
      appBar: AppBar(
        backgroundColor: const Color(0xff1A1D27),
        elevation: 0,
        title: Text(isEditing ? 'Edit Inventory Listing' : 'Add New Part Listing', style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _isLoadingCategories
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Brand & Type Row
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            initialValue: _selectedBrandId,
                            dropdownColor: const Color(0xff1A1D27),
                            style: const TextStyle(color: Colors.white),
                            decoration: _buildInputDecoration('Brand', icon: Icons.phone_android_rounded),
                            items: _brands.map((b) {
                              return DropdownMenuItem<int>(
                                value: b.id,
                                child: Text(b.name),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedBrandId = val);
                            },
                            validator: (val) => val == null ? 'Select brand' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            initialValue: _selectedPartTypeId,
                            dropdownColor: const Color(0xff1A1D27),
                            style: const TextStyle(color: Colors.white),
                            decoration: _buildInputDecoration('Part Type', icon: Icons.extension_rounded),
                            items: _partTypes.map((pt) {
                              return DropdownMenuItem<int>(
                                value: pt.id,
                                child: Text(pt.name),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedPartTypeId = val);
                            },
                            validator: (val) => val == null ? 'Select type' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Model Name Input
                    TextFormField(
                      controller: _modelNameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: _buildInputDecoration('Model Name', hint: 'e.g. Galaxy S21 Ultra / iPhone 13 Pro', icon: Icons.build_circle_rounded),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Please enter model name' : null,
                    ),
                    const SizedBox(height: 16),

                    // Price & Stock Row
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _priceController,
                            style: const TextStyle(color: Colors.white),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: _buildInputDecoration('Price (\$)', hint: '99.99', icon: Icons.attach_money_rounded),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) return 'Enter price';
                              if (double.tryParse(val.trim()) == null) return 'Invalid price';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _stockQuantityController,
                            style: const TextStyle(color: Colors.white),
                            keyboardType: TextInputType.number,
                            decoration: _buildInputDecoration('Stock Qty', icon: Icons.inventory_rounded),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) return 'Enter quantity';
                              if (int.tryParse(val.trim()) == null) return 'Invalid qty';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Condition Segment Dropdown
                    DropdownButtonFormField<String>(
                      initialValue: _selectedCondition,
                      dropdownColor: const Color(0xff1A1D27),
                      style: const TextStyle(color: Colors.white),
                      decoration: _buildInputDecoration('Condition', icon: Icons.new_releases_rounded),
                      items: const [
                        DropdownMenuItem(value: 'new', child: Text('Brand New (Original)')),
                        DropdownMenuItem(value: 'used', child: Text('Used (Refurbished / Tested)')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedCondition = val);
                      },
                    ),
                    const SizedBox(height: 16),

                    // Image URL Input
                    TextFormField(
                      controller: _imageUrlController,
                      style: const TextStyle(color: Colors.white),
                      decoration: _buildInputDecoration('Image URL (Optional)', hint: 'https://example.com/part.jpg', icon: Icons.image_rounded),
                    ),
                    const SizedBox(height: 28),

                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _handleSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff7C4DFF),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Text(
                                isEditing ? 'Save Changes' : 'Save & Generate QR Code',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
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
