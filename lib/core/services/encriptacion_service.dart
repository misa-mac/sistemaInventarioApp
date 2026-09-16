import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';

class EncriptacionService {
  // Generar hash de contraseña con salt
  static String hashPassword(String password) {
    final salt = _generarSalt();
    final hash = sha256.convert(utf8.encode(salt + password)).toString();
    return '$salt:$hash';
  }

  // Verificar contraseña
  static bool verificarPassword(String passwordIngresada, String hashAlmacenado) {
    try {
      final partes = hashAlmacenado.split(':');
      if (partes.length != 2) return false;

      final salt = partes[0];
      final hashAlmacenado2 = partes[1];

      final hashIngresado = sha256.convert(utf8.encode(salt + passwordIngresada)).toString();

      return hashIngresado == hashAlmacenado2;
    } catch (e) {
      debugPrint('Error verificando contraseña: $e');
      return false;
    }
  }

  // Generar salt aleatorio
  static String _generarSalt() {
    final random = DateTime.now().millisecondsSinceEpoch.toString();
    return sha256.convert(utf8.encode(random)).toString().substring(0, 16);
  }

  // Validar fortaleza de contraseña
  static bool esContrasenaFuerte(String password) {
    if (password.length < 8) return false;
    if (!password.contains(RegExp(r'[A-Z]'))) return false;
    if (!password.contains(RegExp(r'[a-z]'))) return false;
    if (!password.contains(RegExp(r'[0-9]'))) return false;
    return true;
  }
}
