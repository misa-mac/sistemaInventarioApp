import 'package:flutter/foundation.dart';
import 'package:inventario_qr_app/core/network/api_client.dart';
import 'package:inventario_qr_app/core/database/local_database.dart';
import 'package:inventario_qr_app/models/tipo_activo_model.dart';

class TipoActivoRepository {
  final ApiClient _apiClient;
  final LocalDatabase _localDb;

  TipoActivoRepository({
    ApiClient? apiClient,
    LocalDatabase? localDb,
  })  : _apiClient = apiClient ?? ApiClient(),
        _localDb = localDb ?? LocalDatabase.instance;

  // Catálogo base oficial de 02_catalogos.sql como garantía offline
  static final List<TipoActivoModel> catalogoOficial = [
    TipoActivoModel(id: '122e1fb5-9ad8-46c0-afaa-b52c496d7eb7', codigo: 10, nombre: 'CPU/Computadora', descripcion: 'Unidad central de procesamiento'),
    TipoActivoModel(id: 'bdfb882b-a889-4502-96c5-9ee935bae1fa', codigo: 20, nombre: 'RAK', descripcion: 'Estructura servidores'),
    TipoActivoModel(id: 'daed2b54-2e0b-4936-8c42-9327a0e19591', codigo: 30, nombre: 'Estabilizador', descripcion: 'Dispositivo regulación energía'),
    TipoActivoModel(id: '59c82de7-53d5-4d7c-a076-3fbc21d9efc4', codigo: 40, nombre: 'Router', descripcion: 'Dispositivo red'),
    TipoActivoModel(id: 'f19846ef-1828-4c4f-bc8b-ebfbeb967b76', codigo: 45, nombre: 'Switch', descripcion: 'Dispositivo red conmutación'),
    TipoActivoModel(id: '635b8532-9e5c-43b5-839d-eff0c0f46e28', codigo: 50, nombre: 'Teclado', descripcion: 'Periférico de entrada'),
    TipoActivoModel(id: 'd93cf193-1bd1-4a6e-a1f1-6c563f3ab28a', codigo: 60, nombre: 'Mouse', descripcion: 'Periférico de entrada'),
    TipoActivoModel(id: '0655beda-b766-4ab1-844d-37087b69eec6', codigo: 80, nombre: 'Pantalla/Monitor', descripcion: 'Monitor display'),
    TipoActivoModel(id: '6e53438a-5290-49d7-8c2b-0e0e6a36a32b', codigo: 90, nombre: 'Mesa', descripcion: 'Mobiliario escritorio'),
    TipoActivoModel(id: 'a6bc710b-3bd0-4595-8c18-6ea4abd4a82c', codigo: 95, nombre: 'Silla', descripcion: 'Mobiliario asiento'),
  ];

  Future<List<TipoActivoModel>> getTiposActivos() async {
    // 1. Intentar cargar desde la API del backend
    try {
      final res = await _apiClient.get('/tipos-activos');
      if (res is List && res.isNotEmpty) {
        final list = res.map((j) => TipoActivoModel.fromJson(j as Map<String, dynamic>)).toList();
        await _localDb.guardarTiposActivos(list);
        return list;
      }
    } catch (e) {
      debugPrint('⚠️ [TipoActivoRepository] Falló llamada a /tipos-activos: $e. Consultando caché local SQLite.');
    }

    // 2. Fallback a caché local SQLite
    try {
      final localRows = await _localDb.getTiposActivosCache();
      if (localRows.isNotEmpty) {
        return localRows.map((r) => TipoActivoModel.fromJson(r)).toList();
      }
    } catch (e) {
      debugPrint('⚠️ [TipoActivoRepository] Error leyendo caché SQLite: $e');
    }

    // 3. Fallback a catálogo oficial semilla (garantía de disponibilidad inmediata)
    // También lo persistimos en SQLite para futuros accesos offline
    try {
      await _localDb.guardarTiposActivos(catalogoOficial);
    } catch (_) {}

    return catalogoOficial;
  }
}
