import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:inventario_qr_app/viewmodel/activo_viewmodel.dart';
import 'package:inventario_qr_app/repositories/activo_repository.dart';
import 'package:inventario_qr_app/models/activo_model.dart';

class EquiposManagementScreen extends StatefulWidget {
  const EquiposManagementScreen({super.key});

  @override
  State<EquiposManagementScreen> createState() => _EquiposManagementScreenState();
}

class _EquiposManagementScreenState extends State<EquiposManagementScreen> {
  final ActivoRepository _activoRepository = ActivoRepository();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarTodosLosActivos();
    });
  }

  void _cargarTodosLosActivos() async {
    try {
      final activos = await _activoRepository.getTodosLosActivos();
      if (mounted) {
        context.read<ActivoViewModel>().activos.clear();
        for (var activo in activos) {
          context.read<ActivoViewModel>().activos.add(activo);
        }
        // Force UI update
        setState(() {});
      }
    } catch (e) {
      debugPrint('Error cargando activos: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Equipos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarTodosLosActivos,
          ),
        ],
      ),
      body: Consumer<ActivoViewModel>(
        builder: (context, activoVM, _) {
          if (activoVM.activos.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inventory_2,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No hay equipos registrados',
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
            itemCount: activoVM.activos.length,
            itemBuilder: (context, index) {
              final activo = activoVM.activos[index];

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Encabezado
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  activo.nombre,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${activo.tipo} | ${activo.marca}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _buildEstadoBadge(activo.estado),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Detalles
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInfoRow('Serie:', activo.numeroSerie),
                            const SizedBox(height: 6),
                            _buildInfoRow('UUID:', activo.uuid, mono: true),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Botones de acción
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () => _editarActivo(context, activo),
                            icon: const Icon(Icons.edit, size: 18),
                            label: const Text('Editar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () => _confirmarEliminar(context, activo),
                            icon: const Icon(Icons.delete, size: 18),
                            label: const Text('Eliminar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _crearNuevoActivo(context),
        backgroundColor: Colors.green,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEstadoBadge(String estado) {
    Color color;
    IconData icono;

    switch (estado.toLowerCase()) {
      case 'activo':
        color = Colors.green;
        icono = Icons.check_circle;
        break;
      case 'mantenimiento':
        color = Colors.orange;
        icono = Icons.construction;
        break;
      case 'baja':
        color = Colors.red;
        icono = Icons.cancel;
        break;
      default:
        color = Colors.grey;
        icono = Icons.help;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            estado,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool mono = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value.isEmpty ? 'No especificado' : value,
            style: TextStyle(
              fontSize: 11,
              fontFamily: mono ? 'monospace' : null,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  void _crearNuevoActivo(BuildContext context) {
    Navigator.of(context).pushNamed('/formulario-equipo');
  }

  void _editarActivo(BuildContext context, ActivoModel activo) {
    Navigator.of(context).pushNamed(
      '/formulario-equipo',
      arguments: activo,
    );
  }

  void _confirmarEliminar(BuildContext context, ActivoModel activo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Equipo'),
        content: Text('¿Estás seguro de eliminar "${activo.nombre}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              
              final success = await _activoRepository.eliminarActivo(activo.id);
              
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Equipo eliminado'),
                    backgroundColor: Colors.green,
                  ),
                );
                _cargarTodosLosActivos();
              } else if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('❌ Error eliminando equipo'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
