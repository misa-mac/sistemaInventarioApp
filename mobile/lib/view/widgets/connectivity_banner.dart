import 'package:flutter/material.dart';
import 'package:inventario_qr_app/core/theme/app_theme.dart';
import 'package:inventario_qr_app/core/services/network_connectivity_service.dart';

/// Banner global que muestra el estado de conexión:
/// "Sin conexión · N pendientes" o el indicador de sincronización.
class ConnectivityBanner extends StatelessWidget {
  const ConnectivityBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: NetworkConnectivityService(),
      builder: (context, _) {
        final service = NetworkConnectivityService();
        final isConnected = service.isConnected;
        final isSyncing = service.isSyncing;
        final pendingCount = service.pendingCount;

        if (isConnected && !isSyncing) {
          return const SizedBox.shrink();
        }

        final isOffline = !isConnected;
        final bgColor = isOffline ? AppColors.statusAmberBg : AppColors.statusGreenBg;
        final textColor = isOffline ? AppColors.statusAmberText : AppColors.statusGreenText;
        final borderColor = (isOffline ? AppColors.statusAmber : AppColors.statusGreen)
            .withValues(alpha: 0.35);

        return Container(
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
              Icon(
                isOffline ? Icons.wifi_off_rounded : Icons.sync_rounded,
                size: 16,
                color: textColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isOffline
                      ? 'Sin conexión · ${pendingCount > 0 ? "$pendingCount pendientes" : "Modo offline"}'
                      : 'Sincronizando cambios...',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ),
              if (isSyncing)
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(textColor),
                  ),
                )
              else
                IconButton(
                  icon: Icon(Icons.refresh_rounded, size: 16, color: textColor),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Comprobar conexión',
                  onPressed: () => service.checkConnection(),
                ),
            ],
          ),
        );
      },
    );
  }
}
