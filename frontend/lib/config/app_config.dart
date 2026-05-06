/// Application Configuration
/// Single source of truth for all app settings.
///
/// HOW TO USE:
/// Replace every hardcoded 'http://10.0.2.2:8080'
/// in every screen with AppConfig.baseUrl
///
/// HOW TO CHANGE URL FOR REAL DEVICE:
/// Just change _localBaseUrl below to your
/// machine's local IP address (e.g. 192.168.1.5)
/// Find your IP: run `ipconfig` (Windows)
///              or `ifconfig` (Mac/Linux)
///
/// Both your PC and phone must be on the
/// same WiFi network for this to work.

class AppConfig {
  AppConfig._(); // prevent instantiation

  // ── App Info ────────────────────────────────────────────
  static const String appName = 'Smart Delivery System';
  static const String appVersion = '1.0.0';

  // ── Base URL ────────────────────────────────────────────
  // Android emulator uses 10.0.2.2 to reach host machine.
  // Real Android/iOS devices use the host machine's
  // actual local IP address on the same WiFi network.
  //
  // To switch between emulator and real device,
  // change _useEmulator to true or false.
  static const bool _useEmulator = true;

  static const String _emulatorBaseUrl =
      'http://10.0.2.2:8080';

  //  CHANGE THIS to your machine's local IP
  // when testing on a real device.
  // Example: 'http://192.168.1.100:8080'
  static const String _localBaseUrl =
      'http://10.210.244.193:8080';

  // Production URL — update before going live
  static const String _productionBaseUrl =
      'https://api.smartdelivery.com';

  // ── Active base URL ─────────────────────────────────────
  // Reads ENVIRONMENT at build time:
  //   flutter run --dart-define=ENVIRONMENT=prod
  //   flutter run --dart-define=ENVIRONMENT=device
  //   flutter run  (defaults to emulator/dev)
  static const String _environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'dev',
  );

  static String get baseUrl {
    switch (_environment) {
      case 'prod':
        return _productionBaseUrl;
      case 'device':
      // Real device on same WiFi as your PC
        return _localBaseUrl;
      case 'dev':
      default:
        return _useEmulator
            ? _emulatorBaseUrl
            : _localBaseUrl;
    }
  }

  // ── Timeouts ─────────────────────────────────────────────
  // How long to wait before giving up on a request.
  static const Duration connectTimeout =
  Duration(seconds: 15);
  static const Duration receiveTimeout =
  Duration(seconds: 30);

  // ── Retry ────────────────────────────────────────────────
  // How many times to retry a failed request.
  static const int maxRetries = 2;
  static const Duration retryDelay =
  Duration(seconds: 2);

  // ── Polling ──────────────────────────────────────────────
  static const Duration notificationPollInterval =
  Duration(seconds: 30);

  // ── Default Location (Coimbatore) ────────────────────────
  // Used as fallback when depot location is not set.
  static const double defaultLatitude = 11.0168;
  static const double defaultLongitude = 76.9674;

  // ── Work Hours ───────────────────────────────────────────
  static const String workEndTime = '16:00';

  // ── Helper ───────────────────────────────────────────────
  static bool get isProduction => _environment == 'prod';
  static bool get isDev => _environment == 'dev';
  static bool get isDevice => _environment == 'device';
}