import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/app_logo.dart';
import '../services/auth_provider.dart';
import '../../admin/screens/admin_dashboard_screen.dart';
import '../../customer/screens/customer_dashboard_screen.dart';
import '../../notifications/services/notification_provider.dart';
import '../../vendor/screens/vendor_dashboard_screen.dart';
import 'register_customer_screen.dart';
import 'register_vendor_screen.dart';

/// LoginScreen
/// Entry point for authenticating users featuring cyber glass styling and official PPF branding logo.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final notifProvider = Provider.of<NotificationProvider>(context, listen: false);

    try {
      final user = await authProvider.login(
        _emailController.text.trim(),
        _passwordController.text,
        notificationProvider: notifProvider,
      );

      if (!mounted) return;

      if (user.role == 'admin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const AdminDashboardScreen(),
          ),
        );
        return;
      } else if (user.role == 'vendor') {
        if (user.verificationStatus == 'pending') {
          _showStatusDialog(
            title: 'Pending Approval',
            message: 'Your account is pending admin approval.',
          );
          return;
        } else if (user.verificationStatus == 'rejected') {
          _showStatusDialog(
            title: 'Registration Rejected',
            message: 'Your registration was rejected. Contact support.',
          );
          return;
        } else if (user.verificationStatus == 'approved') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const VendorDashboardScreen(),
            ),
          );
          return;
        }
      } else if (user.role == 'customer') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const CustomerDashboardScreen(),
          ),
        );
        return;
      }
    } catch (e) {
      if (mounted) {
        final errorMessage = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showStatusDialog({required String title, required String message}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xff1A1D27),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(message, style: const TextStyle(color: Colors.grey)),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xff00E5FF)),
            child: const Text('OK', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = Provider.of<AuthProvider>(context).isLoading;

    return Scaffold(
      backgroundColor: const Color(0xff12141C),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 36.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Header Logo
                const AppLogo(
                  iconSize: 90,
                  fontSize: 24,
                ),
                const SizedBox(height: 32),

                // Card Container
                Container(
                  padding: const EdgeInsets.all(22.0),
                  decoration: BoxDecoration(
                    color: const Color(0xff1A1D27),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xff2A2E3D)),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Welcome Back',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Sign in to access parts & lead requests',
                        style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                      ),
                      const SizedBox(height: 24),

                      TextFormField(
                        controller: _emailController,
                        style: const TextStyle(color: Colors.white),
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Email Address',
                          prefixIcon: const Icon(Icons.email_rounded, color: Color(0xff00E5FF), size: 20),
                          labelStyle: const TextStyle(color: Colors.grey),
                          filled: true,
                          fillColor: const Color(0xff12141C),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xff2A2E3D)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xff00E5FF)),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your email';
                          }
                          final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
                          if (!emailRegex.hasMatch(value.trim())) {
                            return 'Please enter a valid email address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _passwordController,
                        style: const TextStyle(color: Colors.white),
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_rounded, color: Color(0xff00E5FF), size: 20),
                          labelStyle: const TextStyle(color: Colors.grey),
                          filled: true,
                          fillColor: const Color(0xff12141C),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xff2A2E3D)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xff00E5FF)),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 28),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff00E5FF),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.black,
                                  ),
                                )
                              : const Text('Sign In', style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RegisterCustomerScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.person_add_rounded, size: 18, color: Color(0xff00E5FF)),
                      label: const Text('Customer Signup', style: TextStyle(color: Color(0xff00E5FF), fontWeight: FontWeight.bold)),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RegisterVendorScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.storefront_rounded, size: 18, color: Color(0xff7C4DFF)),
                      label: const Text('Vendor Signup', style: TextStyle(color: Color(0xff7C4DFF), fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
