import 'package:http/http.dart' as http;
import 'package:inventario_qr_app/core/constants/api_constants.dart';
import 'package:inventario_qr_app/core/storage/session_manager.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';

class ApiClient {
  static const Duration defaultTimeout = Duration(seconds: 4);

  String get _baseUrl => ApiConstants.baseUrl;

  Map<String, String> _getHeaders() {
    final token = SessionManager.getToken();
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'X-Client': 'mobile',
    };
    if (token != null && token.toString().isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Uri _buildUri(String endpoint) {
    // Si ya viene con http o https completo
    if (endpoint.startsWith('http://') || endpoint.startsWith('https://')) {
      return Uri.parse(endpoint);
    }
    
    // Normalizar si trae parámetros estilo Supabase eq. y transformarlos si es necesario
    String cleanEndpoint = endpoint;
    if (cleanEndpoint.contains('=eq.')) {
      cleanEndpoint = cleanEndpoint.replaceAll('=eq.', '=');
    }
    
    return Uri.parse('$_baseUrl$cleanEndpoint');
  }

  Future<dynamic> get(String endpoint) async {
    final url = _buildUri(endpoint);
    debugPrint('🌐 GET: $url');
    final response = await http.get(url, headers: _getHeaders()).timeout(
      defaultTimeout,
      onTimeout: () => throw Exception('Tiempo de espera agotado al conectar con el servidor ($url).'),
    );
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return [];
      return jsonDecode(response.body);
    } else {
      debugPrint('❌ Error HTTP ${response.statusCode}: ${response.body}');
      throw Exception('Error: ${response.statusCode} - ${response.body}');
    }
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    final url = _buildUri(endpoint);
    
    debugPrint('📤 POST a: $url');
    debugPrint('📦 Body: $body');
    
    final response = await http.post(
      url,
      headers: _getHeaders(),
      body: jsonEncode(body),
    ).timeout(
      defaultTimeout,
      onTimeout: () => throw Exception('Tiempo de espera agotado al conectar con el servidor ($url).'),
    );

    debugPrint('📥 Status: ${response.statusCode}');
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return {};
      }
      return jsonDecode(response.body);
    } else {
      debugPrint('❌ Error HTTP ${response.statusCode}: ${response.body}');
      throw Exception('Error: ${response.statusCode} - ${response.body}');
    }
  }

  Future<dynamic> put(String endpoint, Map<String, dynamic> body) async {
    final url = _buildUri(endpoint);
    
    debugPrint('🔄 PUT a: $url');
    debugPrint('📦 Body: $body');
    
    final response = await http.put(
      url,
      headers: _getHeaders(),
      body: jsonEncode(body),
    ).timeout(
      defaultTimeout,
      onTimeout: () => throw Exception('Tiempo de espera agotado al conectar con el servidor ($url).'),
    );

    debugPrint('📥 Status: ${response.statusCode}');
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return {};
      }
      return jsonDecode(response.body);
    } else {
      debugPrint('❌ Error HTTP ${response.statusCode}: ${response.body}');
      throw Exception('Error: ${response.statusCode} - ${response.body}');
    }
  }

  Future<dynamic> patch(String endpoint, Map<String, dynamic> body) async {
    final url = _buildUri(endpoint);
    
    debugPrint('🔧 PATCH a: $url');
    debugPrint('📦 Body: $body');
    
    final response = await http.patch(
      url,
      headers: _getHeaders(),
      body: jsonEncode(body),
    ).timeout(
      defaultTimeout,
      onTimeout: () => throw Exception('Tiempo de espera agotado al conectar con el servidor ($url).'),
    );

    debugPrint('📥 Status: ${response.statusCode}');
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return {};
      }
      return jsonDecode(response.body);
    } else {
      debugPrint('❌ Error HTTP ${response.statusCode}: ${response.body}');
      throw Exception('Error: ${response.statusCode} - ${response.body}');
    }
  }

  Future<dynamic> delete(String endpoint) async {
    final url = _buildUri(endpoint);
    
    debugPrint('🗑️ DELETE a: $url');
    
    final response = await http.delete(url, headers: _getHeaders()).timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw Exception('Tiempo de espera agotado al conectar con el servidor ($url).'),
    );

    debugPrint('📥 Status: ${response.statusCode}');
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return {};
      }
      return jsonDecode(response.body);
    } else {
      debugPrint('❌ Error HTTP ${response.statusCode}: ${response.body}');
      throw Exception('Error: ${response.statusCode} - ${response.body}');
    }
  }
}
