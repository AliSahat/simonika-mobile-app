// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../pool/pool_screen.dart';
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

  final List<Map<String, dynamic>> _navItems = [
    {
      'icon': Icons.water_drop_outlined,
      'activeIcon': Icons.water_drop_rounded,
      'label': 'Wadah',
      'color': Colors.blue,
    },
    {
      'icon': Icons.history_outlined,
      'activeIcon': Icons.history_rounded,
      'label': 'Riwayat',
      'color': Colors.amber,
    },
    {
      'icon': Icons.person_outline,
      'activeIcon': Icons.person_rounded,
      'label': 'Profil',
      'color': Colors.purple,
    },
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: _screens[_selectedIndex],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 24,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade100, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
                  _navItems.length,
                  (index) => _buildNavItem(
                    index: index,
                    item: _navItems[index],
                    isSelected: _selectedIndex == index,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required Map<String, dynamic> item,
    required bool isSelected,
  }) {
    final color = item['color'] as Color;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onItemTapped(index),
          splashColor: color.withOpacity(0.1),
          highlightColor: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            padding: EdgeInsets.symmetric(
              vertical: isSelected ? 10 : 10,
              horizontal: 8,
            ),
            decoration: BoxDecoration(
              color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedScale(
                  duration: const Duration(milliseconds: 300),
                  scale: isSelected ? 1.2 : 1.0,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? color.withOpacity(0.15)
                          : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isSelected ? item['activeIcon'] : item['icon'],
                      color: color,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                AnimatedOpacity(
                  opacity: isSelected ? 1.0 : 0.7,
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    item['label'],
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w600,
                      color: isSelected ? color : Colors.grey.shade600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
