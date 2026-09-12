import 'package:http/http.dart' as http;
import 'package:inventario_qr_app/core/constants/api_constants.dart';
import 'dart:convert';

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

  Future<Map<String, dynamic>> get(String endpoint) async {
    final url = Uri.parse('$_supabaseUrl$endpoint');
    final response = await http.get(url, headers: _getHeaders());
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse('$_supabaseUrl$endpoint');
    final response = await http.post(
      url,
      headers: _getHeaders(),
      body: jsonEncode(body),
    );
    
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error: ${response.statusCode}');
    }
  }
}
