import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:inventario_qr_app/models/usuario_model.dart';

/// Gestor de sesión aislado de SQLite.
///
/// Cumple con la directriz arquitectónica: los tokens JWT y preferencias
/// de autenticación NO se almacenan en tablas SQLite.
///
/// Mantiene una caché en memoria para accesos sincrónicos ultra-rápidos
/// (usados en cabeceras HTTP de ApiClient y verificaciones de sesión)
/// y persiste de forma asíncrona en un archivo privado de la aplicación.
class SessionManager {
  static const String _fileName = 'session.json';

  static String? _cachedToken;
  static UsuarioModel? _cachedUsuario;
  static bool _initialized = false;

  /// Inicializa la sesión cargando los datos guardados en memoria.
  static Future<void> init() async {
    if (_initialized) return;

    try {
      final file = await _getSessionFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        if (content.isNotEmpty) {
          final data = jsonDecode(content) as Map<String, dynamic>;
          _cachedToken = data['token'] as String?;
          if (data['usuario'] != null) {
            _cachedUsuario = UsuarioModel.fromJson(
              Map<String, dynamic>.from(data['usuario'] as Map),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('⚠️ [SessionManager] Error cargando sesión local: $e');
    } finally {
      _initialized = true;
    }
  }

  static String? getToken() => _cachedToken;

  static UsuarioModel? getUsuario() => _cachedUsuario;

  static bool isLoggedIn() {
    return _cachedToken != null &&
        _cachedToken!.isNotEmpty &&
        _cachedUsuario != null;
  }

  /// Guarda token y usuario en memoria y los persiste en disco.
  static Future<void> saveSession(String token, UsuarioModel usuario) async {
    _cachedToken = token;
    _cachedUsuario = usuario;
    _initialized = true;

    try {
      final file = await _getSessionFile();
      final payload = {
        'token': token,
        'usuario': usuario.toJson(),
      };
      await file.writeAsString(jsonEncode(payload));
    } catch (e) {
      debugPrint('⚠️ [SessionManager] Error persistiendo sesión: $e');
    }
  }

  /// Elimina la sesión tanto en memoria como en disco.
  static Future<void> clearSession() async {
    _cachedToken = null;
    _cachedUsuario = null;

    try {
      final file = await _getSessionFile();
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('⚠️ [SessionManager] Error eliminando archivo de sesión: $e');
    }
  }

  static Future<File> _getSessionFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  /// Permite inyectar valores en tests unitarios.
  @visibleForTesting
  static void setMockSession({String? token, UsuarioModel? usuario}) {
    _cachedToken = token;
    _cachedUsuario = usuario;
    _initialized = true;
  }
}
