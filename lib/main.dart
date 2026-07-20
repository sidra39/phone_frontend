import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/services/auth_provider.dart';
import 'features/notifications/services/notification_provider.dart';
import 'features/splash/screens/splash_screen.dart';

void main() {
  runApp(const MyApp());
}

/// MyApp
/// Root Widget of the Phone Parts Finder application.
/// Sets up state management (MultiProvider), app theme, and splash screen entry point.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(),
        ),
        ChangeNotifierProvider<NotificationProvider>(
          create: (_) => NotificationProvider(),
        ),
      ],
      child: MaterialApp(
        title: 'Phone Parts Finder',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.appTheme,
        home: const SplashScreen(),
      ),
    );
  }
}
