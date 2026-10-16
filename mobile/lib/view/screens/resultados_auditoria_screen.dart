import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:inventario_qr_app/viewmodel/auditoria_viewmodel.dart';
import 'package:inventario_qr_app/core/services/auditoria_pdf_service.dart';
import 'package:inventario_qr_app/viewmodel/activo_viewmodel.dart';
import 'package:inventario_qr_app/viewmodel/ambiente_viewmodel.dart';
import 'package:file_picker/file_picker.dart';

class ResultadosAuditoriaScreen extends StatefulWidget {
  const ResultadosAuditoriaScreen({super.key});

  @override
  State<ResultadosAuditoriaScreen> createState() => _ResultadosAuditoriaScreenState();
}

class _ResultadosAuditoriaScreenState extends State<ResultadosAuditoriaScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuditoriaViewModel>().cargarDetalles();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultados de Auditoría'),
        leading: const BackButton(),
      ),
      body: Consumer<AuditoriaViewModel>(
        builder: (context, auditoriaVM, _) {
          final auditoria = auditoriaVM.auditoriaActual;
          
          if (auditoria == null) {
            return const Center(child: Text('No hay auditoría activa'));
          }

          final presentados = auditoriaVM.detalles
              .where((d) => d.estado == 'presente')
              .length;
          final faltantes = auditoriaVM.detalles
              .where((d) => d.estado == 'faltante')
              .length;
          final noEsperados = auditoriaVM.detalles
              .where((d) => d.estado == 'no_esperado')
              .length;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Resumen
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(
                          'Resumen de Auditoría',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatCard(
                              'Presentes',
                              presentados.toString(),
                              Colors.green,
                            ),
                            _buildStatCard(
                              'Faltantes',
                              faltantes.toString(),
                              Colors.red,
                            ),
                            _buildStatCard(
                              'No Esperados',
                              noEsperados.toString(),
                              Colors.orange,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Detalles de escaneo
                Text(
                  'Detalles de Equipos',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                
                if (auditoriaVM.detalles.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No hay detalles registrados'),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: auditoriaVM.detalles.length,
                    itemBuilder: (context, index) {
                      final detalle = auditoriaVM.detalles[index];
                      final color = detalle.estado == 'presente'
                          ? Colors.green
                          : detalle.estado == 'faltante'
                          ? Colors.red
                          : Colors.orange;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              detalle.estado == 'presente'
                                  ? Icons.check
                                  : Icons.close,
                              color: Colors.white,
                            ),
                          ),
                          title: Text(detalle.activoId),
                          subtitle: Text(detalle.estado.toUpperCase()),
                          trailing: Text(
                            detalle.fechaEscaneo.toString().split('.')[0],
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      );
                    },
                  ),
                
                const SizedBox(height: 24),
                
                // Botón para volver a inicio
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final rutaPersonalizada = await _seleccionarUbicacion();
                          if (!context.mounted) return;

                          final auditoriaVM = context.read<AuditoriaViewModel>();
                          final activoVM = context.read<ActivoViewModel>();
                          final ambienteVM = context.read<AmbienteViewModel>();
                          
                          if (auditoriaVM.auditoriaActual != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('📄 Generando PDF...'),
                                backgroundColor: Colors.blue,
                              ),
                            );

                            final activosEscaneados = auditoriaVM.detalles
                                .where((m) => m.estado == 'presente')
                                .map((m) => m.activoId)
                                .toList();

                            await AuditoriaPdfService.generarPdfAuditoria(
                              auditoria: auditoriaVM.auditoriaActual!,
                              activosDelAmbiente: activoVM.activos,
                              activosEscaneados: activosEscaneados,
                              ambienteNombre: ambienteVM.ambienteSeleccionado?.nombre ?? 'Desconocido',
                              tecnicoNombre: 'Usuario', // Obtener del auth si está disponible
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
                          }
                        },
                        icon: const Icon(Icons.download),
                        label: const Text('Descargar PDF'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          context.read<AuditoriaViewModel>().limpiarAuditoria();
                          Navigator.of(context).pushReplacementNamed('/main');
                        },
                        icon: const Icon(Icons.home),
                        label: const Text('Ir al Inicio'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
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
}
