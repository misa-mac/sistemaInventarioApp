import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:inventario_qr_app/models/activo_model.dart';
import 'package:inventario_qr_app/models/ambiente_model.dart';
import 'package:inventario_qr_app/models/tipo_activo_model.dart';
import 'package:inventario_qr_app/repositories/tipo_activo_repository.dart';
import 'package:inventario_qr_app/viewmodel/ambiente_viewmodel.dart';
import 'package:inventario_qr_app/viewmodel/solicitud_viewmodel.dart';
import 'package:inventario_qr_app/core/theme/app_theme.dart';

class FormularioEquipoScreen extends StatefulWidget {
  final ActivoModel? activo;

  const FormularioEquipoScreen({super.key, this.activo});

  @override
  State<FormularioEquipoScreen> createState() => _FormularioEquipoScreenState();
}

class _FormularioEquipoScreenState extends State<FormularioEquipoScreen> {
  final _formKey = GlobalKey<FormState>();
  final TipoActivoRepository _tipoActivoRepo = TipoActivoRepository();

  late TextEditingController _nombreController;
  late TextEditingController _marcaController;
  late TextEditingController _modeloController;
  late TextEditingController _numeroSerieController;
  late TextEditingController _origenController;
  late TextEditingController _especificacionOrigenController;
  late TextEditingController _descripcionController;
  late TextEditingController _responsableController;
  late TextEditingController _valorController;
  late TextEditingController _observacionesController;

  String _estadoSeleccionado = 'Activo';
  String? _tipoActivoSeleccionadoId;
  String? _ambienteSeleccionadoId;

  List<AmbienteModel> _ambientes = [];
  List<TipoActivoModel> _tiposActivos = [];
  bool _cargandoCatalogos = true;
  bool _isSubmitting = false;

  final List<String> _estados = ['Activo', 'Dañado', 'Inactivo'];

  bool get esEdicion => widget.activo != null;

