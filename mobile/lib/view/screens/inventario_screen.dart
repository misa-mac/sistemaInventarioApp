import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:inventario_qr_app/core/theme/app_theme.dart';
import 'package:inventario_qr_app/viewmodel/ambiente_viewmodel.dart';
import 'package:inventario_qr_app/viewmodel/activo_viewmodel.dart';
import 'package:inventario_qr_app/viewmodel/auth_viewmodel.dart';
import 'package:inventario_qr_app/models/ambiente_model.dart';
import 'package:inventario_qr_app/models/activo_model.dart';
import 'package:inventario_qr_app/core/constants/api_constants.dart';
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
  String _searchFilter = 'todos'; // 'todos' | 'ambientes' | 'activos'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AmbienteViewModel>().cargarAmbientes();
        context.read<ActivoViewModel>().cargarTodosLosActivos();
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

  String? _resolveImageUrl(String? url) {
    if (url == null || url.trim().isEmpty) return null;
    final trimmed = url.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    final base = ApiConstants.baseUrl.replaceAll('/api', '');
    final cleanPath = trimmed.startsWith('/') ? trimmed : '/$trimmed';
    return '$base$cleanPath';
  }

  Widget _buildEstadoChip(String estado) {
    Color bg = AppColors.statusGreenBg;
    Color textColor = AppColors.statusGreenText;
    IconData icon = Icons.check_circle_rounded;

    final lower = estado.toLowerCase();
    if (lower.contains('manten') || lower.contains('esperado')) {
      bg = AppColors.statusAmberBg;
      textColor = AppColors.statusAmberText;
      icon = Icons.warning_rounded;
    } else if (lower.contains('baja') || lower.contains('dañado') || lower.contains('inactivo')) {
      bg = AppColors.statusRedBg;
      textColor = AppColors.statusRedText;
      icon = Icons.cancel_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: textColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 4),
          Text(
            estado.toUpperCase(),
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: textColor,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarFichaTecnica(BuildContext context, ActivoModel activo, AmbienteViewModel ambienteVM) {
    final imageUrl = _resolveImageUrl(activo.imagenUrl);
    final ambienteNombre = activo.ambienteNombre?.isNotEmpty == true
        ? activo.ambienteNombre!
        : 'Ambiente no especificado';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SafeArea(
          child: Column(
            children: [
              // Barra de arrastre superior
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),

              // Encabezado protegido contra overflow
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 12, 12),
                child: Row(
                  children: [
                    const Icon(Icons.inventory_2_rounded, color: AppColors.brandBlue, size: 22),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Ficha Técnica del Activo',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildEstadoChip(activo.estado),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 22, color: AppColors.iconInactive),
                      onPressed: () => Navigator.pop(ctx),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Cerrar',
                    ),
                  ],
                ),
              ),

              const Divider(height: 1, color: AppColors.border),

              // Contenido scrolleable
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  children: [
                    if (imageUrl != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          height: 180,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: Colors.grey[100],
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.broken_image_rounded, size: 40, color: AppColors.iconInactive),
                                  SizedBox(height: 6),
                                  Text(
                                    'Imagen no disponible',
                                    style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AppColors.iconInactive),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Banner de Identificación Principal
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primaryNavy.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.primaryNavy.withValues(alpha: 0.12)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activo.nombre,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: AppColors.brandBlue.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.brandBlue.withValues(alpha: 0.25)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.qr_code_2_rounded, size: 16, color: AppColors.brandBlue),
                                    const SizedBox(width: 6),
                                    Text(
                                      activo.qrCodigo.isNotEmpty ? activo.qrCodigo : activo.uuid,
                                      style: const TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.brandBlue,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (activo.numeroCorrelativo != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Nº #${activo.numeroCorrelativo.toString().padLeft(2, '0')}',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                ),
                              if (activo.tipo.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.blueGrey[50],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    activo.tipo,
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Tabla de Especificaciones Técnicas
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.tune_rounded, size: 18, color: AppColors.brandBlue),
                              SizedBox(width: 8),
                              Text(
                                'Especificaciones Técnicas',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 20, color: AppColors.border),
                          _buildModalRow('Marca', activo.marca),
                          const Divider(height: 16, color: AppColors.border),
                          _buildModalRow('Modelo', activo.modelo),
                          const Divider(height: 16, color: AppColors.border),
                          _buildModalRow('Número de Serie', activo.numeroSerie, isMonospace: true),
                          const Divider(height: 16, color: AppColors.border),
                          _buildModalRow('Ambiente Actual', ambienteNombre, isHighlight: true),
                          if (activo.ambienteUbicacion != null && activo.ambienteUbicacion!.isNotEmpty) ...[
                            const Divider(height: 16, color: AppColors.border),
                            _buildModalRow('Ubicación Física', activo.ambienteUbicacion!),
                          ],
                          if (activo.responsable != null && activo.responsable!.isNotEmpty) ...[
                            const Divider(height: 16, color: AppColors.border),
                            _buildModalRow('Responsable', activo.responsable!),
                          ],
                          if (activo.origen != null && activo.origen!.isNotEmpty) ...[
                            const Divider(height: 16, color: AppColors.border),
                            _buildModalRow('Origen', activo.origen!),
                          ],
                          if (activo.fechaIngreso != null && activo.fechaIngreso!.isNotEmpty) ...[
                            const Divider(height: 16, color: AppColors.border),
                            _buildModalRow('Fecha de Ingreso', activo.fechaIngreso!),
                          ],
                          if (activo.valor != null) ...[
                            const Divider(height: 16, color: AppColors.border),
                            _buildModalRow('Valor Estimado', 'Bs. ${activo.valor!.toStringAsFixed(2)}'),
                          ],
                          if (activo.descripcion != null && activo.descripcion!.isNotEmpty) ...[
                            const Divider(height: 16, color: AppColors.border),
                            _buildModalRow('Descripción', activo.descripcion!),
                          ],
                          const Divider(height: 16, color: AppColors.border),
                          _buildModalRow('UUID Sistema', activo.uuid, isMonospace: true),
                        ],
                      ),
                    ),

                    if (activo.observaciones != null && activo.observaciones!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.notes_rounded, size: 16, color: AppColors.textSecondary),
                                SizedBox(width: 6),
                                Text(
                                  'Observaciones',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              activo.observaciones!,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 13,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Botones de acción
                    Row(
                      children: [
                        // Botón para ir al ambiente correspondiente
                        if (activo.ambienteId.isNotEmpty)
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.pop(ctx);
                                final amb = ambienteVM.ambientes.firstWhere(
                                  (a) => a.id == activo.ambienteId,
                                  orElse: () => AmbienteModel(
                                    id: activo.ambienteId,
                                    nombre: ambienteNombre,
                                    descripcion: '',
                                    tieneInternet: true,
                                    latitude: 0.0,
                                    longitude: 0.0,
                                    radioGeofence: 50.0,
                                  ),
                                );
                                _selectAmbiente(context, ambienteVM, amb);
                              },
                              icon: const Icon(Icons.meeting_room_outlined, size: 18),
                              label: const Text(
                                'Ver en Ambiente',
                                style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.brandBlue,
                                side: const BorderSide(color: AppColors.brandBlue),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        if (activo.ambienteId.isNotEmpty) const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(ctx),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryNavy,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text(
                              'Cerrar',
                              style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModalRow(String label, String value, {bool isHighlight = false, bool isMonospace = false}) {
    final displayValue = value.trim().isNotEmpty ? value.trim() : 'No especificado';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            displayValue,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontFamily: isMonospace ? 'monospace' : 'Poppins',
              fontSize: isMonospace ? 12 : 13,
              color: isHighlight ? AppColors.brandBlue : AppColors.textPrimary,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActivoCard(BuildContext context, ActivoModel activo, AmbienteViewModel ambienteVM) {
    final codigo = activo.qrCodigo.isNotEmpty
        ? activo.qrCodigo
        : (activo.uuid.length > 8 ? activo.uuid.substring(0, 8) : activo.uuid);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border, width: 0.8),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _mostrarFichaTecnica(context, activo, ambienteVM),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fila de Código + Estado
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.brandBlue.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.qr_code_2_rounded,
                          size: 14,
                          color: AppColors.brandBlue,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          codigo,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.brandBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  _buildEstadoChip(activo.estado),
                ],
              ),
              const SizedBox(height: 10),

              // Nombre del Activo
              Text(
                activo.nombre,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),

              // Especificaciones: Modelo / Serie
              Row(
                children: [
                  if (activo.modelo.isNotEmpty) ...[
                    const Icon(Icons.devices_outlined, size: 14, color: AppColors.iconInactive),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        activo.modelo,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  if (activo.numeroSerie.isNotEmpty) ...[
                    const Icon(Icons.tag_rounded, size: 14, color: AppColors.iconInactive),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        activo.numeroSerie,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),

              // Ubicación / Ambiente del Activo
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 14, color: AppColors.brandBlue),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        activo.ambienteNombre?.isNotEmpty == true
                            ? activo.ambienteNombre!
                            : 'Ambiente no especificado',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: AppColors.iconInactive,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.brandBlue.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 34,
                color: AppColors.brandBlue,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'No se encontraron resultados para "$_searchQuery"',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Prueba buscando por nombre de ambiente, modelo, marca o código de activo.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
              icon: const Icon(Icons.clear_rounded, size: 16),
              label: const Text(
                'Limpiar búsqueda',
                style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.brandBlue,
                side: const BorderSide(color: AppColors.brandBlue),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<AuthViewModel>().usuario;
    final nombre = usuario?.nombreCompleto ?? 'Usuario';
    final rol = (usuario?.rol ?? 'tecnico').toUpperCase();

    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    final bottomInset = isKeyboardOpen
        ? 16.0
        : (FloatingBottomNavBar.totalOccupiedHeight(context) + 24.0);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Cabecera con saludo, nombre y etiqueta de rol
            // Se compacta automáticamente cuando el teclado está abierto o hay búsqueda activa para no perder espacio
            Padding(
              padding: EdgeInsets.fromLTRB(20, isKeyboardOpen ? 8 : 16, 20, isKeyboardOpen ? 6 : 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: isKeyboardOpen ? 36 : 44,
                    height: isKeyboardOpen ? 36 : 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.person_rounded,
                      color: AppColors.primary,
                      size: isKeyboardOpen ? 20 : 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hola, $nombre',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: isKeyboardOpen ? 15 : 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (!isKeyboardOpen) ...[
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
                      ],
                    ),
                  ),
                  // Etiqueta de Rol
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

            // 2. Buscador unificado (Ambientes + Activos + Códigos)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: TextField(
                controller: _searchController,
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val.trim().toLowerCase();
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Buscar ambiente, activo o código...',
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

            // 3. Pestañas de filtrado cuando se busca
            if (_searchQuery.isNotEmpty)
              Consumer2<AmbienteViewModel, ActivoViewModel>(
                builder: (context, ambienteVM, activoVM, _) {
                  final q = _searchQuery;
                  final countAmb = ambienteVM.ambientes.where((a) =>
                      a.nombre.toLowerCase().contains(q) ||
                      a.descripcion.toLowerCase().contains(q)).length;

                  final countAct = activoVM.todosLosActivos.where((act) =>
                      act.nombre.toLowerCase().contains(q) ||
                      act.qrCodigo.toLowerCase().contains(q) ||
                      act.uuid.toLowerCase().contains(q) ||
                      act.numeroSerie.toLowerCase().contains(q) ||
                      act.modelo.toLowerCase().contains(q) ||
                      act.marca.toLowerCase().contains(q) ||
                      act.tipo.toLowerCase().contains(q) ||
                      (act.ambienteNombre != null && act.ambienteNombre!.toLowerCase().contains(q))).length;

                  return Padding(
                    padding: const EdgeInsets.fromLTRB(20, 6, 20, 4),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip('todos', 'Todos (${countAmb + countAct})'),
                          const SizedBox(width: 8),
                          _buildFilterChip('ambientes', 'Ambientes ($countAmb)'),
                          const SizedBox(width: 8),
                          _buildFilterChip('activos', 'Equipos ($countAct)'),
                        ],
                      ),
                    ),
                  );
                },
              ),

            const SizedBox(height: 6),

            // 4. Lista de Resultados o Ambientes con scroll independiente
            Expanded(
              child: Consumer2<AmbienteViewModel, ActivoViewModel>(
                builder: (context, ambienteVM, activoVM, _) {
                  if (ambienteVM.isLoading) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(strokeWidth: 2.5),
                          SizedBox(height: 12),
                          Text(
                            'Cargando inventario...',
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

                  if (ambienteVM.ambientes.isEmpty && activoVM.todosLosActivos.isEmpty) {
                    return ErrorState(
                      icon: Icons.domain_disabled_rounded,
                      titulo: 'No hay ambientes disponibles',
                      error: ambienteVM.error,
                      onRetry: () {
                        ambienteVM.cargarAmbientes();
                        activoVM.cargarTodosLosActivos();
                      },
                    );
                  }

                  // 4.1 Búsqueda activa
                  if (_searchQuery.isNotEmpty) {
                    final q = _searchQuery;
                    final filteredAmbientes = ambienteVM.ambientes.where((ambiente) {
                      return ambiente.nombre.toLowerCase().contains(q) ||
                          ambiente.descripcion.toLowerCase().contains(q);
                    }).toList();

                    final filteredActivos = activoVM.todosLosActivos.where((activo) {
                      return activo.nombre.toLowerCase().contains(q) ||
                          activo.qrCodigo.toLowerCase().contains(q) ||
                          activo.uuid.toLowerCase().contains(q) ||
                          activo.numeroSerie.toLowerCase().contains(q) ||
                          activo.modelo.toLowerCase().contains(q) ||
                          activo.marca.toLowerCase().contains(q) ||
                          activo.tipo.toLowerCase().contains(q) ||
                          (activo.ambienteNombre != null && activo.ambienteNombre!.toLowerCase().contains(q));
                    }).toList();

                    final bool showAmbientes = _searchFilter == 'todos' || _searchFilter == 'ambientes';
                    final bool showActivos = _searchFilter == 'todos' || _searchFilter == 'activos';

                    final totalCount = (showAmbientes ? filteredAmbientes.length : 0) +
                        (showActivos ? filteredActivos.length : 0);

                    if (totalCount == 0) {
                      return _buildEmptyState();
                    }

                    return ListView(
                      padding: EdgeInsets.fromLTRB(16, 4, 16, bottomInset),
                      children: [
                        // Sección de Ambientes
                        if (showAmbientes && filteredAmbientes.isNotEmpty) ...[
                          _buildSectionHeader('Ambientes / Laboratorios', filteredAmbientes.length, Icons.meeting_room_outlined),
                          ...filteredAmbientes.map((ambiente) => _buildAmbienteCard(context, ambienteVM, ambiente)),
                          const SizedBox(height: 12),
                        ],

                        // Sección de Activos / Equipos
                        if (showActivos && filteredActivos.isNotEmpty) ...[
                          _buildSectionHeader('Equipos y Activos', filteredActivos.length, Icons.inventory_2_outlined),
                          ...filteredActivos.map((activo) => _buildActivoCard(context, activo, ambienteVM)),
                        ],
                      ],
                    );
                  }

                  // 4.2 Vista estándar: Lista de todos los ambientes
                  return RefreshIndicator(
                    onRefresh: () async {
                      await Future.wait([
                        ambienteVM.cargarAmbientes(),
                        activoVM.cargarTodosLosActivos(),
                      ]);
                    },
                    child: ListView.builder(
                      padding: EdgeInsets.fromLTRB(16, 4, 16, bottomInset),
                      itemCount: ambienteVM.ambientes.length,
                      itemBuilder: (context, index) {
                        final ambiente = ambienteVM.ambientes[index];
                        return _buildAmbienteCard(context, ambienteVM, ambiente);
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

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _searchFilter == key;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        setState(() {
          _searchFilter = key;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.brandBlue : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.brandBlue : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.brandBlue),
          const SizedBox(width: 6),
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: AppColors.brandBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.brandBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmbienteCard(BuildContext context, AmbienteViewModel ambienteVM, AmbienteModel ambiente) {
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
  }
}
