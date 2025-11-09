import 'package:flutter/material.dart';
import 'pool_screen.dart';
import 'notif_screen.dart';
import 'profile_screen.dart';
import 'history_screen.dart';

class BnavContainerScreen extends StatefulWidget {
  const BnavContainerScreen({super.key});

  @override
  State<BnavContainerScreen> createState() => _BnavContainerScreenState();
}

class _BnavContainerScreenState extends State<BnavContainerScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    PoolScreen(),
    NotifScreen(),
    HistoryScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,

        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.pool_outlined),
            activeIcon: Icon(Icons.pool),
            label: 'Pool',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_outlined),
            activeIcon: Icon(Icons.notifications),
            label: 'Notif',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
