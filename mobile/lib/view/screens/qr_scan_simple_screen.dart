import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:inventario_qr_app/core/theme/app_theme.dart';
import 'package:inventario_qr_app/core/constants/api_constants.dart';
import 'package:inventario_qr_app/core/utils/app_routes.dart';
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

          // Marco de enfoque visual
          Align(
            alignment: Alignment.center,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white.withValues(alpha: 0.9), width: 2.5),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 16,
                  ),
                ],
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
                'Apunta la cámara al código QR oficial del equipo',
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
    final cleanCode = datosQr.trim();
    if (cleanCode.isEmpty) return;

    // Enrutamiento Híbrido: Si empieza con EST-, navegar a StationDetailScreen
    if (cleanCode.toUpperCase().startsWith('EST-')) {
      if (!mounted) return;
      await Navigator.pushNamed(
        context,
        AppRoutes.stationDetail,
        arguments: cleanCode.toUpperCase(),
      );
      if (mounted) {
        setState(() => _isProcessing = false);
      }
      return;
    }

    try {
      final activoVM = context.read<ActivoViewModel>();
      await activoVM.procesarEscaneoQr(cleanCode);

      if (!mounted) return;

      if (activoVM.activoActual != null) {
        _mostrarFichaTecnica(context, activoVM.activoActual!);
      } else {
        _mostrarError('Activo no encontrado con el código escaneado: $cleanCode');
      }
    } catch (e) {
      if (!mounted) return;
      _mostrarError('Error procesando código QR: $e');
    } finally {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted && !_isModalOpen) {
          _isProcessing = false;
        }
      });
    }
  }

  bool _isModalOpen = false;

  String? _resolveImageUrl(String? url) {
    if (url == null || url.trim().isEmpty) return null;
    final trimmed = url.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    final base = ApiConstants.baseUrl.replaceAll('/api', '');
    final cleanPath = trimmed.startsWith('/') ? trimmed : '/$trimmed';
    return '$base$cleanPath';
  }

  void _mostrarFichaTecnica(BuildContext context, ActivoModel activo) {
    _isModalOpen = true;
    final imageUrl = _resolveImageUrl(activo.imagenUrl);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SafeArea(
          child: Column(
            children: [
              // 1. Barra de arrastre superior
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),

              // 2. Encabezado fijo con título y chip de estado (sin riesgo de overflow)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 12, 12),
                child: Row(
                  children: [
                    const Icon(Icons.inventory_2_rounded, color: AppColors.brandBlue, size: 22),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Ficha Técnica del Activo',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildEstadoChip(activo.estado),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 22, color: AppColors.iconInactive),
                      onPressed: () => Navigator.pop(ctx),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Cerrar',
                    ),
                  ],
                ),
              ),

              const Divider(height: 1, color: AppColors.border),

              // 3. Contenido scrolleable completo
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  children: [
                    // Foto del equipo (si tiene imagen registrada)
                    if (imageUrl != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          height: 180,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: Colors.grey[100],
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.broken_image_rounded, size: 40, color: AppColors.iconInactive),
                                  SizedBox(height: 6),
                                  Text(
                                    'Imagen no disponible',
                                    style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AppColors.iconInactive),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Banner de Identificación Principal
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primaryNavy.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.primaryNavy.withValues(alpha: 0.12)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Nombre principal
                          Text(
                            activo.nombre,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Código Oficial QR y Tipo
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: AppColors.brandBlue.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.brandBlue.withValues(alpha: 0.25)),
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
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.brandBlue,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (activo.numeroCorrelativo != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Nº #${activo.numeroCorrelativo.toString().padLeft(2, '0')}',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                ),
                              if (activo.tipo.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.blueGrey[50],
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.blueGrey[200]!),
                                  ),
                                  child: Text(
                                    activo.tipo,
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.blueGrey[800],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // SECCIÓN 1: Ubicación & Entorno
                    _buildSectionCard(
                      title: 'Ubicación e Infraestructura',
                      icon: Icons.location_on_rounded,
                      iconColor: Colors.deepOrange,
                      children: [
                        _buildRow('Ambiente Actual', activo.ambienteNombre ?? 'Ambiente no asignado', isHighlight: true),
                        if (activo.ambienteUbicacion != null && activo.ambienteUbicacion!.isNotEmpty) ...[
                          const Divider(height: 16, color: AppColors.border),
                          _buildRow('Ubicación Física', activo.ambienteUbicacion!),
                        ],
                        if (activo.ambienteRegistroNombre != null && activo.ambienteRegistroNombre!.isNotEmpty) ...[
                          const Divider(height: 16, color: AppColors.border),
                          _buildRow('Ambiente de Registro', activo.ambienteRegistroNombre!),
                        ],
                      ],
                    ),

                    const SizedBox(height: 14),

                    // SECCIÓN 2: Especificaciones de Hardware
                    _buildSectionCard(
                      title: 'Especificaciones Técnicas',
                      icon: Icons.devices_rounded,
                      iconColor: AppColors.brandBlue,
                      children: [
                        _buildRow('Marca', activo.marca),
                        const Divider(height: 16, color: AppColors.border),
                        _buildRow('Modelo', activo.modelo),
                        const Divider(height: 16, color: AppColors.border),
                        _buildRow('Número de Serie', activo.numeroSerie, isMonospace: true),
                        if (activo.descripcion != null && activo.descripcion!.isNotEmpty) ...[
                          const Divider(height: 16, color: AppColors.border),
                          _buildRow('Descripción', activo.descripcion!),
                        ],
                      ],
                    ),

                    const SizedBox(height: 14),

                    // SECCIÓN 3: Datos Patrimoniales & Administrativos
                    _buildSectionCard(
                      title: 'Control Patrimonial y Administrativo',
                      icon: Icons.admin_panel_settings_rounded,
                      iconColor: Colors.teal,
                      children: [
                        _buildRow('Responsable / Custodio', activo.responsable ?? 'No asignado'),
                        const Divider(height: 16, color: AppColors.border),
                        _buildRow(
                          'Origen de Adquisición',
                          activo.especificacionOrigen != null && activo.especificacionOrigen!.isNotEmpty
                              ? '${activo.origen ?? "Origen"} (${activo.especificacionOrigen})'
                              : (activo.origen ?? 'No especificado'),
                        ),
                        if (activo.fechaIngreso != null && activo.fechaIngreso!.isNotEmpty) ...[
                          const Divider(height: 16, color: AppColors.border),
                          _buildRow('Fecha de Ingreso', activo.fechaIngreso!),
                        ],
                        if (activo.valor != null) ...[
                          const Divider(height: 16, color: AppColors.border),
                          _buildRow('Valor Estimado', 'Bs. ${activo.valor!.toStringAsFixed(2)}', isHighlight: true),
                        ],
                      ],
                    ),

                    // SECCIÓN 4: Observaciones (si cuenta con ellas)
                    if (activo.observaciones != null && activo.observaciones!.trim().isNotEmpty) ...[
                      const SizedBox(height: 14),
                      _buildSectionCard(
                        title: 'Observaciones / Notas',
                        icon: Icons.notes_rounded,
                        iconColor: Colors.amber[800]!,
                        children: [
                          Text(
                            activo.observaciones!.trim(),
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              color: AppColors.textPrimary,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 14),

                    // SECCIÓN 5: Trazabilidad Técnica
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.fingerprint_rounded, size: 18, color: Colors.grey[600]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'ID Sistema: ${activo.id}',
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 11,
                                color: Colors.grey[700],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),

              // 4. Botón inferior fijo para escanear otro equipo
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _isModalOpen = false;
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
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).whenComplete(() {
      _isModalOpen = false;
      _isProcessing = false;
    });
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildEstadoChip(String estado) {
    Color bg = AppColors.statusGreenBg;
    Color textColor = AppColors.statusGreenText;
    IconData icon = Icons.check_circle_rounded;

    final lower = estado.toLowerCase();
    if (lower.contains('manten') || lower.contains('esperado')) {
      bg = AppColors.statusAmberBg;
      textColor = AppColors.statusAmberText;
      icon = Icons.warning_rounded;
    } else if (lower.contains('baja') || lower.contains('dañado') || lower.contains('inactivo')) {
      bg = AppColors.statusRedBg;
      textColor = AppColors.statusRedText;
      icon = Icons.cancel_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: textColor.withValues(alpha: 0.25)),
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
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isHighlight = false, bool isMonospace = false}) {
    final displayValue = value.trim().isNotEmpty ? value.trim() : 'No especificado';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            displayValue,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontFamily: isMonospace ? 'monospace' : 'Poppins',
              fontSize: isMonospace ? 12 : 13,
              color: isHighlight ? AppColors.brandBlue : AppColors.textPrimary,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
            ),
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
