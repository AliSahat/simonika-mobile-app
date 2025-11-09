import 'package:flutter/material.dart';
import '../pool/pool_screen.dart';
// import '../notif/notif_screen.dart';
import '../profile/profile_screen.dart';
import '../history/history_screen.dart';

class BnavContainerScreen extends StatefulWidget {
  const BnavContainerScreen({super.key});

  @override
  State<BnavContainerScreen> createState() => _BnavContainerScreenState();
}

class _BnavContainerScreenState extends State<BnavContainerScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    PoolScreen(),
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
            label: 'Wadah',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history),
            label: 'Riwayat',
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
