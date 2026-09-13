import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:inventario_qr_app/viewmodel/ambiente_viewmodel.dart';

class InventarioScreen extends StatefulWidget {
  const InventarioScreen({super.key});

  @override
  State<InventarioScreen> createState() => _InventarioScreenState();
}

class _InventarioScreenState extends State<InventarioScreen> {
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
      body: Consumer<AmbienteViewModel>(
        builder: (context, ambienteVM, _) {
          if (ambienteVM.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (ambienteVM.ambientes.isEmpty) {
            return const Center(child: Text('No hay ambientes disponibles'));
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Inventario de Laboratorios',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ...ambienteVM.ambientes.map((ambiente) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  child: ListTile(
                    leading: Icon(Icons.location_on, color: Colors.blue[900]),
                    title: Text(
                      ambiente.nombre,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(ambiente.descripcion),
                    trailing: const Icon(Icons.arrow_forward),
                    onTap: () => _selectAmbiente(context, ambienteVM, ambiente),
                  ),
                );
              }).toList(),
            ],
          );
        },
      ),
    );
  }

  void _selectAmbiente(BuildContext context, AmbienteViewModel ambienteVM, dynamic ambiente) async {
    await ambienteVM.seleccionarAmbiente(ambiente);
    
    if (!context.mounted) return;

    if (!ambienteVM.dentroDeGeofence) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚠️ No estás en el laboratorio ${ambiente.nombre}'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
    }

    Navigator.of(context).pushNamed('/auditoria');
  }
}
