import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:inventario_qr_app/core/theme/app_theme.dart';
import 'package:inventario_qr_app/core/utils/app_routes.dart';
import 'package:inventario_qr_app/viewmodel/activo_viewmodel.dart';
import 'package:inventario_qr_app/viewmodel/auth_viewmodel.dart';
import 'package:inventario_qr_app/viewmodel/solicitud_viewmodel.dart';
import 'package:inventario_qr_app/repositories/activo_repository.dart';
import 'package:inventario_qr_app/models/activo_model.dart';
import 'package:inventario_qr_app/view/widgets/error_state.dart';
import 'package:inventario_qr_app/view/widgets/floating_bottom_nav_bar.dart';

class EquiposManagementScreen extends StatefulWidget {
  final ActivoRepository? activoRepository;

  const EquiposManagementScreen({super.key, this.activoRepository});

  @override
  State<EquiposManagementScreen> createState() => _EquiposManagementScreenState();
}

class _EquiposManagementScreenState extends State<EquiposManagementScreen> {
  late final ActivoRepository _activoRepository;
  bool _cargando = false;
  String? _errorCarga;

  @override
  void initState() {
    super.initState();
    _activoRepository = widget.activoRepository ?? ActivoRepository();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarTodosLosActivos();
      context.read<SolicitudViewModel>().cargarPendientesCount();
    });
  }

  void _cargarTodosLosActivos() async {
    setState(() {
      _cargando = true;
      _errorCarga = null;
    });

    try {
      final activos = await _activoRepository.getTodosLosActivos();
      if (mounted) {
        context.read<ActivoViewModel>().activos.clear();
        for (var activo in activos) {
          context.read<ActivoViewModel>().activos.add(activo);
        }
        setState(() {
          _cargando = false;
        });
      }
    } catch (e) {
      debugPrint('Error cargando activos: $e');
      if (mounted) {
        setState(() {
          _cargando = false;
          _errorCarga = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();
    final rol = (authVM.usuario?.rol ?? 'tecnico').toLowerCase();
    final esAuditor = rol == 'auditor';
    final esAdmin = rol == 'admin';
    final bottomInset = FloatingBottomNavBar.totalOccupiedHeight(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Equipos'),
        actions: [
          // Acceso a Mis solicitudes
          IconButton(
            icon: const Icon(Icons.assignment_outlined),
            tooltip: 'Mis Solicitudes',
            onPressed: () {
              Navigator.of(context).pushNamed(AppRoutes.misSolicitudes);
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargando ? null : _cargarTodosLosActivos,
          ),
        ],
      ),
      body: Consumer2<ActivoViewModel, SolicitudViewModel>(
        builder: (context, activoVM, solicitudVM, _) {
          if (_cargando || activoVM.isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(strokeWidth: 2.5),
                  SizedBox(height: 12),
                  Text(
                    'Cargando equipos...',
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 14),
                  ),
                ],
              ),
            );
          }

          if (_errorCarga != null) {
            return ErrorState(
              error: _errorCarga,
              titulo: 'Error al obtener equipos',
              onRetry: _cargarTodosLosActivos,
            );
          }

          return Column(
            children: [
              // Admin en móvil: ve contador de pendientes y aviso "Confirmar en la web" sin botones de aprobar
              if (esAdmin)
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFFB300)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Color(0xFFF57F17), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${solicitudVM.pendientesCount} solicitud(es) pendiente(s). Confirmar en la web.',
                          style: const TextStyle(
                            color: Color(0xFFE65100),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pushNamed(AppRoutes.misSolicitudes);
                        },
                        child: const Text(
                          'VER',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFE65100)),
                        ),
                      ),
                    ],
                  ),
                ),

              // Lista de Equipos
              Expanded(
                child: activoVM.activos.isEmpty
                    ? ErrorState(
                        icon: Icons.inventory_2_outlined,
                        titulo: 'No hay equipos registrados',
                        mensaje: 'No se encontraron equipos en el inventario o la base de datos está vacía.',
                        onRetry: _cargarTodosLosActivos,
                      )
                    : ListView.builder(
                        padding: EdgeInsets.fromLTRB(16, 12, 16, bottomInset + 80),
                        itemCount: activoVM.activos.length,
                        itemBuilder: (context, index) {
                          final activo = activoVM.activos[index];

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 1.5,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Encabezado
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              activo.nombre,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${activo.tipo} | ${activo.marca}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      _buildEstadoBadge(activo.estado),
                                    ],
                                  ),
                                  const SizedBox(height: 10),

                                  // Detalles de Identificación
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _buildInfoRow('Código:', activo.qrCodigo.isNotEmpty ? activo.qrCodigo : 'Sin código', mono: true),
                                        const SizedBox(height: 4),
                                        _buildInfoRow('Serie:', activo.numeroSerie),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  // Acciones de Gobernanza:
                                  // Auditor: sin acceso a estas acciones
                                  // Técnico y Admin: "Solicitar edición" y "Solicitar baja"
                                  if (esAuditor)
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(vertical: 6),
                                      alignment: Alignment.center,
                                      child: Text(
                                        'Rol Auditor: Modo solo lectura',
                                        style: TextStyle(fontSize: 11, color: Colors.grey[500], fontStyle: FontStyle.italic),
                                      ),
                                    )
                                  else
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        OutlinedButton.icon(
                                          onPressed: () => _solicitarEdicion(activo),
                                          icon: const Icon(Icons.edit_note, size: 16),
                                          label: const Text('Solicitar edición', style: TextStyle(fontSize: 12)),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.blue[800],
                                            side: BorderSide(color: Colors.blue[300]!),
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        OutlinedButton.icon(
                                          onPressed: () => _solicitarBaja(context, activo),
                                          icon: const Icon(Icons.remove_circle_outline, size: 16),
                                          label: const Text('Solicitar baja', style: TextStyle(fontSize: 12)),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.red[800],
                                            side: BorderSide(color: Colors.red[300]!),
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      // Floating Action Button: "Solicitar alta" (oculto para Auditor)
      floatingActionButton: esAuditor
          ? null
          : FloatingActionButton.extended(
              onPressed: _solicitarAlta,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 3,
              icon: const Icon(Icons.add_task, size: 20),
              label: const Text(
                'Solicitar alta',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
    );
  }

  Widget _buildEstadoBadge(String estado) {
    Color color;
    IconData icono;

    switch (estado.toLowerCase()) {
      case 'activo':
        color = Colors.green;
        icono = Icons.check_circle;
        break;
      case 'mantenimiento':
      case 'dañado':
        color = Colors.orange;
        icono = Icons.construction;
        break;
      case 'baja':
      case 'inactivo':
        color = Colors.red;
        icono = Icons.cancel;
        break;
      default:
        color = Colors.grey;
        icono = Icons.help;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            estado,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool mono = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value.isEmpty ? 'No especificado' : value,
            style: TextStyle(
              fontSize: 11,
              fontFamily: mono ? 'monospace' : null,
              fontWeight: mono ? FontWeight.bold : FontWeight.normal,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  void _solicitarAlta() async {
    final result = await Navigator.of(context).pushNamed(AppRoutes.formularioEquipo);
    if (!mounted) return;
    if (result == true) {
      context.read<SolicitudViewModel>().cargarPendientesCount();
    }
  }

  void _solicitarEdicion(ActivoModel activo) async {
    final result = await Navigator.of(context).pushNamed(
      AppRoutes.formularioEquipo,
      arguments: activo,
    );
    if (!mounted) return;
    if (result == true) {
      context.read<SolicitudViewModel>().cargarPendientesCount();
    }
  }

  void _solicitarBaja(BuildContext context, ActivoModel activo) {
    final motivoCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Solicitar Baja de Equipo'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Activo: ${activo.nombre} (${activo.qrCodigo.isNotEmpty ? activo.qrCodigo : activo.numeroSerie})',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 8),
              const Text(
                'La baja es lógica (estado Inactivo) y debe ser aprobada por un administrador en la web.',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: motivoCtrl,
                maxLines: 3,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'El motivo de la baja es obligatorio';
                  }
                  return null;
                },
                decoration: const InputDecoration(
                  labelText: 'Motivo obligatorio *',
                  hintText: 'Ej: Equipo obsoleto e irreparable con pantalla rota...',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.all(10),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final motivo = motivoCtrl.text.trim();
              Navigator.pop(ctx);

              final success = await context.read<SolicitudViewModel>().solicitarBaja(
                activoId: activo.id.isNotEmpty ? activo.id : activo.uuid,
                motivo: motivo,
              );

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Solicitud de baja enviada. Se confirmará en la web.'
                          : 'Error al enviar solicitud de baja.',
                    ),
                    backgroundColor: success ? Colors.green[700] : Colors.red[700],
                  ),
                );
              }
            },
            child: const Text('Enviar Solicitud'),
          ),
        ],
      ),
    );
  }
}
