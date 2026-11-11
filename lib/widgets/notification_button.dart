import 'package:flutter/material.dart';
import '../services/notification_service.dart';

class NotificationButton extends StatelessWidget {
  const NotificationButton({super.key, this.service});
  final NotificationService? service;

  @override
  Widget build(BuildContext context) {
    final notifications = service ?? NotificationService.instance;
    return ListenableBuilder(
      listenable: notifications,
      builder: (context, _) => Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.06),
          border: Border.all(color: Colors.white.withOpacity(0.08), width: 1.0),
        ),
        child: IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
          tooltip: notifications.unreadCount == 0
              ? 'Notifikasi'
              : 'Notifikasi, ${notifications.unreadCount} belum dibaca',
          onPressed: () => Navigator.pushNamed(context, '/notif'),
          icon: Badge(
            isLabelVisible: notifications.unreadCount > 0,
            backgroundColor: const Color(0xFF2563EB),
            textColor: const Color(0xFFF8FAFC),
            label: Text(
              notifications.unreadCount > 99
                  ? '99+'
                  : '${notifications.unreadCount}',
              style: const TextStyle(
                color: Color(0xFFF8FAFC),
                fontSize: 10,
                fontWeight: FontWeight.w700,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            child: const Icon(
              Icons.notifications_outlined,
              size: 19,
              color: Color(0xFFF8FAFC),
            ),
          ),
        ),
      ),
    );
  }
}
