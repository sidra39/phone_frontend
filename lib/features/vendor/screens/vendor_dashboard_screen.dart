import 'package:flutter/material.dart';
import 'leads_screen.dart';
import 'my_commissions_screen.dart';
import 'my_parts_screen.dart';
import 'vendor_profile_screen.dart';
import '../../chat/screens/chat_rooms_screen.dart';

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
    ChatRoomsScreen(),
    VendorProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          border: Border(
            top: BorderSide(color: const Color(0xffCCCCCC), width: 1),
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
          selectedItemColor: Theme.of(context).primaryColor,
          unselectedItemColor: Colors.grey.shade600,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          type: BottomNavigationBarType.fixed,
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.inventory_2_rounded),
              activeIcon: Icon(Icons.inventory_2_rounded, color: Theme.of(context).primaryColor),
              label: 'My Parts',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.receipt_long_rounded),
              activeIcon: Icon(Icons.receipt_long_rounded, color: Theme.of(context).primaryColor),
              label: 'Leads',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.payments_rounded),
              activeIcon: Icon(Icons.payments_rounded, color: Theme.of(context).primaryColor),
              label: 'Commissions',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.chat_bubble_outline_rounded),
              activeIcon: Icon(Icons.chat_bubble_rounded, color: Theme.of(context).primaryColor),
              label: 'Chats',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.storefront_rounded),
              activeIcon: Icon(Icons.storefront_rounded, color: Theme.of(context).primaryColor),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
