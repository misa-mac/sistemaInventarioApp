import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:inventario_qr_app/viewmodel/auditoria_viewmodel.dart';
import 'package:inventario_qr_app/viewmodel/ambiente_viewmodel.dart';
import 'package:inventario_qr_app/viewmodel/auth_viewmodel.dart';
import 'package:inventario_qr_app/viewmodel/activo_viewmodel.dart';

class AuditoriaScreen extends StatefulWidget {
  const AuditoriaScreen({super.key});

  @override
  State<AuditoriaScreen> createState() => _AuditoriaScreenState();
}

class _AuditoriaScreenState extends State<AuditoriaScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _iniciarAuditoria();
    });
  }

  void _iniciarAuditoria() async {
    final ambienteVM = context.read<AmbienteViewModel>();
    final auditoriaVM = context.read<AuditoriaViewModel>();
    final authVM = context.read<AuthViewModel>();

    final ambiente = ambienteVM.ambienteSeleccionado;
    final usuario = authVM.usuario;

    if (ambiente == null || usuario == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Ambiente o usuario no seleccionado')),
      );
      return;
    }

    // Cargar activos del ambiente
    await context.read<AmbienteViewModel>().cargarAmbientes();
    
    // Contar equipos del ambiente
    final activosVM = context.read<ActivoViewModel>();
    await activosVM.cargarActivosPorAmbiente(ambiente.id);
    final totalEsperados = activosVM.activos.length;

    final success = await auditoriaVM.iniciarAuditoria(
      ambiente.id,
      usuario.id,
      totalEsperados, // Calcula dinámicamente
    );

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error iniciando auditoría')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modo Auditoría'),
        leading: const BackButton(),
      ),
      body: Consumer2<AuditoriaViewModel, AmbienteViewModel>(
        builder: (context, auditoriaVM, ambienteVM, _) {
          if (auditoriaVM.auditoriaActual == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final ambiente = ambienteVM.ambienteSeleccionado;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Información del ambiente
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(
                          ambiente?.nombre ?? 'Ambiente',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '📍 ${ambienteVM.dentroDeGeofence ? "✓ Dentro del rango" : "✗ Fuera del rango"}',
                          style: TextStyle(
                            color: ambienteVM.dentroDeGeofence 
                              ? Colors.green 
                              : Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Contador de escaneos
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue[900]!, width: 2),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Equipos Escaneados',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${auditoriaVM.escaneosCont}/${auditoriaVM.auditoriaActual!.totalEsperados}',
                        style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[900],
                        ),
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: auditoriaVM.auditoriaActual!.totalEsperados > 0
                          ? auditoriaVM.escaneosCont / auditoriaVM.auditoriaActual!.totalEsperados
                          : 0,
                        minHeight: 8,
                        backgroundColor: Colors.grey[300],
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Botones
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pushNamed('/qr-scan');
                    },
                    icon: const Icon(Icons.qr_code_2),
                    label: const Text('Escanear QR'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[900],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => _finalizarAuditoria(context, auditoriaVM),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Finalizar Auditoría'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _finalizarAuditoria(BuildContext context, AuditoriaViewModel auditoriaVM) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Finalizar Auditoría'),
        content: Text('¿Estás seguro de finalizar? Se registrarán ${auditoriaVM.escaneosCont} equipos.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Finalizar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      final success = await auditoriaVM.finalizarAuditoria();
      if (success && context.mounted) {
        Navigator.of(context).pushReplacementNamed('/resultados-auditoria');
      }
    }
  }
}
