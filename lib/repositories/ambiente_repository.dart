import 'package:inventario_qr_app/core/network/api_client.dart';
import 'package:inventario_qr_app/core/constants/api_constants.dart';
import 'package:inventario_qr_app/models/ambiente_model.dart';
import 'package:inventario_qr_app/core/hive/hive_manager.dart';
import 'package:flutter/foundation.dart';

class AmbienteRepository {
  final ApiClient _apiClient = ApiClient();
  static const String _cacheKey = 'ambientes';

  Future<List<AmbienteModel>> getAmbientes() async {
    try {
      final response = await _apiClient.get(ApiConstants.ambientesEndpoint);
      
      List<AmbienteModel> ambientes = [];
      if (response is List) {
        ambientes = (response).map((json) => AmbienteModel.fromJson(json)).toList();
      }
      
      // Cachear
      await HiveManager.getActivosBox().put(_cacheKey,
        ambientes.map((a) => a.toJson()).toList());
      
      return ambientes;
    } catch (e) {
      // Devolver caché
      final cached = HiveManager.getActivosBox().get(_cacheKey);
      if (cached != null) {
        return (cached as List).map((json) => AmbienteModel.fromJson(Map<String, dynamic>.from(json))).toList();
      }
      return [];
    }
  }

  Future<AmbienteModel?> getAmbientePorId(String ambienteId) async {
    try {
      final response = await _apiClient.get(
        '${ApiConstants.ambientesEndpoint}?id=eq.$ambienteId',
      );
      
      if (response is List && (response).isNotEmpty) {
        return AmbienteModel.fromJson((response)[0]);
      }
      return null;
    } catch (e) {
      debugPrint('Error obteniendo ambiente: $e');
      return null;
    }
  }
}
