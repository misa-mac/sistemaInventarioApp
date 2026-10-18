import 'package:flutter/material.dart';
import 'package:inventario_qr_app/core/theme/app_theme.dart';

/// Widget unificado para estados de error y reintento en la app.
///
/// Cumple con las pautas de diseño:
/// - El botón "Reintentar" tiene ancho según su contenido (no ancho infinito).
/// - Altura táctil mínima de 48 dp y ancho máximo acotado (máx. 220 dp).
/// - Muestra la causa real del error (sin conexión, sin permisos, error del servidor).
class ErrorState extends StatelessWidget {
  final String? titulo;
  final String? mensaje;
  final dynamic error;
  final IconData? icon;
  final VoidCallback onRetry;
  final String retryLabel;
  final bool isLoading;

  const ErrorState({
    super.key,
    this.titulo,
    this.mensaje,
    this.error,
    this.icon,
    required this.onRetry,
    this.retryLabel = 'Reintentar',
    this.isLoading = false,
  });

  /// Determina el mensaje amigable y preciso según la causa real del error.
  static String resolverCausaError(dynamic err, {String fallback = 'Ocurrió un error al cargar los datos.'}) {
    if (err == null) return fallback;
    final str = err.toString().toLowerCase();

    if (str.contains('socketexception') ||
        str.contains('connection refused') ||
        str.contains('failed host lookup') ||
        str.contains('network') ||
        str.contains('sin conexión') ||
        str.contains('tiempo de espera') ||
        str.contains('timeout')) {
      return 'Sin conexión con el servidor. Verifica tu conexión a internet o red local.';
    }

    if (str.contains('403') ||
        str.contains('forbidden') ||
        str.contains('sin permisos') ||
        str.contains('no autorizado')) {
      return 'No cuentas con los permisos necesarios para realizar esta acción.';
    }

    if (str.contains('401') ||
        str.contains('unauthorized') ||
        str.contains('sesión expirada') ||
        str.contains('token')) {
      return 'Tu sesión ha expirado o no es válida. Inicia sesión nuevamente.';
    }

    if (str.contains('500') ||
        str.contains('502') ||
        str.contains('503') ||
        str.contains('server error') ||
        str.contains('error interno')) {
      return 'El servidor encontró un error interno al procesar la solicitud.';
    }

    if (str.contains('404') || str.contains('not found')) {
      return 'El recurso solicitado no fue encontrado en el sistema.';
    }

    if (err is String && err.isNotEmpty && !err.startsWith('Exception:')) {
      return err;
    }

    return fallback;
  }

  /// Retorna un ícono coherente con la causa del error.
  static IconData resolverIcono(dynamic err, IconData? customIcon) {
    if (customIcon != null) return customIcon;
    if (err == null) return Icons.error_outline_rounded;
    final str = err.toString().toLowerCase();

    if (str.contains('socketexception') ||
        str.contains('connection') ||
        str.contains('network') ||
        str.contains('sin conexión')) {
      return Icons.wifi_off_rounded;
    }

    if (str.contains('403') || str.contains('permiso')) {
      return Icons.gpp_bad_rounded;
    }

    return Icons.error_outline_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final mensajeFinal = mensaje ?? resolverCausaError(error);
    final iconoFinal = resolverIcono(error, icon);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primaryNavy.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(
                iconoFinal,
                size: 38,
                color: AppColors.primaryNavy.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 16),
            if (titulo != null && titulo!.isNotEmpty) ...[
              Text(
                titulo!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
            ],
            Text(
              mensajeFinal,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: AppColors.iconInactive,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: 48,
                maxWidth: 220,
              ),
              child: OutlinedButton.icon(
                onPressed: isLoading ? null : onRetry,
                icon: isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh_rounded, size: 20),
                label: Text(
                  retryLabel,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.brandBlue,
                  side: const BorderSide(color: AppColors.brandBlue, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
