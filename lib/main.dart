import 'package:flutter/material.dart';
import 'screens/main/welcome_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/main/bnav_container_screen.dart';
import 'screens/notif/notif_screen.dart';
import 'screens/history/history_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/pool/pool_screen.dart';
import 'screens/pool/detail_pool_screen.dart';
import 'screens/pool/create_pool_screen.dart';
import 'screens/pool/update_pool_screen.dart';

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
        '/update-pool': (context) => const UpdatePoolScreen(),
        '/notif': (context) => const NotifScreen(),
        '/history': (context) => const HistoryScreen(),
        '/profile': (context) => const ProfileScreen(),
      },
    );
  }
}
