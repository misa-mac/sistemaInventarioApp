import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:inventario_qr_app/viewmodel/auth_viewmodel.dart';

class PerfilScreen extends StatelessWidget {
  const PerfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Información del usuario
            Consumer<AuthViewModel>(
              builder: (context, authVM, _) {
                final usuario = authVM.usuario;
                
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
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.blue[900],
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: const Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    usuario?.nombreCompleto ?? 'Usuario',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  Text(
                                    usuario?.email ?? 'email@example.com',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue[900]!),
                          ),
                          child: Text(
                            'Rol: ${usuario?.rol.toUpperCase() ?? 'TECNICO'}',
                            style: TextStyle(
                              color: Colors.blue[900],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),

            // Permisos y capacidades
            Text(
              'Capacidades según tu Rol',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            Consumer<AuthViewModel>(
              builder: (context, authVM, _) {
                final rol = authVM.usuario?.rol ?? 'tecnico';
                
                return Column(
                  children: [
                    _buildCapacidadCard(
                      icono: Icons.checklist,
                      titulo: 'Auditorías',
                      descripcion: 'Realizar auditorías completas de equipos',
                      habilitado: _puedeAuditar(rol),
                    ),
                    const SizedBox(height: 12),
                    _buildCapacidadCard(
                      icono: Icons.qr_code_2,
                      titulo: 'Escaneo Simple',
                      descripcion: 'Escanear QR para ver información',
                      habilitado: true,
                    ),
                    const SizedBox(height: 12),
                    _buildCapacidadCard(
                      icono: Icons.swap_horiz,
                      titulo: 'Registrar Movimientos',
                      descripcion: 'Registrar traslados de equipos',
                      habilitado: _puedeMovimientos(rol),
                    ),
                    const SizedBox(height: 12),
                    _buildCapacidadCard(
                      icono: Icons.add_circle,
                      titulo: 'Crear Equipos',
                      descripcion: 'Registrar nuevos equipos en la BD',
                      habilitado: _puedeCrear(rol),
                    ),
                    const SizedBox(height: 12),
                    _buildCapacidadCard(
                      icono: Icons.assignment,
                      titulo: 'Ver Reportes',
                      descripcion: 'Acceso a reportes y estadísticas',
                      habilitado: true,
                    ),
                    const SizedBox(height: 12),
                    _buildCapacidadCard(
                      icono: Icons.admin_panel_settings,
                      titulo: 'Administrador',
                      descripcion: 'Control total del sistema',
                      habilitado: _esAdmin(rol),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 32),

            // Botón cerrar sesión
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _handleLogout(context),
                icon: const Icon(Icons.logout),
                label: const Text('Cerrar Sesión'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCapacidadCard({
    required IconData icono,
    required String titulo,
    required String descripcion,
    required bool habilitado,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: habilitado ? Colors.green[50] : Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: habilitado ? Colors.green : Colors.grey[300]!,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icono,
            color: habilitado ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: habilitado ? Colors.green[900] : Colors.grey[700],
                  ),
                ),
                Text(
                  descripcion,
                  style: TextStyle(
                    fontSize: 12,
                    color: habilitado ? Colors.green[800] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Icon(
            habilitado ? Icons.check_circle : Icons.lock,
            color: habilitado ? Colors.green : Colors.grey,
          ),
        ],
      ),
    );
  }

  bool _puedeAuditar(String rol) => rol == 'administrador' || rol == 'auditor';
  bool _puedeMovimientos(String rol) => rol != 'auditor';
  bool _puedeCrear(String rol) => rol == 'administrador';
  bool _esAdmin(String rol) => rol == 'administrador';

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de cerrar sesión?'),
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
