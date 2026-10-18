import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:inventario_qr_app/viewmodel/solicitud_viewmodel.dart';
import 'package:inventario_qr_app/view/widgets/floating_bottom_nav_bar.dart';

class MisSolicitudesScreen extends StatefulWidget {
  const MisSolicitudesScreen({super.key});

  @override
  State<MisSolicitudesScreen> createState() => _MisSolicitudesScreenState();
}

class _MisSolicitudesScreenState extends State<MisSolicitudesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SolicitudViewModel>().cargarSolicitudes();
    });
  }

  Widget _buildEstadoChip(String estado, bool sincronizado) {
    if (!sincronizado) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[400]!),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off, size: 14, color: Colors.grey),
            SizedBox(width: 4),
            Text(
              'En cola offline',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    switch (estado.toLowerCase()) {
      case 'pendiente':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8E1), // Ámbar claro
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFFB300)), // Ámbar borde
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.schedule, size: 14, color: Color(0xFFF57F17)),
              SizedBox(width: 4),
              Text(
                'Pendiente',
                style: TextStyle(
                  color: Color(0xFFF57F17),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      case 'aprobada':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9), // Verde claro
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF66BB6A)), // Verde borde
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, size: 14, color: Color(0xFF2E7D32)),
              SizedBox(width: 4),
              Text(
                'Aprobada',
                style: TextStyle(
                  color: Color(0xFF2E7D32),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      case 'rechazada':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFFFEBEE), // Rojo claro
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEF5350)), // Rojo borde
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cancel, size: 14, color: Color(0xFFC62828)),
              SizedBox(width: 4),
              Text(
                'Rechazada',
                style: TextStyle(
                  color: Color(0xFFC62828),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      default:
        return Text(estado);
    }
  }

  Widget _buildTipoBadge(String tipo) {
    Color bg = Colors.blue[50]!;
    Color text = Colors.blue[800]!;
    String label = tipo.toUpperCase();

    if (tipo == 'alta') {
      bg = Colors.green[50]!;
      text = Colors.green[800]!;
      label = 'ALTA';
    } else if (tipo == 'edicion') {
      bg = Colors.amber[50]!;
      text = Colors.amber[900]!;
      label = 'EDICIÓN';
    } else if (tipo == 'baja') {
      bg = Colors.red[50]!;
      text = Colors.red[800]!;
      label = 'BAJA';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = FloatingBottomNavBar.totalOccupiedHeight(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Solicitudes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Sincronizar cola offline',
            onPressed: () async {
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              final count = await context.read<SolicitudViewModel>().sincronizarColaOffline();
              if (!mounted) return;
              scaffoldMessenger.showSnackBar(
                SnackBar(
                  content: Text(count > 0 
                      ? 'Se sincronizaron $count solicitudes con la web.' 
                      : 'No hay solicitudes pendientes por sincronizar.'),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<SolicitudViewModel>().cargarSolicitudes(),
          ),
        ],
      ),
      body: Consumer<SolicitudViewModel>(
        builder: (context, vm, _) {
          if (vm.isLoading && vm.solicitudes.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (vm.solicitudes.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.assignment_outlined, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    const Text(
                      'No tienes solicitudes registradas',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Cuando propongas altas, ediciones o bajas de equipos, aparecerán aquí con su estado de aprobación.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            );
          }

          return Column(
            children: [
              // Banner si hay pendientes offline
              if (vm.offlinePendingCount > 0)
                Container(
                  color: Colors.amber[100],
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Icon(Icons.cloud_queue, size: 18, color: Colors.amber[900]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${vm.offlinePendingCount} solicitud(es) guardada(s) localmente pendientes de enviar.',
                          style: TextStyle(fontSize: 12, color: Colors.amber[900], fontWeight: FontWeight.w600),
                        ),
                      ),
                      TextButton(
                        onPressed: () => vm.sincronizarColaOffline(),
                        child: const Text('ENVIAR YA', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),

              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, bottomInset + 32),
                  itemCount: vm.solicitudes.length,
                  itemBuilder: (context, index) {
                    final sol = vm.solicitudes[index];
                    final nombre = sol.tipo == 'alta'
                        ? (sol.datos['nombre'] ?? 'Nuevo Activo')
                        : (sol.activoNombre ?? sol.datos['nombre'] ?? 'Activo');

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 1.5,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Fila superior: Tipo y Chip de Estado
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildTipoBadge(sol.tipo),
                                _buildEstadoChip(sol.estado, sol.sincronizado),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // Nombre del activo
                            Text(
                              nombre.toString(),
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),

                            // Código si ya existe o fue aprobado
                            if (sol.activoResultanteCodigo != null && sol.activoResultanteCodigo!.isNotEmpty)
                              Container(
                                margin: const EdgeInsets.only(top: 4, bottom: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green[50],
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.green[200]!),
                                ),
                                child: Text(
                                  'Código asignado: ${sol.activoResultanteCodigo}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green[900],
                                  ),
                                ),
                              )
                            else if (sol.activoCodigo != null && sol.activoCodigo!.isNotEmpty)
                              Text(
                                'Código: ${sol.activoCodigo}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontFamily: 'monospace',
                                  color: Colors.grey[700],
                                ),
                              ),

                            // Motivo (en bajas)
                            if (sol.tipo == 'baja' && sol.motivo != null && sol.motivo!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  'Motivo de baja: "${sol.motivo}"',
                                  style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.black87),
                                ),
                              ),

                            // Comentario de Rechazo (si fue rechazada)
                            if (sol.estado.toLowerCase() == 'rechazada' &&
                                sol.comentarioRevision != null &&
                                sol.comentarioRevision!.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFEBEE),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFEF9A9A)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(Icons.info_outline, size: 14, color: Color(0xFFC62828)),
                                        SizedBox(width: 4),
                                        Text(
                                          'Comentario de rechazo en la web:',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFFC62828),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      sol.comentarioRevision!,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFFB71C1C),
                                        height: 1.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            const SizedBox(height: 8),
                            // Fecha
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                '${sol.createdAt.day.toString().padLeft(2, '0')}/${sol.createdAt.month.toString().padLeft(2, '0')}/${sol.createdAt.year} ${sol.createdAt.hour.toString().padLeft(2, '0')}:${sol.createdAt.minute.toString().padLeft(2, '0')}',
                                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                              ),
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
    );
  }
}
