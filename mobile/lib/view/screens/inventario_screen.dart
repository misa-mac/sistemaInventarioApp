import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:inventario_qr_app/core/theme/app_theme.dart';
import 'package:inventario_qr_app/viewmodel/ambiente_viewmodel.dart';
import 'package:inventario_qr_app/viewmodel/activo_viewmodel.dart';
import 'package:inventario_qr_app/viewmodel/auth_viewmodel.dart';
import 'package:inventario_qr_app/models/ambiente_model.dart';
import 'package:inventario_qr_app/view/widgets/error_state.dart';
import 'package:inventario_qr_app/view/widgets/floating_bottom_nav_bar.dart';

class InventarioScreen extends StatefulWidget {
  const InventarioScreen({super.key});

  @override
  State<InventarioScreen> createState() => _InventarioScreenState();
}

class _InventarioScreenState extends State<InventarioScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AmbienteViewModel>().cargarAmbientes();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  IconData _getIconForAmbiente(String nombre, String descripcion) {
    final text = '${nombre.toLowerCase()} ${descripcion.toLowerCase()}';
    if (text.contains('lab') || text.contains('comput') || text.contains('sistem')) {
      return Icons.computer_rounded;
    } else if (text.contains('taller') || text.contains('mecanic') || text.contains('electr')) {
      return Icons.build_rounded;
    } else if (text.contains('oficina') || text.contains('admin') || text.contains('direcc')) {
      return Icons.business_center_rounded;
    } else if (text.contains('deposito') || text.contains('depósito') || text.contains('almacen') || text.contains('bodega')) {
      return Icons.inventory_2_rounded;
    }
    return Icons.meeting_room_rounded;
  }

  String _getAmbienteTypeLabel(String nombre, String descripcion) {
    final text = '${nombre.toLowerCase()} ${descripcion.toLowerCase()}';
    if (text.contains('lab') || text.contains('comput') || text.contains('sistem')) {
      return 'Laboratorio';
    } else if (text.contains('taller') || text.contains('mecanic') || text.contains('electr')) {
      return 'Taller';
    } else if (text.contains('oficina') || text.contains('admin') || text.contains('direcc')) {
      return 'Oficina';
    } else if (text.contains('deposito') || text.contains('depósito') || text.contains('almacen') || text.contains('bodega')) {
      return 'Depósito';
    }
    return 'Ambiente';
  }

  void _selectAmbiente(BuildContext context, AmbienteViewModel ambienteVM, AmbienteModel ambiente) async {
    await ambienteVM.seleccionarAmbiente(ambiente);
    if (!context.mounted) return;

    await context.read<ActivoViewModel>().cargarActivosPorAmbiente(ambiente.id);
    if (!context.mounted) return;

    Navigator.of(context).pushNamed('/activos-detalle');
  }

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<AuthViewModel>().usuario;
    final nombre = usuario?.nombreCompleto ?? 'Usuario';
    final rol = (usuario?.rol ?? 'tecnico').toUpperCase();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Cabecera con saludo, nombre y etiqueta de rol (sin flecha de retroceso)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      color: AppColors.primary,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hola, $nombre',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Ambientes e Inventario',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            color: AppColors.iconInactive,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Etiqueta de Rol (alto contraste)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.brandBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.brandBlue.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Text(
                      rol,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        color: AppColors.brandBlue,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 2. Buscador de ambientes
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: TextField(
                controller: _searchController,
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val.trim().toLowerCase();
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Buscar ambiente o laboratorio...',
                  hintStyle: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    color: AppColors.iconInactive,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppColors.brandBlue,
                    size: 22,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 20),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.brandBlue, width: 1.5),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // 3. Lista de Ambientes con scroll independiente y reserva de espacio inferior
            Expanded(
              child: Consumer<AmbienteViewModel>(
                builder: (context, ambienteVM, _) {
                  if (ambienteVM.isLoading) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(strokeWidth: 2.5),
                          SizedBox(height: 12),
                          Text(
                            'Cargando ambientes...',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              color: AppColors.iconInactive,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (ambienteVM.ambientes.isEmpty) {
                    return ErrorState(
                      icon: Icons.domain_disabled_rounded,
                      titulo: 'No hay ambientes disponibles',
                      error: ambienteVM.error,
                      onRetry: () => ambienteVM.cargarAmbientes(),
                    );
                  }

                  // Filtrado por buscador
                  final filteredAmbientes = ambienteVM.ambientes.where((ambiente) {
                    if (_searchQuery.isEmpty) return true;
                    final query = _searchQuery;
                    return ambiente.nombre.toLowerCase().contains(query) ||
                        ambiente.descripcion.toLowerCase().contains(query);
                  }).toList();

                  if (filteredAmbientes.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.search_off_rounded,
                              size: 48,
                              color: AppColors.iconInactive,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No se encontraron ambientes para "$_searchQuery"',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                color: AppColors.iconInactive,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final bottomInset = FloatingBottomNavBar.totalOccupiedHeight(context);

                  return RefreshIndicator(
                    onRefresh: () => ambienteVM.cargarAmbientes(),
                    child: ListView.builder(
                      padding: EdgeInsets.fromLTRB(16, 8, 16, bottomInset + 24),
                      itemCount: filteredAmbientes.length,
                      itemBuilder: (context, index) {
                        final ambiente = filteredAmbientes[index];
                        final icon = _getIconForAmbiente(ambiente.nombre, ambiente.descripcion);
                        final typeLabel = _getAmbienteTypeLabel(ambiente.nombre, ambiente.descripcion);

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 1.5,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: const BorderSide(color: AppColors.border, width: 0.8),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => _selectAmbiente(context, ambienteVM, ambiente),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Ícono según tipo
                                  Container(
                                    width: 46,
                                    height: 46,
                                    decoration: BoxDecoration(
                                      color: AppColors.brandBlue.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      icon,
                                      color: AppColors.brandBlue,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 14),

                                  // Nombre, subtítulo y chips de estado
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                ambiente.nombre,
                                                style: const TextStyle(
                                                  fontFamily: 'Poppins',
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                  color: AppColors.textPrimary,
                                                ),
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 6,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: AppColors.surfaceVariant,
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                typeLabel,
                                                style: const TextStyle(
                                                  fontFamily: 'Poppins',
                                                  fontSize: 10,
                                                  color: AppColors.textSecondary,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          ambiente.descripcion.isNotEmpty
                                              ? ambiente.descripcion
                                              : 'Sin descripción adicional',
                                          style: const TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),

                                        // Chip "Sin internet" si ambiente.tieneInternet == false
                                        if (!ambiente.tieneInternet) ...[
                                          const SizedBox(height: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.statusAmberBg,
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(
                                                color: AppColors.statusAmber.withValues(alpha: 0.4),
                                              ),
                                            ),
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.wifi_off_rounded,
                                                  size: 13,
                                                  color: AppColors.statusAmberText,
                                                ),
                                                SizedBox(width: 4),
                                                Text(
                                                  'Sin internet',
                                                  style: TextStyle(
                                                    fontFamily: 'Poppins',
                                                    color: AppColors.statusAmberText,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),

                                  const SizedBox(width: 8),
                                  const Padding(
                                    padding: EdgeInsets.only(top: 10),
                                    child: Icon(
                                      Icons.chevron_right_rounded,
                                      color: AppColors.iconInactive,
                                      size: 22,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