  @override
  void initState() {
    super.initState();
    _inicializarControladores();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarCatalogos();
    });
  }

  void _inicializarControladores() {
    final activo = widget.activo;

    _nombreController = TextEditingController(text: activo?.nombre ?? '');
    _marcaController = TextEditingController(text: activo?.marca ?? '');
    _modeloController = TextEditingController(text: activo?.modelo ?? '');
    _numeroSerieController = TextEditingController(text: activo?.numeroSerie ?? '');
    _origenController = TextEditingController();
    _especificacionOrigenController = TextEditingController();
    _descripcionController = TextEditingController();
    _responsableController = TextEditingController();
    _valorController = TextEditingController();
    _observacionesController = TextEditingController(text: activo?.observaciones ?? '');

    _estadoSeleccionado = (activo?.estado != null && _estados.contains(activo!.estado))
        ? activo.estado
        : 'Activo';
    _ambienteSeleccionadoId = activo?.ambienteId;
  }

  Future<void> _cargarCatalogos() async {
    setState(() => _cargandoCatalogos = true);

    // 1. Cargar Ambientes
    try {
      final ambienteVM = context.read<AmbienteViewModel>();
      await ambienteVM.cargarAmbientes();
      _ambientes = ambienteVM.ambientes;
    } catch (e) {
      debugPrint('Error cargando ambientes: $e');
    }

    // 2. Cargar Tipos de Activos (API + caché SQLite + fallback oficial)
    try {
      _tiposActivos = await _tipoActivoRepo.getTiposActivos();
    } catch (e) {
      debugPrint('Error cargando tipos de activos: $e');
      _tiposActivos = TipoActivoRepository.catalogoOficial;
    }

    // 3. Selecciones iniciales seguras para Alta
    if (!esEdicion) {
      if (_tiposActivos.isNotEmpty && (_tipoActivoSeleccionadoId == null || !_tiposActivos.any((t) => t.id == _tipoActivoSeleccionadoId))) {
        _tipoActivoSeleccionadoId = _tiposActivos.first.id;
      }
      if (_ambientes.isNotEmpty && (_ambienteSeleccionadoId == null || !_ambientes.any((a) => a.id == _ambienteSeleccionadoId))) {
        _ambienteSeleccionadoId = _ambientes.first.id;
      }
    }

    if (mounted) {
      setState(() => _cargandoCatalogos = false);
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _marcaController.dispose();
    _modeloController.dispose();
    _numeroSerieController.dispose();
    _origenController.dispose();
    _especificacionOrigenController.dispose();
    _descripcionController.dispose();
    _responsableController.dispose();
    _valorController.dispose();
    _observacionesController.dispose();
    super.dispose();
  }

  Future<void> _enviarSolicitud() async {
    if (!_formKey.currentState!.validate()) return;

    if (!esEdicion) {
      if (_tipoActivoSeleccionadoId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Debe seleccionar un tipo de activo.')),
        );
        return;
      }
      if (_ambienteSeleccionadoId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Debe seleccionar un ambiente de registro.')),
        );
        return;
      }
    }

    setState(() => _isSubmitting = true);

    final solicitudVM = context.read<SolicitudViewModel>();
    bool exitoso = false;

    if (!esEdicion) {
      // SOLICITAR ALTA
      final datosAlta = <String, dynamic>{
        'nombre': _nombreController.text.trim(),
        'tipo_activo_id': _tipoActivoSeleccionadoId,
        'ambiente_id': _ambienteSeleccionadoId,
        'ambiente_registro_id': _ambienteSeleccionadoId,
        'marca': _marcaController.text.trim(),
        'modelo': _modeloController.text.trim(),
        'numero_serie': _numeroSerieController.text.trim(),
        'origen': _origenController.text.trim().isEmpty ? null : _origenController.text.trim(),
        'especificacion_origen': _especificacionOrigenController.text.trim().isEmpty ? null : _especificacionOrigenController.text.trim(),
        'descripcion': _descripcionController.text.trim().isEmpty ? null : _descripcionController.text.trim(),
        'responsable': _responsableController.text.trim().isEmpty ? null : _responsableController.text.trim(),
        'valor': double.tryParse(_valorController.text.trim()) ?? 0.0,
        'estado': _estadoSeleccionado,
        'observaciones': _observacionesController.text.trim().isEmpty ? null : _observacionesController.text.trim(),
      };

      exitoso = await solicitudVM.solicitarAlta(datos: datosAlta);
    } else {
      // SOLICITAR EDICIÓN (solo campos permitidos)
      final datosEdicion = <String, dynamic>{
        'nombre': _nombreController.text.trim(),
        'marca': _marcaController.text.trim(),
        'modelo': _modeloController.text.trim(),
        'numero_serie': _numeroSerieController.text.trim(),
        'origen': _origenController.text.trim().isEmpty ? null : _origenController.text.trim(),
        'especificacion_origen': _especificacionOrigenController.text.trim().isEmpty ? null : _especificacionOrigenController.text.trim(),
        'descripcion': _descripcionController.text.trim().isEmpty ? null : _descripcionController.text.trim(),
        'responsable': _responsableController.text.trim().isEmpty ? null : _responsableController.text.trim(),
        'valor': double.tryParse(_valorController.text.trim()) ?? 0.0,
        'estado': _estadoSeleccionado,
        'observaciones': _observacionesController.text.trim().isEmpty ? null : _observacionesController.text.trim(),
      };

      exitoso = await solicitudVM.solicitarEdicion(
        activoId: widget.activo!.id.isNotEmpty ? widget.activo!.id : widget.activo!.uuid,
        datos: datosEdicion,
      );
    }

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (exitoso) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            esEdicion
                ? 'Solicitud de edición enviada. Se confirmará en la web.'
                : 'Solicitud de alta enviada. Se confirmará en la web.',
          ),
          backgroundColor: Colors.green[700],
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(solicitudVM.errorMessage ?? 'Error al registrar la solicitud.'),
          backgroundColor: Colors.red[700],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = esEdicion ? 'Solicitar Edición' : 'Solicitar Alta de Equipo';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: const BackButton(),
      ),
      body: _cargandoCatalogos
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // AVISO DE AUTORIDAD Y CÓDIGO
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              esEdicion
                                  ? 'Propuesta de edición para el activo ${widget.activo?.qrCodigo ?? ""}. El código y el ambiente son inmutables; los cambios serán confirmados por un administrador en la web.'
                                  : 'El código se asigna al aprobar en la web. La aplicación móvil solo propone el registro; el código oficial XYZAACC-GG y QR son generados por la base de datos al confirmar.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue[900],
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Tipo de Activo (Solo en Alta)
                    if (!esEdicion) ...[
                      const Text(
                        'Tipo de Activo *',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        key: ValueKey('tipo_${_tipoActivoSeleccionadoId}_${_tiposActivos.length}'),
                        initialValue: (_tiposActivos.any((t) => t.id == _tipoActivoSeleccionadoId))
                            ? _tipoActivoSeleccionadoId
                            : null,
                        hint: const Text('Seleccione tipo de activo'),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        items: _tiposActivos.map((tipo) {
                          return DropdownMenuItem<String>(
                            value: tipo.id,
                            child: Text('${tipo.nombre} (Cód: ${tipo.codigo.toString().padLeft(2, '0')})'),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() => _tipoActivoSeleccionadoId = val);
                        },
                        validator: (v) => v == null ? 'Seleccione un tipo' : null,
                      ),
                      const SizedBox(height: 16),

                      // Ambiente de Registro (Solo en Alta)
                      const Text(
                        'Ambiente de Registro *',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        key: ValueKey('amb_${_ambienteSeleccionadoId}_${_ambientes.length}'),
                        initialValue: (_ambientes.any((a) => a.id == _ambienteSeleccionadoId))
                            ? _ambienteSeleccionadoId
                            : null,
                        hint: const Text('Seleccione ambiente de registro'),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        items: _ambientes.map((amb) {
                          return DropdownMenuItem<String>(
                            value: amb.id,
                            child: Text(amb.nombre),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() => _ambienteSeleccionadoId = val);
                        },
                        validator: (v) => v == null ? 'Seleccione un ambiente' : null,
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Nombre del Equipo
                    _buildTextField(
                      controller: _nombreController,
                      label: 'Nombre / Denominación *',
                      hint: 'Ej: Computadora HP Pavilion, Monitor Dell',
                      validator: (value) {
                        if (value?.trim().isEmpty ?? true) {
                          return 'El nombre es obligatorio';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Marca y Modelo en fila
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _marcaController,
                            label: 'Marca',
                            hint: 'Ej: HP, Dell, LG',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(
                            controller: _modeloController,
                            label: 'Modelo',
                            hint: 'Ej: OptiPlex 7090',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Número de Serie
                    _buildTextField(
                      controller: _numeroSerieController,
                      label: 'Número de Serie',
                      hint: 'Ej: SN-48921829',
                    ),
                    const SizedBox(height: 16),

                    // Responsable y Valor
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _responsableController,
                            label: 'Responsable',
                            hint: 'Ej: Juan Pérez',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(
                            controller: _valorController,
                            label: 'Valor Estimado (Bs.)',
                            hint: '0.00',
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Estado
                    const Text(
                      'Estado del Activo *',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: _estadoSeleccionado,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      items: _estados.map((est) {
                        return DropdownMenuItem<String>(
                          value: est,
                          child: Text(est),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _estadoSeleccionado = val);
                      },
                    ),
                    const SizedBox(height: 16),

                    // Observaciones
                    _buildTextField(
                      controller: _observacionesController,
                      label: 'Observaciones / Notas',
                      hint: 'Detalles sobre el estado o procedencia...',
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),

                    // Botón de Enviar Solicitud
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _isSubmitting ? null : _enviarSolicitud,
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.send),
                        label: Text(
                          _isSubmitting
                              ? 'Enviando...'
                              : (esEdicion ? 'Enviar Solicitud de Edición' : 'Enviar Solicitud de Alta'),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    String? Function(String?)? validator,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ],
    );
  }
}
