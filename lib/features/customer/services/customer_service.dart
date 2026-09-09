import '../../../core/network/api_client.dart';
import '../../vendor/models/category_model.dart';
import '../models/request_model.dart';
import '../models/review_model.dart';
import '../models/search_result_model.dart';

/// CustomerSearchResult
/// Response container holding search list, fallback indicator, and server message.
class CustomerSearchResult {
  final bool fallback;
  final String message;
  final List<SearchResultModel> results;

  CustomerSearchResult({
    required this.fallback,
    required this.message,
    required this.results,
  });
}

/// CustomerService
/// Handles HTTP API communications for customer functionalities.
class CustomerService {
  final ApiClient _apiClient;

  CustomerService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// Gets customer profile details
  Future<Map<String, dynamic>> getMyProfile(String token) async {
    final response = await _apiClient.get('/customer/profile', token: token);
    return response['data'];
  }

  /// Updates customer city
  Future<void> updateMyProfile(String token, String city) async {
    await _apiClient.put('/customer/profile', {'city': city}, token: token);
  }

  /// Searches for available phone parts with optional filters
  Future<CustomerSearchResult> searchParts(
    String token, {
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
    final response = await _apiClient.get(uri.toString(), token: token);

    final List list = response['data'] ?? [];
    final results = list.map((item) => SearchResultModel.fromJson(item)).toList();

    return CustomerSearchResult(
      fallback: response['fallback'] == true,
      message: response['message'] ?? '',
      results: results,
    );
  }

  /// Sends a part request to a vendor with optional Home Delivery options
  Future<RequestModel> createRequest(
    String token,
    int partId, {
    String deliveryType = 'shop_pickup',
    String? deliveryAddress,
    String? deliveryCity,
    String? deliveryPhone,
    String? deliveryNotes,
  }) async {
    final response = await _apiClient.post(
      '/customer/requests',
      {
        'part_id': partId,
        'delivery_type': deliveryType,
        'delivery_address': deliveryAddress,
        'delivery_city': deliveryCity,
        'delivery_phone': deliveryPhone,
        'delivery_notes': deliveryNotes,
      },
      token: token,
    );
    return RequestModel.fromJson(response['data']);
  }

  /// Fetches requests made by logged-in customer
  Future<List<RequestModel>> getMyRequests(String token) async {
    final response = await _apiClient.get('/customer/requests', token: token);
    final List list = response['data'] ?? [];
    return list.map((item) => RequestModel.fromJson(item)).toList();
  }

  /// Submits a review for a responded/available request
  Future<void> addReview(
    String token, {
    required int requestId,
    required int rating,
    String? comment,
  }) async {
    await _apiClient.post(
      '/customer/reviews',
      {
        'request_id': requestId,
        'rating': rating,
        'comment': comment,
      },
      token: token,
    );
  }

  /// Fetches public reviews for a specific vendor
  Future<List<ReviewModel>> getVendorReviews(int vendorId) async {
    final response = await _apiClient.get('/customer/vendors/$vendorId/reviews');
    final List list = response['data'] ?? [];
    return list.map((item) => ReviewModel.fromJson(item)).toList();
  }

  /// Fetches brands for search filter dropdown
  Future<List<CategoryModel>> getBrands() async {
    final response = await _apiClient.get('/categories/brands');
    final List list = response['data'] ?? [];
    return list.map((item) => CategoryModel.fromJson(item)).toList();
  }

  /// Fetches part types for search filter dropdown
  Future<List<CategoryModel>> getPartTypes() async {
    final response = await _apiClient.get('/categories/part-types');
    final List list = response['data'] ?? [];
    return list.map((item) => CategoryModel.fromJson(item)).toList();
  }
  /// Fetches public part details including authenticity fields & vendor shop info
  Future<Map<String, dynamic>> getPartDetails(int partId) async {
    final response = await _apiClient.get('/parts/$partId');
    return response['data'];
  }

  /// Verifies a delivery scan and performs anti-fake / duplicate barcode security checks
  Future<Map<String, dynamic>> verifyDelivery(String token, int partId, int? requestId, String scannedBarcode) async {
    final response = await _apiClient.post(
      '/customer/verify-delivery',
      {
        'part_id': partId,
        'request_id': requestId,
        'scanned_barcode': scannedBarcode,
      },
      token: token,
    );
    return response;
  }
}
