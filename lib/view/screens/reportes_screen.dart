import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:inventario_qr_app/viewmodel/auditoria_viewmodel.dart';
import 'package:inventario_qr_app/viewmodel/activo_viewmodel.dart';
import 'package:inventario_qr_app/core/services/reportes_pdf_service.dart';
import 'package:inventario_qr_app/core/services/auditoria_pdf_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:inventario_qr_app/models/auditoria_model.dart';
import 'package:inventario_qr_app/repositories/auditoria_repository.dart';
import 'package:inventario_qr_app/models/ambiente_model.dart';
import 'package:inventario_qr_app/viewmodel/ambiente_viewmodel.dart';

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
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'pdf_auditoria',
            onPressed: () => _descargarPdfAuditoriaPorFecha(context),
            backgroundColor: Colors.orange,
            tooltip: 'PDF Auditoría por Fecha',
            child: const Icon(Icons.calendar_today),
          ),
          const SizedBox(height: 16),
          FloatingActionButton.extended(
            heroTag: 'pdf_reportes',
            onPressed: () => _descargarPdfReportes(),
            backgroundColor: Colors.blue,
            icon: const Icon(Icons.download),
            label: const Text('Descargar PDF'),
            foregroundColor: Colors.white,
          ),
        ],
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

  void _descargarPdfReportes() async {
    final rutaPersonalizada = await _seleccionarUbicacion();
    
    if (!mounted) return;

    final auditoriaVM = context.read<AuditoriaViewModel>();
    final activoVM = context.read<ActivoViewModel>();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📄 Generando PDF...'),
        backgroundColor: Colors.blue,
      ),
    );

    await ReportesPdfService.generarPdfReportes(
      ultimaAuditoria: auditoriaVM.ultimaAuditoria,
      ultimoEscaneado: activoVM.ultimoEscaneado,
      movimientosRecientes: auditoriaVM.movimientosRecientes,
      activosNuevos: activoVM.activosNuevos,
      activosDeBaja: activoVM.activosDeBaja,
      rutaPersonalizada: rutaPersonalizada,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            rutaPersonalizada != null
                ? '✅ PDF descargado en: $rutaPersonalizada'
                : '✅ PDF descargado en Descargas',
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _descargarPdfAuditoriaPorFecha(BuildContext context) async {
    final fechaSeleccionada = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      locale: const Locale('es', 'ES'),
    );

    if (fechaSeleccionada == null || !context.mounted) return;

    final auditoriaSeleccionada = await _obtenerAuditoriasDelDia(fechaSeleccionada);

    if (auditoriaSeleccionada == null || !context.mounted) return;

    final rutaPersonalizada = await _seleccionarUbicacion();

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📄 Obteniendo datos...'),
        backgroundColor: Colors.blue,
      ),
    );

    try {
      // Obtener nombre del ambiente desde BD
      final auditoriaRepo = AuditoriaRepository();
      final auditoriaDetalles = await auditoriaRepo.obtenerAuditoriaConDetalles(auditoriaSeleccionada.id);
      
      if (!context.mounted) return;

      String ambienteNombre = 'Ambiente Desconocido';
      if (auditoriaDetalles != null && auditoriaDetalles['ambiente_id'] != null) {
        final ambienteVM = context.read<AmbienteViewModel>();
        final ambiente = ambienteVM.ambientes
            .firstWhere(
              (a) => a.id == auditoriaDetalles['ambiente_id'],
              orElse: () => AmbienteModel(
                id: '',
                nombre: 'Desconocido',
                descripcion: '',
                tieneInternet: false,
                latitude: 0,
                longitude: 0,
                radioGeofence: 0,
              ),
            );
        ambienteNombre = ambiente.nombre;
      }

      // Obtener IDs de activos escaneados en esa auditoría
      final activosEscaneados = await auditoriaRepo.obtenerActivosEscaneadosDeAuditoria(
        auditoriaSeleccionada.id,
      );

      if (!context.mounted) return;

      // Cargar todos los activos del ambiente
      await context.read<ActivoViewModel>().cargarActivosPorAmbiente(
        auditoriaSeleccionada.ambienteId,
      );

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📄 Generando PDF...'),
          backgroundColor: Colors.blue,
        ),
      );

      final activos = context.read<ActivoViewModel>().activos;

      await AuditoriaPdfService.generarPdfAuditoria(
        auditoria: auditoriaSeleccionada,
        activosDelAmbiente: activos,
        activosEscaneados: activosEscaneados,
        ambienteNombre: ambienteNombre,
        tecnicoNombre: 'Usuario',
        rutaPersonalizada: rutaPersonalizada,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              rutaPersonalizada != null
                  ? '✅ PDF descargado en: $rutaPersonalizada'
                  : '✅ PDF descargado en Descargas',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String?> _seleccionarUbicacion() async {
    try {
      final resultado = await FilePicker.platform.getDirectoryPath();
      return resultado;
    } catch (e) {
      debugPrint('Error seleccionando ubicación: $e');
      return null;
    }
  }

  Future<AuditoriaModel?> _obtenerAuditoriasDelDia(DateTime fecha) async {
    try {
      final auditoriaRepository = AuditoriaRepository();
      
      debugPrint('🔍 Buscando auditorías para: ${fecha.toString().split(' ')[0]}');

      // Obtener auditorías de esa fecha desde BD
      final auditorias = await auditoriaRepository.obtenerAuditoriasDelDia(fecha);

      if (auditorias.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'No hay auditorías para: ${fecha.toString().split(' ')[0]}',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return null;
      }

      // Si solo hay una, retornarla directamente
      if (auditorias.length == 1) {
        return auditorias.first;
      }

      // Si hay varias, mostrar un diálogo para que el usuario seleccione
      if (mounted) {
        final seleccionada = await showDialog<AuditoriaModel>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Seleccionar Auditoría'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: auditorias.length,
                itemBuilder: (context, index) {
                  final auditoria = auditorias[index];
                  return ListTile(
                    title: Text('Auditoría ${index + 1}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hora: ${auditoria.fechaInicio.hour.toString().padLeft(2, '0')}:${auditoria.fechaInicio.minute.toString().padLeft(2, '0')}',
                        ),
                        Text(
                          'Equipos: ${auditoria.totalEncontrados}/${auditoria.totalEsperados}',
                        ),
                        Text(
                          auditoria.totalEncontrados == auditoria.totalEsperados
                              ? '✅ Completada'
                              : '⚠️ Incompleta',
                          style: TextStyle(
                            color: auditoria.totalEncontrados == auditoria.totalEsperados
                                ? Colors.green
                                : Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    onTap: () => Navigator.pop(context, auditoria),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
            ],
          ),
        );

        return seleccionada;
      }

      return null;
    } catch (e) {
      debugPrint('❌ Error obteniendo auditorías: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }
}
