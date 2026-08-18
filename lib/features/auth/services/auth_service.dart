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

  /// Registers a new vendor.
  /// Calls POST /auth/register/vendor.
  Future<dynamic> registerVendor({
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
    return await _apiClient.post('/auth/register/vendor', {
      'name': name,
      'email': email,
      'password': password,
      'phone': phone,
      'shop_name': shopName,
      'verification_docs': verificationDocs,
      'city': city,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
    });
  }
}