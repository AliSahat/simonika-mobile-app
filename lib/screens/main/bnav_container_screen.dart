import 'dart:ui';
import 'package:flutter/material.dart';
import '../../services/notification_service.dart';
import '../pool/pool_screen.dart';
import '../profile/profile_screen.dart';
import '../history/history_screen.dart';

class BnavContainerScreen extends StatefulWidget {
  const BnavContainerScreen({super.key});

  @override
  State<BnavContainerScreen> createState() => _BnavContainerScreenState();
}

class _BnavContainerScreenState extends State<BnavContainerScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    NotificationService.instance.addListener(_announceAlert);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) NotificationService.instance.start();
    });
  }

  String? _announcedAlert;

  void _announceAlert() {
    final alert = NotificationService.instance.latestAlert;
    if (alert == null || alert.id == _announcedAlert) return;
    _announcedAlert = alert.id;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || alert.isRead) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${alert.title} • ${alert.poolName}'),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Lihat',
          onPressed: () => Navigator.pushNamed(context, '/notif'),
        ),
      ));
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      NotificationService.instance.start();
    } else {
      NotificationService.instance.pause();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    NotificationService.instance.removeListener(_announceAlert);
    NotificationService.instance.stop();
    super.dispose();
  }

  int _selectedIndex = 0;
  final List<Widget?> _screens = [const PoolScreen(), null, null];

  static const _destinations = [
    (
      label: 'Wadah',
      icon: Icons.water_drop_outlined,
      activeIcon: Icons.water_drop_rounded
    ),
    (
      label: 'Riwayat',
      icon: Icons.history_outlined,
      activeIcon: Icons.history_rounded
    ),
    (
      label: 'Profil',
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded
    ),
  ];

  void _selectDestination(int index) {
    if (_selectedIndex == index) return;
    setState(() {
      _screens[index] ??= switch (index) {
        1 => const HistoryScreen(),
        2 => const ProfileScreen(),
        _ => const PoolScreen(),
      };
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 200);

    return Scaffold(
      backgroundColor: const Color(0xFF060911),
      extendBody: true,
      body: Stack(
        children: [
          IgnorePointer(
            child: Stack(
              children: [
                Positioned(
                  top: -60,
                  right: -40,
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
                    child: Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFF59E0B).withOpacity(0.32),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 240,
                  left: -70,
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                    child: Container(
                      width: 260,
                      height: 260,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF2563EB).withOpacity(0.28),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 120,
                  left: 80,
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
                    child: Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF10B981).withOpacity(0.22),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -40,
                  right: -40,
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
                    child: Container(
                      width: 240,
                      height: 240,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF06B6D4).withOpacity(0.26),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          IndexedStack(
            index: _selectedIndex,
            children: List.generate(_screens.length, (index) {
              return TickerMode(
                enabled: index == _selectedIndex,
                child: _screens[index] ?? const SizedBox.shrink(),
              );
            }),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Align(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.45),
                    blurRadius: 30,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF181F30).withOpacity(0.76),
                            const Color(0xFF101624).withOpacity(0.66),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.09),
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: List.generate(_destinations.length, (index) {
                          final destination = _destinations[index];
                          final selected = index == _selectedIndex;
                          return Expanded(
                            child: Semantics(
                              button: true,
                              selected: selected,
                              label: destination.label,
                              onTap: () => _selectDestination(index),
                              excludeSemantics: true,
                              child: Tooltip(
                                message: destination.label,
                                child: InkWell(
                                  onTap: () => _selectDestination(index),
                                  borderRadius: BorderRadius.circular(20),
                                  splashColor: const Color(0xFF2563EB)
                                      .withOpacity(0.16),
                                  focusColor: const Color(0xFF2563EB)
                                      .withOpacity(0.20),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4, vertical: 8),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        AnimatedContainer(
                                          duration: duration,
                                          curve: Curves.easeOutCubic,
                                          width: 64,
                                          height: 36,
                                          decoration: BoxDecoration(
                                            gradient: selected
                                                ? const LinearGradient(
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                    colors: [
                                                      Color(0xFF2563EB),
                                                      Color(0xFF1D8CF8),
                                                    ],
                                                  )
                                                : null,
                                            color: selected
                                                ? null
                                                : Colors.transparent,
                                            borderRadius:
                                                BorderRadius.circular(18),
                                            boxShadow: selected
                                                ? [
                                                    BoxShadow(
                                                      color: const Color(
                                                              0xFF2563EB)
                                                          .withOpacity(0.45),
                                                      blurRadius: 14,
                                                      offset:
                                                          const Offset(0, 4),
                                                    ),
                                                  ]
                                                : null,
                                          ),
                                          child: Icon(
                                            selected
                                                ? destination.activeIcon
                                                : destination.icon,
                                            size: 22,
                                            color: selected
                                                ? const Color(0xFFF8FAFC)
                                                : const Color(0xFF94A3B8),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          destination.label,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 12,
                                            height: 1.3,
                                            fontWeight: selected
                                                ? FontWeight.w700
                                                : FontWeight.w500,
                                            color: selected
                                                ? const Color(0xFFF8FAFC)
                                                : const Color(0xFF94A3B8),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
