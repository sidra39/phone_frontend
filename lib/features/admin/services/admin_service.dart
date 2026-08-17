import '../../../core/network/api_client.dart';
import '../../reports/models/report_model.dart';
import '../../vendor/models/category_model.dart';
import '../../vendor/models/commission_model.dart';
import '../models/user_admin_model.dart';
import '../models/vendor_admin_model.dart';

/// AdminDashboardStats
/// Container for dashboard counters.
class AdminDashboardStats {
  final int totalVendors;
  final int totalCustomers;
  final int totalParts;
  final int totalRequests;
  final int pendingVendorApprovals;

  AdminDashboardStats({
    required this.totalVendors,
    required this.totalCustomers,
    required this.totalParts,
    required this.totalRequests,
    required this.pendingVendorApprovals,
  });

  factory AdminDashboardStats.fromJson(Map<String, dynamic> json) {
    return AdminDashboardStats(
      totalVendors: json['totalVendors'] ?? 0,
      totalCustomers: json['totalCustomers'] ?? 0,
      totalParts: json['totalParts'] ?? 0,
      totalRequests: json['totalRequests'] ?? 0,
      pendingVendorApprovals: json['pendingVendorApprovals'] ?? 0,
    );
  }
}

/// AdminService
/// Handles HTTP communications for admin endpoints.
class AdminService {
  final ApiClient _apiClient;

  AdminService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// Gets dashboard statistics
  Future<AdminDashboardStats> getDashboardStats(String token) async {
    final response = await _apiClient.get('/admin/dashboard', token: token);
    return AdminDashboardStats.fromJson(response['data']);
  }

  /// Fetches vendor list with optional status filter
  Future<List<VendorAdminModel>> getAllVendors(String token, {String? statusFilter}) async {
    String endpoint = '/admin/vendors';
    if (statusFilter != null && statusFilter.isNotEmpty && statusFilter != 'all') {
      endpoint += '?status=$statusFilter';
    }
    final response = await _apiClient.get(endpoint, token: token);
    final List list = response['data'] ?? [];
    return list.map((item) => VendorAdminModel.fromJson(item)).toList();
  }

  /// Approves a vendor registration
  Future<void> approveVendor(String token, int vendorId) async {
    await _apiClient.put('/admin/vendors/$vendorId/approve', {}, token: token);
  }

  /// Rejects a vendor registration
  Future<void> rejectVendor(String token, int vendorId) async {
    await _apiClient.put('/admin/vendors/$vendorId/reject', {}, token: token);
  }

  /// Fetches user list with optional role filter
  Future<List<UserAdminModel>> getAllUsers(String token, {String? roleFilter}) async {
    String endpoint = '/admin/users';
    if (roleFilter != null && roleFilter.isNotEmpty && roleFilter != 'all') {
      endpoint += '?role=$roleFilter';
    }
    final response = await _apiClient.get(endpoint, token: token);
    final List list = response['data'] ?? [];
    return list.map((item) => UserAdminModel.fromJson(item)).toList();
  }

  /// Blocks a user account
  Future<void> blockUser(String token, int userId) async {
    await _apiClient.put('/admin/users/$userId/block', {}, token: token);
  }

  /// Unblocks a user account
  Future<void> unblockUser(String token, int userId) async {
    await _apiClient.put('/admin/users/$userId/unblock', {}, token: token);
  }

  /// Fetches commissions for admin review with optional status filter
  Future<List<CommissionModel>> getAllCommissions(String token, {String? statusFilter}) async {
    String endpoint = '/admin/commissions';
    if (statusFilter != null && statusFilter.isNotEmpty && statusFilter != 'all') {
      endpoint += '?status=$statusFilter';
    }
    final response = await _apiClient.get(endpoint, token: token);
    final List list = response['data'] ?? [];
    return list.map((item) => CommissionModel.fromJson(item)).toList();
  }

  /// Approves and verifies a commission payment
  Future<void> verifyCommission(String token, int id) async {
    await _apiClient.put('/admin/commissions/$id/verify', {}, token: token);
  }

  /// Rejects a commission payment proof
  Future<void> rejectCommission(String token, int id) async {
    await _apiClient.put('/admin/commissions/$id/reject', {}, token: token);
  }

  /// Fetches reports for admin review with optional status filter
  Future<List<ReportModel>> getAllReports(String token, {String? statusFilter}) async {
    String endpoint = '/admin/reports';
    if (statusFilter != null && statusFilter.isNotEmpty && statusFilter != 'all') {
      endpoint += '?status=$statusFilter';
    }
    final response = await _apiClient.get(endpoint, token: token);
    final List list = response['data'] ?? [];
    return list.map((item) => ReportModel.fromJson(item)).toList();
  }

  /// Marks a report as resolved
  Future<void> resolveReport(String token, int id) async {
    await _apiClient.put('/admin/reports/$id/resolve', {}, token: token);
  }

  /// Marks a report as dismissed
  Future<void> dismissReport(String token, int id) async {
    await _apiClient.put('/admin/reports/$id/dismiss', {}, token: token);
  }

  /// Category Brands CRUD
  Future<List<CategoryModel>> getBrands() async {
    final response = await _apiClient.get('/categories/brands');
    final List list = response['data'] ?? [];
    return list.map((item) => CategoryModel.fromJson(item)).toList();
  }

  Future<void> addBrand(String token, String name) async {
    await _apiClient.post('/categories/brands', {'name': name}, token: token);
  }

  Future<void> updateBrand(String token, int id, String name) async {
    await _apiClient.put('/categories/brands/$id', {'name': name}, token: token);
  }

  Future<void> deleteBrand(String token, int id) async {
    await _apiClient.delete('/categories/brands/$id', token: token);
  }

  /// Category Part Types CRUD
  Future<List<CategoryModel>> getPartTypes() async {
    final response = await _apiClient.get('/categories/part-types');
    final List list = response['data'] ?? [];
    return list.map((item) => CategoryModel.fromJson(item)).toList();
  }

  Future<void> addPartType(String token, String name) async {
    await _apiClient.post('/categories/part-types', {'name': name}, token: token);
  }

  Future<void> updatePartType(String token, int id, String name) async {
    await _apiClient.put('/categories/part-types/$id', {'name': name}, token: token);
  }

  Future<void> deletePartType(String token, int id) async {
    await _apiClient.delete('/categories/part-types/$id', token: token);
  }
}