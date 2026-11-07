import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vibration/vibration.dart';
import 'package:inventario_qr_app/core/theme/app_theme.dart';
import 'package:inventario_qr_app/models/estacion_model.dart';
import 'package:inventario_qr_app/models/activo_model.dart';
import 'package:inventario_qr_app/repositories/estacion_repository.dart';
import 'package:inventario_qr_app/viewmodel/auditoria_viewmodel.dart';

class StationDetailScreen extends StatefulWidget {
  final String codigoEstacion;
  final EstacionModel? estacionInicial;

  const StationDetailScreen({
    super.key,
    required this.codigoEstacion,
    this.estacionInicial,
  });

  @override
  State<StationDetailScreen> createState() => _StationDetailScreenState();
}

class _StationDetailScreenState extends State<StationDetailScreen> {
  final EstacionRepository _repository = EstacionRepository();
  bool _isLoading = true;
  String? _error;
  EstacionModel? _estacion;
  bool _isAuditing = false;

  @override
  void initState() {
    super.initState();
    if (widget.estacionInicial != null) {
      _estacion = widget.estacionInicial;
      _isLoading = false;
    } else {
      _cargarEstacion();
    }
  }

  Future<void> _cargarEstacion() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final res = await _repository.getEstacionPorCodigo(widget.codigoEstacion);
      if (mounted) {
        setState(() {
          _estacion = res;
          _isLoading = false;
          if (res == null) {
            _error = 'No se encontró la estación con código ${widget.codigoEstacion}';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error cargando estación: $e';
          _isLoading = false;
        });
      }
    }
  }

  IconData _getComponentIcon(String nombre, String tipo) {
    final text = '$nombre $tipo'.toLowerCase();
    if (text.contains('cpu') || text.contains('gabinete') || text.contains('torre') || text.contains('computadora')) {
      return Icons.memory;
    }
    if (text.contains('monitor') || text.contains('pantalla')) {
      return Icons.desktop_windows;
    }
    if (text.contains('teclado') || text.contains('keyboard')) {
      return Icons.keyboard;
    }
    if (text.contains('mouse') || text.contains('raton')) {
      return Icons.mouse;
    }
    return Icons.devices;
  }

  Color _getStatusColor(String estado) {
    final e = estado.toLowerCase();
    if (e.contains('activo') || e.contains('presente')) return AppColors.statusGreenText;
    if (e.contains('dañado') || e.contains('danado') || e.contains('faltante')) return AppColors.statusRedText;
    return AppColors.statusAmberText;
  }

  Color _getStatusBg(String estado) {
    final e = estado.toLowerCase();
    if (e.contains('activo') || e.contains('presente')) return AppColors.statusGreenBg;
    if (e.contains('dañado') || e.contains('danado') || e.contains('faltante')) return AppColors.statusRedBg;
    return AppColors.statusAmberBg;
  }

  Future<void> _auditarEstacionCompleta() async {
    final auditoriaVM = context.read<AuditoriaViewModel>();
    if (auditoriaVM.auditoriaActual == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ No hay ninguna sesión de auditoría en progreso.'),
          backgroundColor: AppColors.statusAmberText,
        ),
      );
      return;
    }

    if (_estacion == null) return;

    setState(() => _isAuditing = true);
    try {
      final success = await auditoriaVM.registrarEstacionCompleta(_estacion!);
      if (success) {
        try {
          await Vibration.vibrate(duration: 80);
        } catch (_) {}

        if (mounted) {
          final count = _estacion!.componentes.length;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✓ Estación ${_estacion!.codigoEstacion} auditada exitosamente ($count componentes registrados)'),
              backgroundColor: AppColors.statusGreen,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error registrando auditoría de la estación'),
              backgroundColor: AppColors.statusRed,
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isAuditing = false);
    }
  }

  void _mostrarDetalleComponente(ActivoModel activo) {
    final auditoriaVM = context.read<AuditoriaViewModel>();
    final hayAuditoria = auditoriaVM.auditoriaActual != null;
    final yaAuditado = auditoriaVM.isActivoAuditado(activo.id);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primaryNavy.withValues(alpha: 0.1),
                  child: Icon(_getComponentIcon(activo.nombre, activo.tipo), color: AppColors.primaryNavy),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activo.nombre,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        'Código: ${activo.qrCodigo}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontFamily: 'monospace'),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusBg(activo.estado),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    activo.estado,
                    style: TextStyle(color: _getStatusColor(activo.estado), fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow('Marca / Modelo:', '${activo.marca.isNotEmpty ? activo.marca : 'N/A'} ${activo.modelo.isNotEmpty ? '• ${activo.modelo}' : ''}'),
            if (activo.numeroSerie.isNotEmpty) _buildInfoRow('N° Serie:', activo.numeroSerie),
            if (activo.descripcion != null && activo.descripcion!.isNotEmpty)
              _buildInfoRow('Descripción:', activo.descripcion!),
            const SizedBox(height: 16),
            if (hayAuditoria)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: yaAuditado ? null : () async {
                    Navigator.pop(ctx);
                    final ok = await auditoriaVM.registrarEscaneo(activo.id, 'presente', 'Auditoría individual');
                    if (ok && mounted) {
                      try { await Vibration.vibrate(duration: 50); } catch (_) {}
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('✓ ${activo.nombre} auditado'),
                          backgroundColor: AppColors.statusGreen,
                        ),
                      );
                    }
                  },
                  icon: Icon(yaAuditado ? Icons.check_circle : Icons.qr_code_scanner),
                  label: Text(yaAuditado ? 'Componente Ya Auditado' : 'Auditar Este Componente'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryNavy,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 12, color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.codigoEstacion,
          style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primaryNavy,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarEstacion,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: AppColors.statusRed),
                        const SizedBox(height: 12),
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _cargarEstacion,
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                )
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final estacion = _estacion!;
    final auditoriaVM = context.watch<AuditoriaViewModel>();
    final hayAuditoria = auditoriaVM.auditoriaActual != null;
    final comps = estacion.componentes;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Tarjeta Banner de la Estación (Mesa de Trabajo)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryNavy.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'QR GENERAL • ESTACIÓN',
                        style: TextStyle(
                          color: AppColors.primaryNavy,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: comps.length >= 4 ? AppColors.statusGreenBg : AppColors.statusAmberBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${comps.length}/4 Componentes',
                        style: TextStyle(
                          color: comps.length >= 4 ? AppColors.statusGreenText : AppColors.statusAmberText,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  estacion.codigoEstacion,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: AppColors.primaryNavy),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${estacion.ambienteNombre ?? 'Ambiente'} ${estacion.ambienteUbicacion != null ? '• ${estacion.ambienteUbicacion}' : ''}',
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
                if (estacion.descripcion != null && estacion.descripcion!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    estacion.descripcion!,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 2. Botón de Acción Principal: "Auditar Estación Completa"
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isAuditing ? null : _auditarEstacionCompleta,
              icon: _isAuditing
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.checklist_rounded),
              label: Text(
                hayAuditoria
                    ? 'Auditar Estación Completa (${comps.length} equipos)'
                    : 'Auditar Estación Completa (Sin sesión)',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.statusGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 1,
              ),
            ),
          ),

          const SizedBox(height: 24),

          // 3. Encabezado de Componentes
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Componentes de la Mesa',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '${comps.length} asignado(s)',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 4. Lista de 4 Componentes (CPU, Monitor, Teclado, Mouse)
          if (comps.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border, style: BorderStyle.solid),
              ),
              child: const Column(
                children: [
                  Icon(Icons.device_unknown, size: 40, color: Colors.grey),
                  SizedBox(height: 8),
                  Text(
                    'No hay componentes vinculados a esta mesa.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: comps.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final activo = comps[index];
                final yaAuditado = auditoriaVM.isActivoAuditado(activo.id);

                return Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: () => _mostrarDetalleComponente(activo),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: yaAuditado ? AppColors.statusGreen : AppColors.border,
                          width: yaAuditado ? 1.5 : 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: yaAuditado
                                ? AppColors.statusGreenBg
                                : AppColors.primaryNavy.withValues(alpha: 0.08),
                            child: Icon(
                              _getComponentIcon(activo.nombre, activo.tipo),
                              size: 20,
                              color: yaAuditado ? AppColors.statusGreenText : AppColors.primaryNavy,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        activo.nombre,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (yaAuditado)
                                      const Icon(Icons.check_circle, size: 16, color: AppColors.statusGreen),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${activo.qrCodigo} • ${activo.marca.isNotEmpty ? activo.marca : 'S/M'} ${activo.modelo.isNotEmpty ? activo.modelo : ''}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontFamily: 'monospace',
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _getStatusBg(activo.estado),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              activo.estado,
                              style: TextStyle(
                                color: _getStatusColor(activo.estado),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

