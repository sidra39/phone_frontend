import 'package:flutter/material.dart';
import 'customer_profile_screen.dart';
import 'my_requests_screen.dart';
import 'qr_scanner_screen.dart';
import 'search_screen.dart';

/// CustomerDashboardScreen
/// Main customer shell managing cyber glass bottom navigation tabs: Search, My Requests, Scan QR, and Profile.
class CustomerDashboardScreen extends StatefulWidget {
  const CustomerDashboardScreen({super.key});

  @override
  State<CustomerDashboardScreen> createState() => _CustomerDashboardScreenState();
}

class _CustomerDashboardScreenState extends State<CustomerDashboardScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    SearchScreen(),
    MyRequestsScreen(),
    QrScannerScreen(),
    CustomerProfileScreen(),
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
          selectedItemColor: const Color(0xff00E5FF),
          unselectedItemColor: Colors.grey.shade600,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.search_rounded),
              activeIcon: Icon(Icons.search_rounded, color: Color(0xff00E5FF)),
              label: 'Search Parts',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_rounded),
              activeIcon: Icon(Icons.receipt_long_rounded, color: Color(0xff00E5FF)),
              label: 'My Requests',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.qr_code_scanner_rounded),
              activeIcon: Icon(Icons.qr_code_scanner_rounded, color: Color(0xff00E5FF)),
              label: 'Verify QR',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              activeIcon: Icon(Icons.person_rounded, color: Color(0xff00E5FF)),
              label: 'Account',
            ),
          ],
        ),
      ),
    );
  }
}
