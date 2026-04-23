import 'package:flutter/material.dart';
import '../screens/login_screen.dart';
import 'session_service.dart';

/// Call this from any logout button.
/// Clears saved session and navigates to login screen.
Future<void> performLogout(BuildContext context) async {
  // Clear saved session data
  await SessionService.clearSession();

  // Navigate to login screen, removing all routes
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(
        builder: (_) => const LoginScreen()),
        (route) => false,
  );
}

/// Shows a logout confirmation dialog then logs out.
void showLogoutDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16)),
      title: const Text('Logout'),
      content:
      const Text('Are you sure you want to logout?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(context);
            await performLogout(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: const Text('Logout'),
        ),
      ],
    ),
  );
}