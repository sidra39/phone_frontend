import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';

/// ApiClient
/// A clean wrapper around the http package to handle API requests.
/// Performs simple JSON encoding/decoding, token authorization, and basic status code checks.
class ApiClient {
  final http.Client _client;

  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  /// Constructs a full Uri from the endpoint and baseUrl
  Uri _buildUri(String endpoint) {
    if (endpoint.startsWith('http://') || endpoint.startsWith('https://')) {
      return Uri.parse(endpoint);
    }
    final String formattedPath = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    return Uri.parse('${ApiConstants.baseUrl}$formattedPath');
  }

  /// Builds headers, including Authorization Bearer token if provided
  Map<String, String> _buildHeaders(String? token) {
    final Map<String, String> headers = {'Content-Type': 'application/json'};
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  /// Processes the response, returning decoded JSON on success (2xx)
  /// and throwing an Exception with the server's error message on failure.
  dynamic _handleResponse(http.Response response) {
    final int statusCode = response.statusCode;
    final String body = response.body;

    if (statusCode >= 200 && statusCode < 300) {
      if (body.isEmpty) return null;
      return jsonDecode(body);
    } else {
      String errorMessage = 'Request failed with status: $statusCode';
      try {
        final decoded = jsonDecode(body);
        if (decoded is Map && decoded.containsKey('message')) {
          errorMessage = decoded['message'];
        }
      } catch (_) {
        if (body.isNotEmpty) {
          errorMessage = body;
        }
      }
      throw Exception(errorMessage);
    }
  }

  /// GET request
  Future<dynamic> get(String endpoint, {String? token}) async {
    try {
      final response = await _client.get(
        _buildUri(endpoint),
        headers: _buildHeaders(token),
      );
      return _handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  /// POST request
  Future<dynamic> post(String endpoint, Map body, {String? token}) async {
    try {
      final response = await _client.post(
        _buildUri(endpoint),
        headers: _buildHeaders(token),
        body: jsonEncode(body),
      );
      return _handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  /// PUT request
  Future<dynamic> put(String endpoint, Map body, {String? token}) async {
    try {
      final response = await _client.put(
        _buildUri(endpoint),
        headers: _buildHeaders(token),
        body: jsonEncode(body),
      );
      return _handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  /// DELETE request
  Future<dynamic> delete(String endpoint, {String? token}) async {
    try {
      final response = await _client.delete(
        _buildUri(endpoint),
        headers: _buildHeaders(token),
      );
      return _handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }
}
