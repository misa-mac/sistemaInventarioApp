import 'package:http/http.dart' as http;
import 'package:inventario_qr_app/core/constants/api_constants.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';

class ApiClient {
  final String _supabaseUrl = ApiConstants.supabaseUrl;
  final String _anonKey = ApiConstants.supabaseAnonKey;

  Map<String, String> _getHeaders() {
    return {
      'Content-Type': 'application/json',
      'apikey': _anonKey,
      'Authorization': 'Bearer $_anonKey',
    };
  }

  Future<dynamic> get(String endpoint) async {
    final url = Uri.parse('$_supabaseUrl$endpoint');
    final response = await http.get(url, headers: _getHeaders());
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error: ${response.statusCode} - ${response.body}');
    }
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse('$_supabaseUrl$endpoint');
    
    debugPrint('📤 POST a: $url');
    debugPrint('📦 Body: $body');
    
    final response = await http.post(
      url,
      headers: _getHeaders(),
      body: jsonEncode(body),
    );

    debugPrint('📥 Status: ${response.statusCode}');
    debugPrint('📥 Response: ${response.body}');
    
    if (response.statusCode == 200 || response.statusCode == 201) {
      if (response.body.isEmpty) {
        debugPrint('⚠️ Respuesta vacía');
        return {};
      }
      return jsonDecode(response.body);
    } else {
      throw Exception('Error: ${response.statusCode} - ${response.body}');
    }
  }

  Future<dynamic> patch(String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse('$_supabaseUrl$endpoint');
    
    debugPrint('🔧 PATCH a: $url');
    debugPrint('📦 Body: $body');
    
    final response = await http.patch(
      url,
      headers: _getHeaders(),
      body: jsonEncode(body),
    );

    debugPrint('📥 Status: ${response.statusCode}');
    debugPrint('📥 Response: ${response.body}');
    
    if (response.statusCode == 200 || response.statusCode == 204) {
      if (response.body.isEmpty) {
        return {};
      }
      return jsonDecode(response.body);
    } else {
      throw Exception('Error: ${response.statusCode} - ${response.body}');
    }
  }

  Future<dynamic> delete(String endpoint) async {
    final url = Uri.parse('$_supabaseUrl$endpoint');
    
    debugPrint('🗑️ DELETE a: $url');
    
    final response = await http.delete(url, headers: _getHeaders());

    debugPrint('📥 Status: ${response.statusCode}');
    
    if (response.statusCode == 200 || response.statusCode == 204) {
      if (response.body.isEmpty) {
        return {};
      }
      return jsonDecode(response.body);
    } else {
      throw Exception('Error: ${response.statusCode} - ${response.body}');
    }
  }
}
