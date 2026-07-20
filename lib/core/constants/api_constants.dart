/// ApiConstants
/// Holds API-related configuration and endpoint paths.
class ApiConstants {
  ApiConstants._(); // Private constructor to prevent instantiation

  // Base URL pointing to the backend API.
  // Using 10.0.2.2 for Android emulator to connect to localhost (3000)
  static const String baseUrl = 'http://localhost:3000/api';

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
