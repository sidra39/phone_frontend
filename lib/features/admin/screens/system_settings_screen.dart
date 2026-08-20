import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/services/auth_provider.dart';
import '../services/admin_service.dart';

/// SystemSettingsScreen
/// Admin control panel for freely adjusting platform Security Deposit amount, deposit payment phone number,
/// and platform lead commission percentages.
class SystemSettingsScreen extends StatefulWidget {
  const SystemSettingsScreen({super.key});

  @override
  State<SystemSettingsScreen> createState() => _SystemSettingsScreenState();
}

class _SystemSettingsScreenState extends State<SystemSettingsScreen> {
  final AdminService _adminService = AdminService();
  final _formKey = GlobalKey<FormState>();

  final _depositAmountController = TextEditingController();
  final _depositPhoneController = TextEditingController();
  final _commissionRateController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _depositAmountController.dispose();
    _depositPhoneController.dispose();
    _commissionRateController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) return;

    setState(() => _isLoading = true);
    try {
      final settings = await _adminService.getSystemSettings(token);
      setState(() {
        _depositAmountController.text = (settings['security_deposit_amount'] ?? '500').toString();
        _depositPhoneController.text = (settings['security_deposit_phone'] ?? '+92 311 7595866').toString();
        _commissionRateController.text = (settings['commission_rate_percent'] ?? '10').toString();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        final msg = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load settings: $msg'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _handleSaveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) return;

    setState(() => _isSaving = true);
    try {
      await _adminService.updateSystemSettings(token, {
        'security_deposit_amount': _depositAmountController.text.trim(),
        'security_deposit_phone': _depositPhoneController.text.trim(),
        'commission_rate_percent': _commissionRateController.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ System Settings updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save settings: $msg'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.cardColor,
        elevation: 0,
        title: const Text('System Controls & Settings', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadSettings,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Banner
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.tune_rounded, color: Colors.amber, size: 28),
                          SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Free-Will Platform Controls',
                                  style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Adjust vendor security deposit rates, payment phone numbers, and lead commission percentages in real-time.',
                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Section 1: Security Deposit Settings
                    const Text('1. Vendor Security Deposit Control', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _depositAmountController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Security Deposit Amount (Rs.)',
                                hintText: '500',
                                prefixText: 'Rs. ',
                                prefixIcon: Icon(Icons.payments_rounded, color: Colors.amber),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) return 'Enter deposit amount';
                                if (double.tryParse(val.trim()) == null) return 'Enter a valid number';
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _depositPhoneController,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
                                labelText: 'JazzCash & EasyPaisa Phone Number',
                                hintText: '+92 311 7595866',
                                prefixIcon: Icon(Icons.phone_android_rounded, color: Color(0xff00E5FF)),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) return 'Enter payment phone number';
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Section 2: Commission Settings
                    const Text('2. Platform Lead Commission Control', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _commissionRateController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Commission Rate (%)',
                                hintText: '10',
                                suffixText: '%',
                                prefixIcon: Icon(Icons.percent_rounded, color: Color(0xff00E676)),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) return 'Enter commission percentage';
                                final num = double.tryParse(val.trim());
                                if (num == null || num < 0 || num > 100) return 'Enter a valid percentage (0-100)';
                                return null;
                              },
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'This percentage is automatically calculated on lead requests beyond the 2 free initial leads.',
                              style: TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _handleSaveSettings,
                        icon: _isSaving
                            ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.save_rounded),
                        label: Text(_isSaving ? 'Saving Changes...' : 'Save & Update System Controls', style: const TextStyle(fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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