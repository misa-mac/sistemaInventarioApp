import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:inventario_qr_app/core/theme/app_theme.dart';
import 'package:inventario_qr_app/core/services/permisos_service.dart';
import 'package:inventario_qr_app/core/utils/app_routes.dart';
import 'package:inventario_qr_app/models/activo_model.dart';
import 'package:inventario_qr_app/repositories/activo_repository.dart';
import 'package:inventario_qr_app/viewmodel/activo_viewmodel.dart';
import 'package:inventario_qr_app/viewmodel/ambiente_viewmodel.dart';
import 'package:inventario_qr_app/viewmodel/auth_viewmodel.dart';

class ActivosDetalleScreen extends StatefulWidget {
  const ActivosDetalleScreen({super.key});

  @override
  State<ActivosDetalleScreen> createState() => _ActivosDetalleScreenState();
}

class _ActivosDetalleScreenState extends State<ActivosDetalleScreen> {
  final ActivoRepository _activoRepository = ActivoRepository();

  void _editarActivo(ActivoModel activo) async {
    final resultado = await Navigator.pushNamed(
      context,
      AppRoutes.formularioEquipo,
      arguments: activo,
    );

    if (resultado == true && mounted) {
      final ambienteId = context.read<AmbienteViewModel>().ambienteSeleccionado?.id;
      if (ambienteId != null) {
        context.read<ActivoViewModel>().cargarActivosPorAmbiente(ambienteId);
      }
    }
  }

  void _confirmarEliminar(ActivoModel activo) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.statusRedText, size: 24),
            SizedBox(width: 8),
            Text(
              'Eliminar Activo',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        content: Text(
          '¿Estás seguro de eliminar el activo "${activo.nombre}"?\nEsta acción no se puede deshacer.',
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              try {
                final ok = await _activoRepository.eliminarActivo(activo.id);
                if (ok && mounted) {
                  final ambienteId = context.read<AmbienteViewModel>().ambienteSeleccionado?.id;
                  if (ambienteId != null) {
                    context.read<ActivoViewModel>().cargarActivosPorAmbiente(ambienteId);
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Activo eliminado correctamente'),
                      backgroundColor: AppColors.statusGreen,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error al eliminar activo: $e'),
                      backgroundColor: AppColors.statusRed,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  Widget _buildEstadoChip(String estado) {
    Color bg;
    Color textColor;
    IconData icon;
    String label = estado;

    switch (estado.toLowerCase()) {
      case 'activo':
      case 'presente':
        bg = AppColors.statusGreenBg;
        textColor = AppColors.statusGreenText;
        icon = Icons.check_circle_rounded;
        break;
      case 'mantenimiento':
      case 'no_esperado':
        bg = AppColors.statusAmberBg;
        textColor = AppColors.statusAmberText;
        icon = Icons.warning_rounded;
        break;
      case 'baja':
      case 'dañado':
      case 'faltante':
        bg = AppColors.statusRedBg;
        textColor = AppColors.statusRedText;
        icon = Icons.cancel_rounded;
        break;
      default:
        bg = AppColors.surfaceVariant;
        textColor = AppColors.textSecondary;
        icon = Icons.info_outline_rounded;
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
            label.toUpperCase(),
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

  @override
  Widget build(BuildContext context) {
    final ambienteNombre =
        context.watch<AmbienteViewModel>().ambienteSeleccionado?.nombre ??
            'Ambiente';
    final rol = context.watch<AuthViewModel>().usuario?.rol ?? 'tecnico';

    final puedeEditar = PermisosService.tienePermiso(rol, 'editar_equipos');
    final puedeEliminar = PermisosService.tienePermiso(rol, 'eliminar_equipos');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryNavy,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ambienteNombre,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
                fontSize: 17,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Text(
              'Fichas Técnicas de Equipos',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
      body: Consumer<ActivoViewModel>(
        builder: (context, activoVM, _) {
          if (activoVM.isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(strokeWidth: 2.5),
                  SizedBox(height: 12),
                  Text(
                    'Cargando activos...',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: AppColors.iconInactive,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            );
          }

          if (activoVM.activos.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 64,
                      color: AppColors.iconInactive.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'No hay activos en este ambiente',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Este ambiente aún no tiene equipos asignados.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        color: AppColors.iconInactive,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: activoVM.activos.length,
            itemBuilder: (context, index) {
              final activo = activoVM.activos[index];
              final codigo = activo.qrCodigo.isNotEmpty
                  ? activo.qrCodigo
                  : (activo.uuid.length > 8 ? activo.uuid.substring(0, 8) : activo.uuid);

              return Card(
                margin: const EdgeInsets.only(bottom: 14),
                elevation: 1.5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppColors.border, width: 0.8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Encabezado: Código QR / ID + Estado como chip
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.brandBlue.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.qr_code_2_rounded,
                                  size: 15,
                                  color: AppColors.brandBlue,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  codigo,
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
                          _buildEstadoChip(activo.estado),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Nombre del activo
                      Text(
                        activo.nombre,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Tabla de Ficha Técnica: Ambiente actual, Modelo, Serie
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
                        ),
                        child: Column(
                          children: [
                            _buildInfoRow('Ambiente actual', ambienteNombre, Icons.location_on_outlined),
                            const Divider(height: 12, color: AppColors.border),
                            _buildInfoRow('Modelo', activo.modelo.isNotEmpty ? activo.modelo : 'Sin modelo', Icons.devices_outlined),
                            const Divider(height: 12, color: AppColors.border),
                            _buildInfoRow('Serie', activo.numeroSerie.isNotEmpty ? activo.numeroSerie : 'S/N', Icons.tag_rounded),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Botones de acción según rol
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _mostrarDetallesCompletos(context, activo, ambienteNombre),
                              icon: const Icon(Icons.visibility_outlined, size: 16),
                              label: const Text(
                                'Ficha Completa',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                          if (puedeEditar) ...[
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: () => _editarActivo(activo),
                              icon: const Icon(Icons.edit_outlined, size: 16),
                              label: const Text(
                                'Editar',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryNavy,
                                foregroundColor: Colors.white,
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ],
                          if (puedeEliminar) ...[
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: () => _confirmarEliminar(activo),
                              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.statusRed),
                              tooltip: 'Eliminar activo',
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.iconInactive),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  void _mostrarDetallesCompletos(BuildContext context, ActivoModel activo, String ambienteNombre) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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
                      'Ficha Técnica Completa',
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
                const SizedBox(height: 16),
                _buildDetalleItem('Nombre', activo.nombre),
                _buildDetalleItem('Tipo / Categoría', activo.tipo),
                _buildDetalleItem('Marca', activo.marca),
                _buildDetalleItem('Modelo', activo.modelo),
                _buildDetalleItem('Número de Serie', activo.numeroSerie),
                _buildDetalleItem('Ambiente Actual', ambienteNombre),
                _buildDetalleItem('Código QR', activo.qrCodigo),
                _buildDetalleItem('UUID del Sistema', activo.uuid),
                if (activo.observaciones != null && activo.observaciones!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Observaciones',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      activo.observaciones!,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryNavy,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Cerrar'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetalleItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
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
                color: AppColors.iconInactive,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? 'No especificado' : value,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
