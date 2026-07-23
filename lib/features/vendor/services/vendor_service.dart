import '../../../core/network/api_client.dart';
import '../models/category_model.dart';
import '../models/commission_model.dart';
import '../models/lead_request_model.dart';
import '../models/part_model.dart';
import '../models/vendor_profile_model.dart';

/// VendorService
/// Handles HTTP communications for vendor profiles, parts CRUD, lead requests, and commissions.
class VendorService {
  final ApiClient _apiClient;

  VendorService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// Fetches vendor profile
  Future<VendorProfileModel> getProfile(String token) async {
    final response = await _apiClient.get('/vendor/profile', token: token);
    return VendorProfileModel.fromJson(response['data']);
  }

  /// Updates vendor profile
  Future<VendorProfileModel> updateProfile(String token, Map<String, dynamic> fields) async {
    final response = await _apiClient.put('/vendor/profile', fields, token: token);
    return VendorProfileModel.fromJson(response['data']);
  }

  /// Fetches parts belonging to vendor
  Future<List<PartModel>> getMyParts(String token) async {
    final response = await _apiClient.get('/vendor/parts', token: token);
    final List list = response['data'] ?? [];
    return list.map((item) => PartModel.fromJson(item)).toList();
  }

  /// Adds a new part
  Future<PartModel> addPart(
    String token,
    Map<String, String> fields,
    Map<String, Map<String, dynamic>> files,
  ) async {
    final response = await _apiClient.postMultipart(
      '/vendor/parts',
      fields,
      files,
      token: token,
    );
    return PartModel.fromJson(response['data']);
  }

  /// Updates an existing part
  Future<PartModel> updatePart(
    String token,
    int id,
    Map<String, String> fields,
    Map<String, Map<String, dynamic>> files,
  ) async {
    final response = await _apiClient.postMultipart(
      '/vendor/parts/$id',
      fields,
      files,
      token: token,
      isPut: true,
    );
    return PartModel.fromJson(response['data']);
  }

  /// Deletes a part
  Future<void> deletePart(String token, int id) async {
    await _apiClient.delete('/vendor/parts/$id', token: token);
  }

  /// Fetches vendor's received customer requests
  Future<List<LeadRequestModel>> getVendorRequests(String token) async {
    final response = await _apiClient.get('/vendor/requests', token: token);
    final List list = response['data'] ?? [];
    return list.map((item) => LeadRequestModel.fromJson(item)).toList();
  }

  /// Responds to a customer request ('available' or 'not_available')
  Future<void> respondToRequest(String token, int requestId, String status) async {
    await _apiClient.put('/vendor/requests/$requestId/respond', {'status': status}, token: token);
  }

  /// Submits payment proof URL for a commission
  Future<CommissionModel> uploadCommissionProof(String token, int commissionId, String proofUrl) async {
    final response = await _apiClient.post(
      '/vendor/commissions/$commissionId/proof',
      {'payment_proof_url': proofUrl},
      token: token,
    );
    return CommissionModel.fromJson(response['data']);
  }

  /// Fetches commissions belonging to logged-in vendor
  Future<List<CommissionModel>> getMyCommissions(String token) async {
    final response = await _apiClient.get('/vendor/commissions', token: token);
    final List list = response['data'] ?? [];
    return list.map((item) => CommissionModel.fromJson(item)).toList();
  }

  /// Fetches all brands (public)
  Future<List<CategoryModel>> getBrands() async {
    final response = await _apiClient.get('/categories/brands');
    final List list = response['data'] ?? [];
    return list.map((item) => CategoryModel.fromJson(item)).toList();
  }

  /// Fetches all part types (public)
  Future<List<CategoryModel>> getPartTypes() async {
    final response = await _apiClient.get('/categories/part-types');
    final List list = response['data'] ?? [];
    return list.map((item) => CategoryModel.fromJson(item)).toList();
  }
}
