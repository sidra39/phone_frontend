import '../../../core/network/api_client.dart';
import '../models/report_model.dart';

/// ReportService
/// Handles HTTP communications for report & complaint endpoints.
class ReportService {
  final ApiClient _apiClient;

  ReportService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// Submits a new complaint report
  Future<ReportModel> submitReport(
    String token, {
    required int reportedUserId,
    int? requestId,
    required String reason,
    required String description,
  }) async {
    final body = {
      'reported_user_id': reportedUserId,
      ...?requestId != null ? {'request_id': requestId} : null,
      'reason': reason,
      'description': description,
    };

    final response = await _apiClient.post('/reports', body, token: token);
    return ReportModel.fromJson(response['data']);
  }

  /// Fetches reports submitted by the logged-in user
  Future<List<ReportModel>> getMyReports(String token) async {
    final response = await _apiClient.get('/reports/my', token: token);
    final List list = response['data'] ?? [];
    return list.map((item) => ReportModel.fromJson(item)).toList();
  }
}