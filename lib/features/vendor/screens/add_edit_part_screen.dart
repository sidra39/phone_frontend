import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/api_constants.dart';
import '../../auth/services/auth_provider.dart';
import '../models/category_model.dart';
import '../models/part_model.dart';
import '../services/vendor_service.dart';

/// AddEditPartScreen
/// Form screen to create a new part listing or edit an existing part with barcode & photo uploads.
class AddEditPartScreen extends StatefulWidget {
  final PartModel? partToEdit;

  const AddEditPartScreen({super.key, this.partToEdit});

  @override
  State<AddEditPartScreen> createState() => _AddEditPartScreenState();
}

class _AddEditPartScreenState extends State<AddEditPartScreen> {
  final _formKey = GlobalKey<FormState>();
  final VendorService _vendorService = VendorService();
  final ImagePicker _picker = ImagePicker();

  int? _selectedBrandId;
  int? _selectedPartTypeId;
  String _selectedCondition = 'new';
  String _selectedCodeType = 'qr';

  final _modelNameController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockQuantityController = TextEditingController(text: '1');
  final _barcodeNumberController = TextEditingController();

  List<CategoryModel> _brands = [];
  List<CategoryModel> _partTypes = [];

  bool _isLoadingCategories = true;
  bool _isSubmitting = false;

