import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:inventario_qr_app/viewmodel/activo_viewmodel.dart';
import 'package:inventario_qr_app/viewmodel/ambiente_viewmodel.dart';

class ActivosDetalleScreen extends StatefulWidget {
  const ActivosDetalleScreen({super.key});

  @override
  State<ActivosDetalleScreen> createState() => _ActivosDetalleScreenState();
}

class _ActivosDetalleScreenState extends State<ActivosDetalleScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<AmbienteViewModel>(
          builder: (context, ambienteVM, _) {
            return Text(
              ambienteVM.ambienteSeleccionado?.nombre ?? 'Activos',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            );
          },
        ),
        leading: const BackButton(),
      ),
      body: Consumer<ActivoViewModel>(
        builder: (context, activoVM, _) {
          if (activoVM.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

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
                    'No hay activos en este ambiente',
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
                child: InkWell(
                  onTap: () => _mostrarDetallesActivo(context, activo),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Encabezado: Nombre y Estado
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
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    activo.tipo,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildEstadoBadge(activo.estado),
                          ],
                        ),
                        const SizedBox(height: 12),
                        
                        // Detalles: Marca, Modelo, Serie
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildDetalleRow('Marca:', activo.marca),
                              const SizedBox(height: 8),
                              _buildDetalleRow('Modelo:', activo.modelo),
                              const SizedBox(height: 8),
                              _buildDetalleRow('Serie:', activo.numeroSerie),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        // UUID/Código QR
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.blue[200]!),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.qr_code_2, size: 16, color: Colors.blue[900]),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  activo.uuid,
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
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
      case 'no_esperado':
        color = Colors.purple;
        icono = Icons.warning;
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
          Icon(icono, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            estado,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetalleRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value.isEmpty ? 'No especificado' : value,
            style: TextStyle(
              fontSize: 12,
              color: value.isEmpty ? Colors.grey[500] : Colors.black,
            ),
          ),
        ),
      ],
    );
  }

  void _mostrarDetallesActivo(BuildContext context, dynamic activo) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Detalles Completos',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              
              _buildDetalleCompleto('Nombre', activo.nombre),
              _buildDetalleCompleto('Tipo', activo.tipo),
              _buildDetalleCompleto('Marca', activo.marca),
              _buildDetalleCompleto('Modelo', activo.modelo),
              _buildDetalleCompleto('Número de Serie', activo.numeroSerie),
              _buildDetalleCompleto('UUID', activo.uuid),
              _buildDetalleCompleto('Código QR', activo.qrCodigo),
              _buildDetalleCompleto('Estado', activo.estado),
              
              if (activo.observaciones != null && activo.observaciones.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Observaciones',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(activo.observaciones),
                ),
              ],
              
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  label: const Text('Cerrar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetalleCompleto(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value.isEmpty ? 'No especificado' : value,
            style: const TextStyle(fontSize: 14),
          ),
          Divider(color: Colors.grey[300]),
        ],
      ),
    );
  }
}
