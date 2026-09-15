import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:inventario_qr_app/viewmodel/auditoria_viewmodel.dart';
import 'package:inventario_qr_app/viewmodel/activo_viewmodel.dart';

class ReportesScreen extends StatefulWidget {
  const ReportesScreen({super.key});

  @override
  State<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends State<ReportesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AuditoriaViewModel>().cargarReportes();
        context.read<ActivoViewModel>().cargarReportes();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reportes y Resumen',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            // Última auditoría
            _buildReporteCard(
              context,
              titulo: 'Última Auditoría',
              icono: Icons.checklist,
              color: Colors.blue,
              contenido: Consumer<AuditoriaViewModel>(
                builder: (context, auditoriaVM, _) {
                  if (auditoriaVM.ultimaAuditoria == null) {
                    return const Text('Sin auditorías realizadas');
                  }
                  final auditoria = auditoriaVM.ultimaAuditoria!;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Fecha: ${auditoria.fechaInicio.toString().split('.')[0]}',
                                  style: const TextStyle(fontSize: 13),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Equipos: ${auditoria.totalEncontrados}/${auditoria.totalEsperados}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '✅ Completada',
                              style: TextStyle(
                                color: Colors.green[800],
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Último escaneo
            _buildReporteCard(
              context,
              titulo: 'Último Escaneo',
              icono: Icons.qr_code_2,
              color: Colors.green,
              contenido: Consumer<ActivoViewModel>(
                builder: (context, activoVM, _) {
                  if (activoVM.ultimoEscaneado == null) {
                    return const Text('Sin escaneos realizados');
                  }
                  final activo = activoVM.ultimoEscaneado!;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Equipo: ${activo.nombre}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Tipo: ${activo.tipo}'),
                      const SizedBox(height: 4),
                      Text('Estado: ${activo.estado}'),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Movimientos recientes
            _buildReporteCard(
              context,
              titulo: 'Escaneos Recientes',
              icono: Icons.swap_horiz,
              color: Colors.orange,
              contenido: Consumer<AuditoriaViewModel>(
                builder: (context, auditoriaVM, _) {
                  if (auditoriaVM.movimientosRecientes.isEmpty) {
                    return const Text('Sin movimientos registrados');
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: auditoriaVM.movimientosRecientes.map((detalle) {
                      final estadoColor = detalle.estado == 'presente'
                          ? Colors.green
                          : detalle.estado == 'faltante'
                          ? Colors.red
                          : Colors.orange;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Activo: ${detalle.activoId.substring(0, 8)}...',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Estado: ${detalle.estado}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: estadoColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: estadoColor.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Icon(
                                  detalle.estado == 'presente'
                                      ? Icons.check
                                      : detalle.estado == 'faltante'
                                      ? Icons.close
                                      : Icons.warning,
                                  color: estadoColor,
                                  size: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Cambios recientes - Dispositivos nuevos
            _buildReporteCard(
              context,
              titulo: 'Dispositivos Nuevos',
              icono: Icons.add_circle,
              color: Colors.green,
              contenido: Consumer<ActivoViewModel>(
                builder: (context, activoVM, _) {
                  if (activoVM.activosNuevos.isEmpty) {
                    return const Text('Sin dispositivos nuevos');
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: activoVM.activosNuevos.map((activo) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green[200]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text('✅', style: TextStyle(fontSize: 16)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      activo.nombre,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                activo.tipo,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Cambios recientes - Dispositivos de baja
            _buildReporteCard(
              context,
              titulo: 'Dispositivos de Baja',
              icono: Icons.delete_outline,
              color: Colors.red,
              contenido: Consumer<ActivoViewModel>(
                builder: (context, activoVM, _) {
                  if (activoVM.activosDeBaja.isEmpty) {
                    return const Text('Sin dispositivos de baja');
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: activoVM.activosDeBaja.map((activo) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red[200]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text('❌', style: TextStyle(fontSize: 16)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      activo.nombre,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                activo.tipo,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReporteCard(
    BuildContext context, {
    required String titulo,
    required IconData icono,
    required Color color,
    required Widget contenido,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icono, color: color),
                ),
                const SizedBox(width: 12),
                Text(
                  titulo,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            contenido,
          ],
        ),
      ),
    );
  }
}
