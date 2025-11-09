import 'package:flutter/material.dart';
import 'screens/welcome_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/bnav_container_screen.dart';
import 'screens/notif_screen.dart';
import 'screens/history_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/pool_screen.dart';
import 'screens/detail_pool_screen.dart';
import 'screens/create_pool_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      initialRoute: '/',

      routes: {
        '/': (context) => const WelcomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),

        '/bnav': (context) => const BnavContainerScreen(),
        '/pool': (context) => const PoolScreen(),
        '/detail-pool': (context) => const DetailPoolScreen(),
        '/create-pool': (context) => const CreatePoolScreen(),
        '/notif': (context) => const NotifScreen(),
        '/history': (context) => const HistoryScreen(),
        '/profile': (context) => const ProfileScreen(),
      },
    );
  }
}
