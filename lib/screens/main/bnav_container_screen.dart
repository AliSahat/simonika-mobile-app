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
  // Build destinations on first visit, keeping their state on subsequent visits.
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
    final dark = Theme.of(context).brightness == Brightness.dark;
    final colors = ColorScheme.fromSeed(
      seedColor: const Color(0xFF0878DE),
      brightness: dark ? Brightness.dark : Brightness.light,
    );
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 200);

    return Scaffold(
      backgroundColor: dark ? colors.surface : const Color(0xFFF7FBFF),
      body: IndexedStack(
        index: _selectedIndex,
        children: List.generate(_screens.length, (index) {
          return TickerMode(
            enabled: index == _selectedIndex,
            child: _screens[index] ?? const SizedBox.shrink(),
          );
        }),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Align(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: colors.primary.withValues(alpha: dark ? 0.08 : 0.10),
                    blurRadius: 28,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Material(
                color: colors.surfaceContainerLowest,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                  side: BorderSide(
                      color: colors.outlineVariant.withValues(alpha: 0.6)),
                ),
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.all(8),
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
                              splashColor:
                                  colors.primary.withValues(alpha: 0.12),
                              focusColor:
                                  colors.primary.withValues(alpha: 0.16),
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
                                        color: selected
                                            ? colors.primaryContainer
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Icon(
                                        selected
                                            ? destination.activeIcon
                                            : destination.icon,
                                        size: 24,
                                        color: selected
                                            ? colors.onPrimaryContainer
                                            : colors.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      destination.label,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 13,
                                        height: 1.3,
                                        fontWeight: selected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: selected
                                            ? colors.primary
                                            : colors.onSurfaceVariant,
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
    );
  }
}
