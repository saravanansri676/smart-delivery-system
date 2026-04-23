import 'package:shared_preferences/shared_preferences.dart';

/// Manages login session persistence.
/// Saves session data on login, clears on logout.
/// App reads this on startup to skip login screen.
class SessionService {

  // ── Keys ────────────────────────────────────────────────
  static const String _keyRole = 'session_role';
  static const String _keyDriverId = 'session_driver_id';
  static const String _keyDriverName = 'session_driver_name';
  static const String _keyManagerId = 'session_manager_id';
  static const String _keyManagerName = 'session_manager_name';
  static const String _keyManagerEmail = 'session_manager_email';
  static const String _keyCompanyName = 'session_company_name';
  static const String _keyManagerIdForDriver =
      'session_manager_id_for_driver';

  // ── Save driver session ──────────────────────────────────
  static Future<void> saveDriverSession({
    required String driverId,
    required String driverName,
    required String managerId,
    required String companyName,
    required String mobileNumber,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyRole, 'DRIVER');
    await prefs.setString(_keyDriverId, driverId);
    await prefs.setString(_keyDriverName, driverName);
    await prefs.setString(
        _keyManagerIdForDriver, managerId);
    await prefs.setString(_keyCompanyName, companyName);
  }

  // ── Save manager session ─────────────────────────────────
  static Future<void> saveManagerSession({
    required String managerId,
    required String managerName,
    required String managerEmail,
    required String companyName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyRole, 'MANAGER');
    await prefs.setString(_keyManagerId, managerId);
    await prefs.setString(_keyManagerName, managerName);
    await prefs.setString(
        _keyManagerEmail, managerEmail);
    await prefs.setString(_keyCompanyName, companyName);
  }

  // ── Clear session on logout ──────────────────────────────
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // ── Get saved role ───────────────────────────────────────
  // Returns 'DRIVER', 'MANAGER', or null if not logged in
  static Future<String?> getSavedRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyRole);
  }

  // ── Get saved driver session ─────────────────────────────
  static Future<Map<String, String>?> getDriverSession() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString(_keyRole);
    if (role != 'DRIVER') return null;

    final driverId = prefs.getString(_keyDriverId);
    if (driverId == null || driverId.isEmpty) return null;

    return {
      'driverId': driverId,
      'driverName': prefs.getString(_keyDriverName) ?? '',
      'managerId':
      prefs.getString(_keyManagerIdForDriver) ?? '',
      'companyName':
      prefs.getString(_keyCompanyName) ?? '',
    };
  }

  // ── Get saved manager session ────────────────────────────
  static Future<Map<String, String>?> getManagerSession() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString(_keyRole);
    if (role != 'MANAGER') return null;

    final managerId = prefs.getString(_keyManagerId);
    if (managerId == null || managerId.isEmpty) return null;

    return {
      'managerId': managerId,
      'managerName':
      prefs.getString(_keyManagerName) ?? '',
      'managerEmail':
      prefs.getString(_keyManagerEmail) ?? '',
      'companyName':
      prefs.getString(_keyCompanyName) ?? '',
    };
  }
}