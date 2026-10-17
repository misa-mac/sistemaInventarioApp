import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:inventario_qr_app/core/theme/app_theme.dart';
import 'package:inventario_qr_app/viewmodel/activo_viewmodel.dart';
import 'package:inventario_qr_app/models/activo_model.dart';

class QrScanSimpleScreen extends StatefulWidget {
  const QrScanSimpleScreen({super.key});

  @override
  State<QrScanSimpleScreen> createState() => _QrScanSimpleScreenState();
}

class _QrScanSimpleScreenState extends State<QrScanSimpleScreen> {
  final MobileScannerController cameraController = MobileScannerController();
  bool _isProcessing = false;

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: AppColors.primaryNavy,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Escaneo Simple de Activo',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          ValueListenableBuilder<TorchState>(
            valueListenable: cameraController.torchState,
            builder: (context, state, child) {
              final isTorchOn = state == TorchState.on;
              return IconButton(
                icon: Icon(
                  isTorchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                  color: isTorchOn ? Colors.amberAccent : Colors.white,
                ),
                tooltip: 'Linterna',
                onPressed: () => cameraController.toggleTorch(),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: cameraController,
            onDetect: (capture) {
              final barcodes = capture.barcodes;
              if (!_isProcessing && barcodes.isNotEmpty) {
                _isProcessing = true;
                _procesarQr(barcodes.first.rawValue ?? '');
              }
            },
          ),

          // Marco de enfoque
          Align(
            alignment: Alignment.center,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white.withValues(alpha: 0.85), width: 2.5),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),

          // Instrucción inferior
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.black87,
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                16 + MediaQuery.of(context).padding.bottom,
              ),
              child: const Text(
                'Apunta la cámara al código QR del equipo',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _procesarQr(String datosQr) async {
    try {
      final activoVM = context.read<ActivoViewModel>();
      await activoVM.procesarEscaneoQr(datosQr);

      if (!mounted) return;

      if (activoVM.activoActual != null) {
        _mostrarFichaTecnica(context, activoVM.activoActual!);
      } else {
        _mostrarError('Activo no encontrado');
      }
    } catch (e) {
      if (!mounted) return;
      _mostrarError('Error procesando QR: $e');
    } finally {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          _isProcessing = false;
        }
      });
    }
  }

  void _mostrarFichaTecnica(BuildContext context, ActivoModel activo) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Ficha Técnica del Equipo',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    _buildEstadoChip(activo.estado),
                  ],
                ),
                const SizedBox(height: 12),

                // Código
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.brandBlue.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.qr_code_2_rounded, size: 16, color: AppColors.brandBlue),
                      const SizedBox(width: 6),
                      Text(
                        activo.qrCodigo.isNotEmpty ? activo.qrCodigo : activo.uuid,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.brandBlue,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Nombre
                Text(
                  activo.nombre,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 14),

                // Tabla técnica
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      _buildRow('Tipo', activo.tipo),
                      const Divider(height: 12, color: AppColors.border),
                      _buildRow('Marca', activo.marca),
                      const Divider(height: 12, color: AppColors.border),
                      _buildRow('Modelo', activo.modelo),
                      const Divider(height: 12, color: AppColors.border),
                      _buildRow('Serie', activo.numeroSerie),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Botón Escanear otro (52 dp)
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _isProcessing = false;
                      Navigator.pop(ctx);
                    },
                    icon: const Icon(Icons.qr_code_scanner_rounded, size: 20),
                    label: const Text(
                      'Escanear otro equipo',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryNavy,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEstadoChip(String estado) {
    Color bg = AppColors.statusGreenBg;
    Color textColor = AppColors.statusGreenText;
    IconData icon = Icons.check_circle_rounded;

    if (estado.toLowerCase().contains('manten') || estado.toLowerCase().contains('esperado')) {
      bg = AppColors.statusAmberBg;
      textColor = AppColors.statusAmberText;
      icon = Icons.warning_rounded;
    } else if (estado.toLowerCase().contains('baja') || estado.toLowerCase().contains('dañado')) {
      bg = AppColors.statusRedBg;
      textColor = AppColors.statusRedText;
      icon = Icons.cancel_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: textColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: textColor),
          const SizedBox(width: 4),
          Text(
            estado.toUpperCase(),
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value.isNotEmpty ? value : 'No especificado',
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  void _mostrarError(String mensaje) {
    _isProcessing = false;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: AppColors.statusRed,
      ),
    );
  }
}
