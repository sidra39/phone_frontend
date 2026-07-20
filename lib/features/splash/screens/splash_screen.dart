import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/app_logo.dart';
import '../../admin/screens/admin_dashboard_screen.dart';
import '../../auth/screens/login_screen.dart';
import '../../auth/services/auth_provider.dart';
import '../../customer/screens/customer_dashboard_screen.dart';
import '../../vendor/screens/vendor_dashboard_screen.dart';

/// SplashScreen
/// Initial landing screen displaying the PPF branding logo with entrance animations,
/// checking user session, and auto-navigating to the appropriate dashboard.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _scaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();
    _checkSessionAndNavigate();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkSessionAndNavigate() async {
    // Wait for splash animation (2.2 seconds minimum display time)
    await Future.delayed(const Duration(milliseconds: 2200));

    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Try restoring saved session
    final isLoggedIn = await authProvider.tryAutoLogin();

    if (!mounted) return;

    if (isLoggedIn && authProvider.currentUser != null) {
      final role = authProvider.currentUser!.role.toLowerCase();
      Widget targetScreen;

      if (role == 'admin') {
        targetScreen = const AdminDashboardScreen();
      } else if (role == 'vendor') {
        targetScreen = const VendorDashboardScreen();
      } else {
        targetScreen = const CustomerDashboardScreen();
      }

      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, anim1, anim2) => targetScreen,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, anim1, anim2) => const LoginScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff12141C),
      body: Stack(
        children: [
          // Background ambient cyan glow circle top right
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xff00E5FF).withValues(alpha: 0.08),
              ),
            ),
          ),

          // Background ambient violet glow circle bottom left
          Positioned(
            bottom: -80,
            left: -60,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xff7C4DFF).withValues(alpha: 0.08),
              ),
            ),
          ),

          // Main Center Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: const AppLogo(
                      iconSize: 120,
                      fontSize: 26,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Text(
                    'Direct Vendor Marketplace & Component Verifier',
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 13,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom Loading Indicator
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Column(
              children: [
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Color(0xff00E5FF),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Loading Phone Parts Finder...',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
