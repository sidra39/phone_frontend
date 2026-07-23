import 'package:flutter/material.dart';
import 'customer_profile_screen.dart';
import 'my_requests_screen.dart';
import 'search_screen.dart';

/// CustomerDashboardScreen
/// Main customer shell managing bottom navigation tabs: Search, My Requests, and Profile.
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
    CustomerProfileScreen(),
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
              icon: const Icon(Icons.search_rounded),
              activeIcon: Icon(Icons.search_rounded, color: Theme.of(context).primaryColor),
              label: 'Search Parts',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.receipt_long_rounded),
              activeIcon: Icon(Icons.receipt_long_rounded, color: Theme.of(context).primaryColor),
              label: 'My Requests',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person_rounded),
              activeIcon: Icon(Icons.person_rounded, color: Theme.of(context).primaryColor),
              label: 'Account',
            ),
          ],
        ),
      ),
    );
  }
}
