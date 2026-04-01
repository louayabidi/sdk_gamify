// Gère tous les appels HTTP vers le backend.
// Ce fichier est INTERNE au SDK, les app owners ne l'utilisent pas directement.

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'exceptions.dart';

class GamificationHttpClient {
  final String baseUrl;
  final String apiKey;
  final Duration timeout;
  final http.Client _inner;

  GamificationHttpClient({
    required this.baseUrl,
    required this.apiKey,
    this.timeout = const Duration(seconds: 15),  // le timeout est de 15 secondes par défaut, mais peut être personnalisé à l'initialisation du SDK
    http.Client? client,
  }) : _inner = client ?? http.Client();

  // Headers envoyés à chaque requête.
  // X-API-Key est la clé générée dans le dashboard Spring Boot.
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'X-API-Key': apiKey,
  };

  Future<dynamic> post(String path, Map<String, dynamic> body) async {
    final uri = _buildUri(path);
    try {
      final response = await _inner
          .post(uri, headers: _headers, body: jsonEncode(body))
          .timeout(timeout);
      return _parseResponse(response);
    } on GamificationApiException {
      rethrow;
    } catch (e) {
      throw GamificationNetworkException(
        message: 'Request failed: ${e.toString()}',
        cause: e,
      );
    }
  }

  Future<dynamic> get(String path) async {
    final uri = _buildUri(path);
    try {
      final response = await _inner
          .get(uri, headers: _headers)
          .timeout(timeout);
      return _parseResponse(response);
    } on GamificationApiException {
      rethrow;
    } catch (e) {
      throw GamificationNetworkException(
        message: 'Request failed: ${e.toString()}',
        cause: e,
      );
    }
  }

  Uri _buildUri(String path) {
    final cleanBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final cleanPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$cleanBase$cleanPath');
  }

  dynamic _parseResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      try {
        return jsonDecode(response.body);
      } catch (_) {
        return response.body;
      }
    }

    String errorMessage = 'HTTP ${response.statusCode}';
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map) {
        errorMessage = decoded['message'] as String? ??
            decoded['error'] as String? ??
            errorMessage;
      }
    } catch (_) {}

    throw GamificationApiException(
      statusCode: response.statusCode,
      message: errorMessage,
    );
  }

  void dispose() => _inner.close();
}