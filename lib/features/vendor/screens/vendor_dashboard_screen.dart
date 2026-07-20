import 'package:flutter/material.dart';
import 'leads_screen.dart';
import 'my_commissions_screen.dart';
import 'my_parts_screen.dart';
import 'vendor_profile_screen.dart';

/// VendorDashboardScreen
/// Main vendor shell screen featuring a cyber-sleek glass BottomNavigationBar across My Parts, Leads, Commissions, and Profile.
class VendorDashboardScreen extends StatefulWidget {
  const VendorDashboardScreen({super.key});

  @override
  State<VendorDashboardScreen> createState() => _VendorDashboardScreenState();
}

class _VendorDashboardScreenState extends State<VendorDashboardScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    MyPartsScreen(),
    LeadsScreen(),
    MyCommissionsScreen(),
    VendorProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff12141C),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xff1A1D27),
          border: Border(
            top: BorderSide(color: Color(0xff2A2E3D), width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: const Color(0xff7C4DFF),
          unselectedItemColor: Colors.grey.shade600,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.inventory_2_rounded),
              activeIcon: Icon(Icons.inventory_2_rounded, color: Color(0xff7C4DFF)),
              label: 'My Parts',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_rounded),
              activeIcon: Icon(Icons.receipt_long_rounded, color: Color(0xff7C4DFF)),
              label: 'Leads',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.payments_rounded),
              activeIcon: Icon(Icons.payments_rounded, color: Color(0xff7C4DFF)),
              label: 'Commissions',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.storefront_rounded),
              activeIcon: Icon(Icons.storefront_rounded, color: Color(0xff7C4DFF)),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
