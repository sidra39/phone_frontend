import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

/// ApiConstants
/// Holds API-related configuration and endpoint paths.
class ApiConstants {
  ApiConstants._(); // Private constructor to prevent instantiation

  // Base URL pointing to the backend API.
  // Using 10.0.2.2 for Android emulator to connect to localhost (3000).
  // If you are using a physical Android device, replace with your development machine's local IP address (e.g. 'http://192.168.1.XX:3000/api').
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000/api';
    }
    try {
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:3000/api';
      }
    } catch (_) {
      // Fallback if Platform checks are not supported on current platform
    }
    return 'http://localhost:3000/api';
  }

  // Future feature routes placeholders

  // Auth Endpoints:
  // static const String login = '/auth/login';
  // static const String register = '/auth/register';

  // Vendor Endpoints:
  // static const String vendorParts = '/vendor/parts';

  // Customer Endpoints:
  // static const String customerSearch = '/customer/search';

  // Admin Endpoints:
  // static const String adminDashboard = '/admin/dashboard';
}
