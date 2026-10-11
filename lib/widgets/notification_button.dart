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
      builder: (context, _) => IconButton(
        tooltip: notifications.unreadCount == 0
            ? 'Notifikasi'
            : 'Notifikasi, ${notifications.unreadCount} belum dibaca',
        onPressed: () => Navigator.pushNamed(context, '/notif'),
        icon: Badge(
          isLabelVisible: notifications.unreadCount > 0,
          label: Text(notifications.unreadCount > 99
              ? '99+'
              : '${notifications.unreadCount}'),
          child: const Icon(Icons.notifications_outlined),
        ),
      ),
    );
  }
}
