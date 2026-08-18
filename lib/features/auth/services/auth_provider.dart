import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../notifications/services/notification_provider.dart';
import '../models/user_model.dart';
import 'auth_service.dart';

/// AuthProvider
/// Manages authentication state (token, currentUser, isLoading) and handles persistence.
class AuthProvider extends ChangeNotifier {
  final AuthService _authService;

  AuthProvider({AuthService? authService})
      : _authService = authService ?? AuthService();

  String? _token;
  UserModel? _currentUser;
  bool _isLoading = false;

  String? get token => _token;
  UserModel? get currentUser => _currentUser;
  UserModel? get user => _currentUser;
  bool get isLoading => _isLoading;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Handles user login, updating state, starting notification polling, and persisting session.
  Future<UserModel> login(
    String email,
    String password, {
    NotificationProvider? notificationProvider,
  }) async {
    _setLoading(true);
    try {
      final result = await _authService.loginUser(email, password);
      _token = result['token'] as String;
      _currentUser = result['user'] as UserModel;

      // Save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('jwt_token', _token!);
      await prefs.setString('user_data', jsonEncode(_currentUser!.toJson()));

      if (notificationProvider != null && _token != null) {
        notificationProvider.startPolling(_token!);
      }

      _setLoading(false);
      return _currentUser!;
    } catch (e) {
      _setLoading(false);
      rethrow;
    }
  }

  /// Registers a customer.
  Future<void> registerCustomer({
    required String name,
    required String email,
    required String password,
    String? phone,
    required String city,
  }) async {
    _setLoading(true);
    try {
      await _authService.registerCustomer(
        name: name,
        email: email,
        password: password,
        phone: phone,
        city: city,
      );
      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      rethrow;
    }
  }

  /// Registers a vendor.
  Future<void> registerVendor({
    required String name,
    required String email,
    required String password,
    String? phone,
    required String shopName,
    String? verificationDocs,
    required String city,
    required String address,
    double? latitude,
    double? longitude,
  }) async {
    _setLoading(true);
    try {
      await _authService.registerVendor(
        name: name,
        email: email,
        password: password,
        phone: phone,
        shopName: shopName,
        verificationDocs: verificationDocs,
        city: city,
        address: address,
        latitude: latitude,
        longitude: longitude,
      );
      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      rethrow;
    }
  }

  /// Restores session from SharedPreferences if available.
  Future<bool> tryAutoLogin({NotificationProvider? notificationProvider}) async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('jwt_token') || !prefs.containsKey('user_data')) {
      return false;
    }

    try {
      final tokenStr = prefs.getString('jwt_token');
      final userDataStr = prefs.getString('user_data');
      if (tokenStr == null || userDataStr == null) return false;

      final userData = jsonDecode(userDataStr) as Map<String, dynamic>;
      _token = tokenStr;
      _currentUser = UserModel.fromJson(userData);

      if (notificationProvider != null && _token != null) {
        notificationProvider.startPolling(_token!);
      }

      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Refreshes current user profile from backend server to sync status changes (e.g. approved deposit, verification)
  Future<UserModel?> refreshProfile() async {
    if (_token == null || _currentUser == null) return null;
    try {
      final updatedUser = await _authService.getProfile(_token!, _currentUser!.role);
      _currentUser = updatedUser;

      // Update SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_data', jsonEncode(_currentUser!.toJson()));

      notifyListeners();
      return _currentUser;
    } catch (_) {
      return _currentUser;
    }
  }

  /// Logs out the user, clearing state, stopping polling, and clearing SharedPreferences.
  Future<void> logout({NotificationProvider? notificationProvider}) async {
    if (notificationProvider != null) {
      notificationProvider.stopPolling();
    }
    _token = null;
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('user_data');
    notifyListeners();
  }
}
