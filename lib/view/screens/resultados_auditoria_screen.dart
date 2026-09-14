import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:inventario_qr_app/viewmodel/auditoria_viewmodel.dart';

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
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      context.read<AuditoriaViewModel>().limpiarAuditoria();
                      Navigator.of(context).pushReplacementNamed('/main');
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Ir al Inicio'),
                  ),
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
}
