import 'package:flutter/material.dart';
import 'package:inventario_qr_app/core/theme/app_theme.dart';
import 'package:inventario_qr_app/core/services/network_connectivity_service.dart';

/// Banner global que muestra el estado de conexión e informa al usuario:
/// 1. "Sin conexión · Modo offline / N pendientes" (Ámbar) mientras esté sin internet.
/// 2. "Conexión restablecida · Actualizando datos..." (Azul con spinner de progreso) cuando vuelve el internet.
/// 3. "¡Actualización completada!" (Verde con ícono de verificación) al terminar la sincronización.
/// Y finalmente desaparece suavemente tras completarse.
class ConnectivityBanner extends StatelessWidget {
  const ConnectivityBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: NetworkConnectivityService(),
      builder: (context, _) {
        final service = NetworkConnectivityService();
        final status = service.bannerStatus;
        final pendingCount = service.pendingCount;

        return AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(opacity: animation, child: child);
            },
            child: _buildBannerContent(context, service, status, pendingCount),
          ),
        );
      },
    );
  }

  Widget _buildBannerContent(
    BuildContext context,
    NetworkConnectivityService service,
    ConnectivityBannerStatus status,
    int pendingCount,
  ) {
    if (status == ConnectivityBannerStatus.hidden) {
      return const SizedBox(
        key: ValueKey('banner_hidden'),
        width: double.infinity,
        height: 0,
      );
    }

    final Color bgColor;
    final Color textColor;
    final Color borderColor;
    final IconData? iconData;
    final String labelText;
    final Widget? trailingWidget;

    switch (status) {
      case ConnectivityBannerStatus.offline:
        bgColor = AppColors.statusAmberBg;
        textColor = AppColors.statusAmberText;
        borderColor = AppColors.statusAmber.withValues(alpha: 0.35);
        iconData = Icons.wifi_off_rounded;
        labelText = pendingCount > 0
            ? 'Sin conexión · $pendingCount pendientes'
            : 'Sin conexión · Modo offline';
        trailingWidget = IconButton(
          key: const Key('btn_comprobar_conexion'),
          icon: Icon(Icons.refresh_rounded, size: 16, color: textColor),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          tooltip: 'Comprobar conexión',
          onPressed: () => service.checkConnection(),
        );
        break;

      case ConnectivityBannerStatus.updating:
        bgColor = const Color(0xFFE0F2FE); // Azul suave
        textColor = const Color(0xFF0369A1); // Azul profundo
        borderColor = const Color(0xFF0284C7).withValues(alpha: 0.35);
        iconData = null; // Indicador de carga animado
        labelText = service.statusMessage ?? 'Conexión restablecida · Actualizando datos...';
        trailingWidget = null;
        break;

      case ConnectivityBannerStatus.completed:
        bgColor = AppColors.statusGreenBg;
        textColor = AppColors.statusGreenText;
        borderColor = AppColors.statusGreen.withValues(alpha: 0.35);
        iconData = Icons.check_circle_rounded;
        labelText = service.statusMessage ?? '¡Actualización completada!';
        trailingWidget = null;
        break;

      case ConnectivityBannerStatus.hidden:
        return const SizedBox(
          key: ValueKey('banner_hidden'),
          width: double.infinity,
          height: 0,
        );
    }

    return Container(
      key: ValueKey('banner_$status'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          bottom: BorderSide(color: borderColor, width: 1),
        ),
      ),
      child: Row(
        children: [
          if (iconData != null)
            Icon(
              iconData,
              size: 16,
              color: textColor,
            )
          else
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(textColor),
              ),
            ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              labelText,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
          if (trailingWidget != null) trailingWidget,
        ],
      ),
    );
  }
}