  // Selected photo payloads
  XFile? _originalPhoto;
  Uint8List? _originalPhotoBytes;
  XFile? _barcodePhoto;
  Uint8List? _barcodePhotoBytes;

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
          _barcodeNumberController.text = p.barcodeNumber ?? '';
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
    _barcodeNumberController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool isOriginalPhoto) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (file == null) return;

      final bytes = await file.readAsBytes();

      setState(() {
        if (isOriginalPhoto) {
          _originalPhoto = file;
          _originalPhotoBytes = bytes;
        } else {
          _barcodePhoto = file;
          _barcodePhotoBytes = bytes;
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error selecting image: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBrandId == null || _selectedPartTypeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select Brand and Part Type')),
      );
      return;
    }

    final bool isEditing = widget.partToEdit != null;

    // Photos are required when adding a new part
    if (!isEditing && (_originalPhotoBytes == null || _barcodePhotoBytes == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Both Original Photo and Barcode Photo are required for verification.')),
      );
      return;
    }

    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) return;

    setState(() {
      _isSubmitting = true;
    });

    // Prepare fields
    final Map<String, String> fields = {
      'brand_id': _selectedBrandId.toString(),
      'part_type_id': _selectedPartTypeId.toString(),
      'model_name': _modelNameController.text.trim(),
      'price': _priceController.text.trim(),
      'condition_type': _selectedCondition,
      'stock_quantity': _stockQuantityController.text.trim(),
      'barcode_number': _barcodeNumberController.text.trim(),
      'code_type': _selectedCodeType,
    };

    // Prepare files
    final Map<String, Map<String, dynamic>> files = {};
    if (_originalPhotoBytes != null && _originalPhoto != null) {
      files['originalPhoto'] = {
        'bytes': _originalPhotoBytes!,
        'filename': _originalPhoto!.name,
      };
    }
    if (_barcodePhotoBytes != null && _barcodePhoto != null) {
      files['barcodePhoto'] = {
        'bytes': _barcodePhotoBytes!,
        'filename': _barcodePhoto!.name,
      };
    }

    try {
      if (isEditing) {
        await _vendorService.updatePart(token, widget.partToEdit!.id, fields, files);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Part updated successfully')),
          );
          Navigator.pop(context, true);
        }
      } else {
        await _vendorService.addPart(token, fields, files);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Part added successfully')),
          );
          Navigator.pop(context, true);
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
    final theme = Theme.of(context);
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon != null ? Icon(icon, color: theme.primaryColor, size: 20) : null,
      labelStyle: TextStyle(color: theme.textTheme.bodyMedium?.color),
      hintStyle: TextStyle(color: theme.textTheme.bodyMedium?.color),
      filled: true,
      fillColor: theme.cardColor,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xffE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xffDC2626)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xffDC2626), width: 2),
      ),
    );
  }

  Widget _buildPhotoPickerSection({
    required String title,
    required String subtitle,
    required bool isOriginalPhoto,
    required Uint8List? selectedBytes,
    required String? existingUrl,
  }) {
    final theme = Theme.of(context);
    final String? fullExistingUrl = existingUrl != null ? '${ApiConstants.baseUrl}$existingUrl' : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xffE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              // Preview Thumbnail
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xffE2E8F0)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: selectedBytes != null
                      ? Image.memory(selectedBytes, fit: BoxFit.cover)
                      : (fullExistingUrl != null
                          ? Image.network(
                              fullExistingUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (ctx, err, stack) => const Icon(Icons.broken_image, color: Colors.grey),
                            )
                          : const Icon(Icons.image_search_rounded, color: Colors.grey, size: 30)),
                ),
              ),
              const SizedBox(width: 16),
              // Selection Action Button
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _pickImage(isOriginalPhoto),
                  icon: const Icon(Icons.photo_library_rounded, size: 16),
                  label: const Text('Pick Image'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor.withValues(alpha: 0.1),
                    foregroundColor: theme.primaryColor,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isEditing = widget.partToEdit != null;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor,
        elevation: 1,
        title: Text(isEditing ? 'Edit Inventory Listing' : 'Add Authenticated Part', style: const TextStyle(fontWeight: FontWeight.bold)),
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
                            dropdownColor: Theme.of(context).cardColor,
                            style: const TextStyle(color: Color(0xff212121)),
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
                            dropdownColor: Theme.of(context).cardColor,
                            style: const TextStyle(color: Color(0xff212121)),
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
                      style: const TextStyle(color: Color(0xff212121)),
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
                            style: const TextStyle(color: Color(0xff212121)),
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
                            style: const TextStyle(color: Color(0xff212121)),
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
                      dropdownColor: Theme.of(context).cardColor,
                      style: const TextStyle(color: Color(0xff212121)),
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

                    // Identification Type Dropdown (Barcode vs QR Code)
                    DropdownButtonFormField<String>(
                      initialValue: _selectedCodeType,
                      dropdownColor: Theme.of(context).cardColor,
                      style: const TextStyle(color: Color(0xff212121)),
                      decoration: _buildInputDecoration('Identification Type', icon: Icons.qr_code_scanner_rounded),
                      items: const [
                        DropdownMenuItem(value: 'qr', child: Text('QR Code (Auto-generated if no number entered)')),
                        DropdownMenuItem(value: 'barcode', child: Text('Barcode (Number required)')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedCodeType = val);
                      },
                    ),
                    const SizedBox(height: 16),

                    // Barcode / QR text field
                    TextFormField(
                      controller: _barcodeNumberController,
                      style: const TextStyle(color: Color(0xff212121)),
                      decoration: _buildInputDecoration(
                        _selectedCodeType == 'barcode' ? 'Barcode Number *' : 'QR Serial / Code Number (Optional)',
                        hint: _selectedCodeType == 'barcode'
                            ? 'Enter printed barcode serial number'
                            : 'Optional: System auto-generates unique QR token if left empty',
                        icon: Icons.qr_code_2_rounded,
                      ),
                      validator: (val) {
                        if (_selectedCodeType == 'barcode' && (val == null || val.trim().isEmpty)) {
                          return 'Barcode Number is required for barcode products';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Image Upload Section 1
                    _buildPhotoPickerSection(
                      title: 'Original Product Photo',
                      subtitle: 'Upload a clear picture showing the physical product state.',
                      isOriginalPhoto: true,
                      selectedBytes: _originalPhotoBytes,
                      existingUrl: widget.partToEdit?.originalPhotoUrl,
                    ),
                    const SizedBox(height: 16),

                    // Image Upload Section 2
                    _buildPhotoPickerSection(
                      title: 'Barcode / Packaging Photo',
                      subtitle: 'Upload a clear picture of the manufacturer barcode sticker.',
                      isOriginalPhoto: false,
                      selectedBytes: _barcodePhotoBytes,
                      existingUrl: widget.partToEdit?.barcodePhotoUrl,
                    ),
                    const SizedBox(height: 28),

                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _handleSubmit,
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Text(
                                isEditing ? 'Save Listing' : 'Publish Listing',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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