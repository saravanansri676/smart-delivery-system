import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/login_screen.dart';
import 'screens/driver/driver_home.dart';
import 'screens/manager/manager_home.dart';
import 'services/session_service.dart';

void main() async {
  // Required before using any plugin (shared_preferences)
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  // Check if user is already logged in
  final Widget startScreen = await _resolveStartScreen();

  runApp(MyApp(startScreen: startScreen));
}

/// Reads saved session and returns the correct start screen.
/// - Driver session saved → DriverHome
/// - Manager session saved → ManagerHome
/// - No session → LoginScreen
Future<Widget> _resolveStartScreen() async {
  try {
    final role = await SessionService.getSavedRole();

    if (role == 'DRIVER') {
      final session =
      await SessionService.getDriverSession();
      if (session != null) {
        return DriverHome(
          driverIdFromLogin: session['driverId'] ?? '',
          driverName: session['driverName'] ?? '',
          managerId: session['managerId'] ?? '',
        );
      }
    }

    if (role == 'MANAGER') {
      final session =
      await SessionService.getManagerSession();
      if (session != null) {
        return ManagerHome(
          managerId: session['managerId'] ?? '',
          managerName: session['managerName'] ?? '',
          managerEmail: session['managerEmail'] ?? '',
          companyName: session['companyName'] ?? '',
        );
      }
    }
  } catch (e) {
    // If anything goes wrong reading session,
    // fall back to login screen safely
    debugPrint('Session read error: $e');
  }

  // No valid session → show login
  return const LoginScreen();
}

class MyApp extends StatelessWidget {
  final Widget startScreen;

  const MyApp({super.key, required this.startScreen});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Delivery System',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0D47A1),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
        cardTheme: CardThemeData(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Color(0xFF0D47A1),
          foregroundColor: Colors.white,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 2,
            padding: const EdgeInsets.symmetric(
                vertical: 16, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
            BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
            BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
                color: Color(0xFF0D47A1), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 16),
        ),
      ),
      //  Start at resolved screen instead of always LoginScreen
      home: startScreen,
    );
  }
}