import '../../../core/network/api_client.dart';
import '../models/user_model.dart';

/// AuthService
/// Handles HTTP communications for authentication operations.
class AuthService {
  final ApiClient _apiClient;

  AuthService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// Logs in a user.
  /// Calls POST /auth/login and returns a Map containing 'token' and 'user'.
  Future<Map<String, dynamic>> loginUser(String email, String password) async {
    final response = await _apiClient.post('/auth/login', {
      'email': email,
      'password': password,
    });

    final String token = response['token'];
    final UserModel user = UserModel.fromJson(response['user']);

    return {
      'token': token,
      'user': user,
    };
  }

  /// Registers a new customer.
  /// Calls POST /auth/register/customer.
  Future<dynamic> registerCustomer({
    required String name,
    required String email,
    required String password,
    String? phone,
    required String city,
  }) async {
    return await _apiClient.post('/auth/register/customer', {
      'name': name,
      'email': email,
      'password': password,
      'phone': phone,
      'city': city,
    });
  }

  /// Registers a new vendor with Shop Photo & CNIC Photo files
  Future<dynamic> registerVendor({
    required String name,
    required String email,
    required String password,
    String? phone,
    required String shopName,
    required String city,
    required String address,
    double? latitude,
    double? longitude,
    Map<String, Map<String, dynamic>>? files,
  }) async {
    final fields = <String, String>{
      'name': name,
      'email': email,
      'password': password,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
      'shop_name': shopName,
      'city': city,
      'address': address,
      if (latitude != null) 'latitude': latitude.toString(),
      if (longitude != null) 'longitude': longitude.toString(),
    };

    if (files != null && files.isNotEmpty) {
      return await _apiClient.postMultipart('/auth/register/vendor', fields, files);
    } else {
      return await _apiClient.post('/auth/register/vendor', fields);
    }
  }

  /// Requests a 6-digit OTP code to be sent via email
  Future<dynamic> sendOtp(String email) async {
    return await _apiClient.post('/auth/send-otp', {'email': email});
  }

  /// Verifies a 6-digit OTP code submitted by the user
  Future<dynamic> verifyOtp(String email, String otp) async {
    return await _apiClient.post('/auth/verify-otp', {
      'email': email,
      'otp': otp,
    });
  }

  /// Sends password reset OTP code to user's email
  Future<dynamic> forgotPassword(String email) async {
    return await _apiClient.post('/auth/forgot-password', {'email': email});
  }

  /// Resets user password using OTP code
  Future<dynamic> resetPassword(String email, String otp, String newPassword) async {
    return await _apiClient.post('/auth/reset-password', {
      'email': email,
      'otp': otp,
      'new_password': newPassword,
    });
  }

  /// Fetches latest user profile from server
  Future<UserModel> getProfile(String token, String role) async {
    final endpoint = role == 'vendor' ? '/vendor/profile' : '/customer/profile';
    final res = await _apiClient.get(endpoint, token: token);
    final data = res['data'];
    return UserModel.fromJson(data);
  }
}
