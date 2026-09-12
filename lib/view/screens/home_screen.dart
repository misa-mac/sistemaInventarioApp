import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:inventario_qr_app/viewmodel/auth_viewmodel.dart';
import 'package:inventario_qr_app/viewmodel/ambiente_viewmodel.dart';
import 'package:inventario_qr_app/models/ambiente_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
        title: const Text('ITBM - Inventario'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _handleLogout(context),
          ),
        ],
      ),
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
                'Selecciona un Ambiente',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ...ambienteVM.ambientes.map((ambiente) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: Icon(Icons.location_on, color: Colors.blue[900]),
                    title: Text(ambiente.nombre),
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

  void _selectAmbiente(BuildContext context, AmbienteViewModel ambienteVM, AmbienteModel ambiente) async {
    await ambienteVM.seleccionarAmbiente(ambiente);
    
    if (!context.mounted) return;

    if (!ambienteVM.dentroDeGeofence) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚠️ No estás en el laboratorio ${ambiente.nombre}'),
          backgroundColor: Colors.orange,
        ),
      );
    }

    Navigator.of(context).pushNamed('/auditoria');
  }

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              context.read<AuthViewModel>().logout();
              Navigator.of(context).pushReplacementNamed('/login');
            },
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );
  }
}
