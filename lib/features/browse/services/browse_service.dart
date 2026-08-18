import '../../../core/network/api_client.dart';
import '../../customer/models/review_model.dart';
import '../../vendor/models/category_model.dart';
import '../models/browse_part_model.dart';

/// BrowseService
/// Public network service for searching parts, retrieving details, and reading vendor reviews without auth headers.
class BrowseService {
  final ApiClient _apiClient;

  BrowseService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// Public Search (GET /parts/search)
  Future<List<BrowsePartModel>> searchParts({
    int? brandId,
    int? partTypeId,
    String? model,
    String? city,
  }) async {
    final Map<String, String> queryParams = {};
    if (brandId != null) queryParams['brandId'] = brandId.toString();
    if (partTypeId != null) queryParams['partTypeId'] = partTypeId.toString();
    if (model != null && model.trim().isNotEmpty) queryParams['model'] = model.trim();
    if (city != null && city.trim().isNotEmpty) queryParams['city'] = city.trim();

    final Uri uri = Uri(path: '/parts/search', queryParameters: queryParams.isEmpty ? null : queryParams);
    final response = await _apiClient.get(uri.toString());

    final List list = response['data'] ?? [];
    return list.map((item) => BrowsePartModel.fromJson(item)).toList();
  }

  /// Public Part Details (GET /parts/:id)
  Future<Map<String, dynamic>> getPartDetails(int partId) async {
    final response = await _apiClient.get('/parts/$partId');
    return response['data'];
  }

  /// Public Vendor Reviews (GET /customer/vendors/:vendorId/reviews)
  Future<List<ReviewModel>> getVendorReviews(int vendorId) async {
    final response = await _apiClient.get('/customer/vendors/$vendorId/reviews');
    final List list = response['data'] ?? [];
    return list.map((item) => ReviewModel.fromJson(item)).toList();
  }

  /// Public Brands (GET /categories/brands)
  Future<List<CategoryModel>> getBrands() async {
    final response = await _apiClient.get('/categories/brands');
    final List list = response['data'] ?? [];
    return list.map((item) => CategoryModel.fromJson(item)).toList();
  }

  /// Public Part Types (GET /categories/part-types)
  Future<List<CategoryModel>> getPartTypes() async {
    final response = await _apiClient.get('/categories/part-types');
    final List list = response['data'] ?? [];
    return list.map((item) => CategoryModel.fromJson(item)).toList();
  }
}