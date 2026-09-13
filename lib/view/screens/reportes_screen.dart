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
                  if (auditoriaVM.auditoriaActual == null) {
                    return const Text('Sin auditorías recientes');
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Fecha: ${auditoriaVM.auditoriaActual!.fechaInicio}'),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Completada',
                              style: TextStyle(color: Colors.green[800]),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Equipos encontrados: ${auditoriaVM.escaneosCont}/${auditoriaVM.auditoriaActual!.totalEsperados}',
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
                  if (activoVM.activoActual == null) {
                    return const Text('Sin escaneos recientes');
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Equipo: ${activoVM.activoActual!.nombre}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text('Tipo: ${activoVM.activoActual!.tipo}'),
                      const SizedBox(height: 4),
                      Text('Estado: ${activoVM.activoActual!.estado}'),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Movimientos recientes
            _buildReporteCard(
              context,
              titulo: 'Movimientos Recientes',
              icono: Icons.swap_horiz,
              color: Colors.orange,
              contenido: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMovimientoItem('Pantalla 1', 'Lab 1 → Lab 2', 'Hace 2 horas'),
                  const SizedBox(height: 8),
                  _buildMovimientoItem('CPU 5', 'Lab 3 → Depósito', 'Hace 1 día'),
                  const SizedBox(height: 8),
                  _buildMovimientoItem('Teclado 12', 'Taller 1 → Lab 1', 'Hace 3 días'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Cambios recientes
            _buildReporteCard(
              context,
              titulo: 'Cambios Recientes',
              icono: Icons.update,
              color: Colors.purple,
              contenido: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCambioItem('✅', 'Dispositivo Nuevo', 'Monitor LG 27"', 'Hoy'),
                  const SizedBox(height: 8),
                  _buildCambioItem('❌', 'Dispositivo de Baja', 'CPU Antigua', 'Hace 2 días'),
                ],
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

  Widget _buildMovimientoItem(String equipo, String movimiento, String fecha) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            equipo,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            movimiento,
            style: const TextStyle(fontSize: 12),
          ),
          Text(
            fecha,
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildCambioItem(
    String icono,
    String tipo,
    String descripcion,
    String fecha,
  ) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(icono, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                tipo,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            descripcion,
            style: const TextStyle(fontSize: 12),
          ),
          Text(
            fecha,
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
