import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/notification_bell_icon.dart';
import '../../auth/screens/login_screen.dart';
import '../../auth/services/auth_provider.dart';
import '../../notifications/services/notification_provider.dart';
import '../../reports/screens/my_reports_screen.dart';
import '../services/customer_service.dart';

/// CustomerProfileScreen
/// Displays customer profile summary, city update dialog, reports link, and sign-out action with cyber styling.
class CustomerProfileScreen extends StatefulWidget {
  const CustomerProfileScreen({super.key});

  @override
  State<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen> {
  final CustomerService _customerService = CustomerService();
  Map<String, dynamic>? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) return;

    setState(() => _isLoading = true);

    try {
      final profile = await _customerService.getMyProfile(token);
      setState(() {
        _profile = profile;
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

  void _showEditCityDialog() {
    if (_profile == null) return;

    final cityController = TextEditingController(text: _profile!['city']);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: const Color(0xff1A1D27),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Update Primary City', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: cityController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'City Name',
              labelStyle: const TextStyle(color: Colors.grey),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xff2A2E3D))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xff00E5FF))),
            ),
            validator: (val) => val == null || val.trim().isEmpty ? 'Please enter city' : null,
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

              try {
                await _customerService.updateMyProfile(token, cityController.text.trim());
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('City updated successfully')),
                  );
                  _loadProfile();
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
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xff00E5FF)),
            child: const Text('Save Location', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xff00E5FF), size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff12141C),
      appBar: AppBar(
        backgroundColor: const Color(0xff1A1D27),
        elevation: 0,
        title: const Text('My Customer Account', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: const [
          NotificationBellIcon(),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _profile == null
              ? const Center(child: Text('Profile not found', style: TextStyle(color: Colors.grey)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Customer Header Card
                      Container(
                        padding: const EdgeInsets.all(20.0),
                        decoration: BoxDecoration(
                          color: const Color(0xff1A1D27),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xff2A2E3D)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xff00E5FF).withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.person_rounded, color: Color(0xff00E5FF), size: 28),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _profile!['name'] ?? 'Customer',
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text('Phone Parts Finder Buyer', style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            const Divider(color: Color(0xff2A2E3D), height: 1),
                            const SizedBox(height: 16),

                            _buildInfoTile(Icons.email_rounded, 'Email Address', _profile!['email'] ?? 'N/A'),
                            _buildInfoTile(Icons.phone_rounded, 'Phone Number', _profile!['phone'] ?? 'N/A'),
                            _buildInfoTile(Icons.location_city_rounded, 'City Location', _profile!['city'] ?? 'N/A'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: _showEditCityDialog,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff00E5FF),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.edit_rounded, color: Colors.black),
                          label: const Text('Edit Location City', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 12),

                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const MyReportsScreen()),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xffFF5252),
                            side: const BorderSide(color: Color(0xffFF5252)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.report_problem_rounded, color: Color(0xffFF5252)),
                          label: const Text('My Reports & Complaints', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Sign Out Button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: TextButton.icon(
                          onPressed: () async {
                            final authProvider = Provider.of<AuthProvider>(context, listen: false);
                            final notifProvider = Provider.of<NotificationProvider>(context, listen: false);
                            await authProvider.logout(notificationProvider: notifProvider);
                            if (context.mounted) {
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(builder: (_) => const LoginScreen()),
                                (route) => false,
                              );
                            }
                          },
                          icon: const Icon(Icons.logout_rounded, color: Colors.grey),
                          label: const Text('Sign Out of Account', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
