import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:inventario_qr_app/viewmodel/ambiente_viewmodel.dart';
import 'package:inventario_qr_app/viewmodel/activo_viewmodel.dart';

class SelectAmbienteAuditoriaScreen extends StatefulWidget {
  const SelectAmbienteAuditoriaScreen({super.key});

  @override
  State<SelectAmbienteAuditoriaScreen> createState() => _SelectAmbienteAuditoriaScreenState();
}

class _SelectAmbienteAuditoriaScreenState extends State<SelectAmbienteAuditoriaScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AmbienteViewModel>().cargarAmbientes();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seleccionar Ambiente para Auditoría'),
        leading: const BackButton(),
      ),
      body: Consumer<AmbienteViewModel>(
        builder: (context, ambienteVM, _) {
          if (ambienteVM.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (ambienteVM.ambientes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.location_off,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No hay ambientes disponibles',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: ambienteVM.ambientes.length,
            itemBuilder: (context, index) {
              final ambiente = ambienteVM.ambientes[index];

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                child: InkWell(
                  onTap: () => _seleccionarAmbiente(context, ambienteVM, ambiente),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
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
                                    ambiente.nombre,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    ambiente.descripcion,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.blue[900],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue[200]!),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 16,
                                color: Colors.blue[900],
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '📍 ${ambiente.radioGeofence.toStringAsFixed(0)}m de radio',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue[900],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _seleccionarAmbiente(
    BuildContext context,
    AmbienteViewModel ambienteVM,
    dynamic ambiente,
  ) async {
    // Seleccionar ambiente
    await ambienteVM.seleccionarAmbiente(ambiente);

    if (!context.mounted) return;

    // Cargar activos para contar cuántos hay
    final activoVM = context.read<ActivoViewModel>();
    await activoVM.cargarActivosPorAmbiente(ambiente.id);

    // Verificar ubicación (solo aviso, no bloquea)
    if (!ambienteVM.dentroDeGeofence) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ No estás en el laboratorio ${ambiente.nombre}'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }

    // Navegar a auditoría
    if (context.mounted) {
      Navigator.of(context).pushReplacementNamed('/auditoria');
    }
  }
}
