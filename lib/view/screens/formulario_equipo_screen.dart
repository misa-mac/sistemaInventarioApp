import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:inventario_qr_app/models/activo_model.dart';
import 'package:inventario_qr_app/models/ambiente_model.dart';
import 'package:inventario_qr_app/repositories/activo_repository.dart';
import 'package:inventario_qr_app/viewmodel/ambiente_viewmodel.dart';

class FormularioEquipoScreen extends StatefulWidget {
  final ActivoModel? activo;

  const FormularioEquipoScreen({super.key, this.activo});

  @override
  State<FormularioEquipoScreen> createState() => _FormularioEquipoScreenState();
}

class _FormularioEquipoScreenState extends State<FormularioEquipoScreen> {
  final _formKey = GlobalKey<FormState>();
  final ActivoRepository _activoRepository = ActivoRepository();

  late TextEditingController _nombreController;
  late TextEditingController _tipoController;
  late TextEditingController _marcaController;
  late TextEditingController _modeloController;
  late TextEditingController _numeroSerieController;
  late TextEditingController _uuidController;
  late TextEditingController _qrCodigoController;
  late TextEditingController _observacionesController;

  String _estadoSeleccionado = 'activo';
  String? _ambienteSeleccionadoId;
  List<AmbienteModel> _ambientes = [];
  bool _isLoading = false;

  final List<String> _estados = ['activo', 'mantenimiento', 'baja'];

  @override
  void initState() {
    super.initState();
    _inicializarControladores();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarAmbientes();
    });
  }

  void _cargarAmbientes() async {
    if (!mounted) return;
    final ambienteVM = context.read<AmbienteViewModel>();
    await ambienteVM.cargarAmbientes();
    if (mounted) {
      setState(() {
        _ambientes = ambienteVM.ambientes;
      });
    }
  }

  void _inicializarControladores() {
    final activo = widget.activo;
    
    _nombreController = TextEditingController(text: activo?.nombre ?? '');
    _tipoController = TextEditingController(text: activo?.tipo ?? '');
    _marcaController = TextEditingController(text: activo?.marca ?? '');
    _modeloController = TextEditingController(text: activo?.modelo ?? '');
    _numeroSerieController = TextEditingController(text: activo?.numeroSerie ?? '');
    _uuidController = TextEditingController(text: activo?.uuid ?? '');
    _qrCodigoController = TextEditingController(text: activo?.qrCodigo ?? '');
    _observacionesController = TextEditingController(text: activo?.observaciones ?? '');

    _estadoSeleccionado = activo?.estado ?? 'activo';
    _ambienteSeleccionadoId = activo?.ambienteId;
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _tipoController.dispose();
    _marcaController.dispose();
    _modeloController.dispose();
    _numeroSerieController.dispose();
    _uuidController.dispose();
    _qrCodigoController.dispose();
    _observacionesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.activo == null ? 'Crear Equipo' : 'Editar Equipo'),
        leading: const BackButton(),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nombre
              _buildTextField(
                controller: _nombreController,
                label: 'Nombre del Equipo *',
                hint: 'Ej: Monitor LG 27"',
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'El nombre es requerido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Tipo
              _buildTextField(
                controller: _tipoController,
                label: 'Tipo *',
                hint: 'Ej: Monitor, CPU, Teclado, RAM',
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'El tipo es requerido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Marca
              _buildTextField(
                controller: _marcaController,
                label: 'Marca',
                hint: 'Ej: LG, Dell, Samsung',
              ),
              const SizedBox(height: 16),

              // Modelo
              _buildTextField(
                controller: _modeloController,
                label: 'Modelo',
                hint: 'Ej: 27UP550, OptiPlex 7090',
              ),
              const SizedBox(height: 16),

              // Número de Serie
              _buildTextField(
                controller: _numeroSerieController,
                label: 'Número de Serie',
                hint: 'Ej: LG-2024-001',
              ),
              const SizedBox(height: 16),

              // UUID
              _buildTextField(
                controller: _uuidController,
                label: 'UUID',
                hint: 'Ej: 150502217-24',
                readOnly: widget.activo != null,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'El UUID es requerido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Código QR
              _buildTextField(
                controller: _qrCodigoController,
                label: 'Código QR',
                hint: 'Automático si está vacío',
              ),
              const SizedBox(height: 16),

              // Estado
              _buildDropdown(
                label: 'Estado *',
                value: _estadoSeleccionado,
                items: _estados,
                onChanged: (value) {
                  setState(() {
                    _estadoSeleccionado = value!;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Ambiente
              _buildAmbienteDropdown(),
              const SizedBox(height: 16),

              // Observaciones
              _buildTextField(
                controller: _observacionesController,
                label: 'Observaciones',
                hint: 'Notas adicionales',
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              // Botones
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    label: const Text('Cancelar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _guardarEquipo,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.save),
                    label: Text(_isLoading ? 'Guardando...' : 'Guardar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
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
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          maxLines: maxLines,
          readOnly: readOnly,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            underline: const SizedBox(),
            items: items.map((String item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(item),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildAmbienteDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ambiente *',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButton<String>(
            value: _ambienteSeleccionadoId,
            isExpanded: true,
            underline: const SizedBox(),
            hint: const Text('Selecciona un ambiente'),
            items: _ambientes.map((AmbienteModel ambiente) {
              return DropdownMenuItem<String>(
                value: ambiente.id,
                child: Text(ambiente.nombre),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _ambienteSeleccionadoId = value;
              });
            },
          ),
        ),
      ],
    );
  }

  void _guardarEquipo() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_ambienteSeleccionadoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debe seleccionar un ambiente'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final nuevoActivo = ActivoModel(
        id: widget.activo?.id ?? '',
        uuid: _uuidController.text,
        nombre: _nombreController.text,
        tipo: _tipoController.text,
        marca: _marcaController.text,
        modelo: _modeloController.text,
        numeroSerie: _numeroSerieController.text,
        estado: _estadoSeleccionado,
        ambienteId: _ambienteSeleccionadoId!,
        qrCodigo: _qrCodigoController.text,
        imagenUrl: null,
        observaciones: _observacionesController.text,
      );

      bool success;
      if (widget.activo == null) {
        // Crear nuevo
        success = await _activoRepository.crearActivo(nuevoActivo);
      } else {
        // Actualizar
        success = await _activoRepository.actualizarActivo(nuevoActivo);
      }

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.activo == null
                  ? '✅ Equipo creado'
                  : '✅ Equipo actualizado',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Error guardando equipo'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
