import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/app_logo.dart';
import '../services/auth_provider.dart';
import '../../admin/screens/admin_dashboard_screen.dart';
import '../../customer/screens/customer_dashboard_screen.dart';
import '../../notifications/services/notification_provider.dart';
import '../../vendor/screens/vendor_dashboard_screen.dart';
import '../../browse/screens/part_detail_screen.dart';
import 'register_customer_screen.dart';
import 'register_vendor_screen.dart';

/// LoginScreen
/// Entry point for authenticating users featuring official PPF branding logo.
class LoginScreen extends StatefulWidget {
  final int? returnToPartId;

  const LoginScreen({super.key, this.returnToPartId});

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
        if (widget.returnToPartId != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => PartDetailScreen(partId: widget.returnToPartId!),
            ),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const CustomerDashboardScreen(),
            ),
          );
        }
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
        backgroundColor: Theme.of(ctx).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = Provider.of<AuthProvider>(context).isLoading;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 36.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Header Logo (Uses custom vector text logic styled to light background compatibility)
                const AppLogo(
                  iconSize: 90,
                  fontSize: 24,
                ),
                const SizedBox(height: 32),

                // Card Container
                Container(
                  padding: const EdgeInsets.all(22.0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xffCCCCCC)),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Welcome Back',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Sign in to access parts & lead requests',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      ),
                      const SizedBox(height: 24),

                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email Address',
                          prefixIcon: Icon(Icons.email_rounded, size: 20),
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
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          prefixIcon: Icon(Icons.lock_rounded, size: 20),
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
                          child: isLoading
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Sign In'),
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
                            builder: (_) => RegisterCustomerScreen(returnToPartId: widget.returnToPartId),
                          ),
                        );
                      },
                      icon: Icon(Icons.person_add_rounded, size: 18, color: Theme.of(context).primaryColor),
                      label: Text('Customer Signup', style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
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
                      icon: Icon(Icons.storefront_rounded, size: 18, color: Theme.of(context).primaryColor),
                      label: Text('Vendor Signup', style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
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
