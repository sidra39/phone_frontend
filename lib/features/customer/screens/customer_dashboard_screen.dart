import 'package:flutter/material.dart';
import 'customer_profile_screen.dart';
import 'my_requests_screen.dart';
import 'search_screen.dart';
import '../../browse/screens/browse_home_screen.dart';
import '../../chat/screens/chat_rooms_screen.dart';

/// CustomerDashboardScreen
/// Main customer shell managing permanent bottom navigation tabs: Browse, Search, My Requests, Chats, and Profile.
class CustomerDashboardScreen extends StatefulWidget {
  final int initialIndex;
  const CustomerDashboardScreen({super.key, this.initialIndex = 0});

  static CustomerDashboardScreenState? of(BuildContext context) {
    return context.findAncestorStateOfType<CustomerDashboardScreenState>();
  }

  @override
  State<CustomerDashboardScreen> createState() => CustomerDashboardScreenState();
}

class CustomerDashboardScreenState extends State<CustomerDashboardScreen> {
  late int _currentIndex;

  final List<Widget> _screens = const [
    BrowseHomeScreen(),
    SearchScreen(),
    MyRequestsScreen(),
    ChatRoomsScreen(),
    CustomerProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void setTab(int index) {
    if (index >= 0 && index < _screens.length) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

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
          border: const Border(
            top: BorderSide(color: Color(0xffCCCCCC), width: 1),
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
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontSize: 10),
          type: BottomNavigationBarType.fixed,
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.explore_outlined),
              activeIcon: Icon(Icons.explore_rounded, color: Theme.of(context).primaryColor),
              label: 'Browse',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.search_rounded),
              activeIcon: Icon(Icons.search_rounded, color: Theme.of(context).primaryColor),
              label: 'Search',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.receipt_long_rounded),
              activeIcon: Icon(Icons.receipt_long_rounded, color: Theme.of(context).primaryColor),
              label: 'Requests',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.chat_bubble_outline_rounded),
              activeIcon: Icon(Icons.chat_bubble_rounded, color: Theme.of(context).primaryColor),
              label: 'Chats',
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
