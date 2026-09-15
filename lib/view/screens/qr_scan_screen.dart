import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:inventario_qr_app/viewmodel/auditoria_viewmodel.dart';
import 'package:inventario_qr_app/viewmodel/activo_viewmodel.dart';

class QrScanScreen extends StatefulWidget {
  const QrScanScreen({super.key});

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  MobileScannerController cameraController = MobileScannerController();
  bool _isProcessing = false;

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear Código QR'),
        leading: const BackButton(),
      ),
      body: Stack(
        children: [
          // Cámara
          MobileScanner(
            controller: cameraController,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              if (!_isProcessing && barcodes.isNotEmpty) {
                _isProcessing = true;
                _procesarQr(barcodes.first.rawValue ?? '');
              }
            },
          ),

          // Marco de enfoque
          Align(
            alignment: Alignment.center,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.green, width: 3),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          // Información superior
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Consumer<AuditoriaViewModel>(
              builder: (context, auditoriaVM, _) {
                return Container(
                  color: Colors.black87,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Equipos Escaneados',
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${auditoriaVM.escaneosCont}/${auditoriaVM.auditoriaActual?.totalEsperados ?? 0}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: auditoriaVM.auditoriaActual?.totalEsperados != null &&
                                auditoriaVM.auditoriaActual!.totalEsperados > 0
                            ? auditoriaVM.escaneosCont / auditoriaVM.auditoriaActual!.totalEsperados
                            : 0,
                        minHeight: 4,
                        backgroundColor: Colors.grey[700],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          auditoriaVM.escaneosCont == auditoriaVM.auditoriaActual?.totalEsperados
                              ? Colors.green
                              : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Información inferior + Botones
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.black87,
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Apunta la cámara al código QR',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Botón Finalizar Auditoría
                  Consumer<AuditoriaViewModel>(
                    builder: (context, auditoriaVM, _) {
                      return SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _handleFinalizarAuditoria(context, auditoriaVM),
                          icon: const Icon(Icons.check_circle),
                          label: Text(
                            'Finalizar Auditoría (${auditoriaVM.escaneosCont}/${auditoriaVM.auditoriaActual?.totalEsperados ?? 0})',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _procesarQr(String datosQr) async {
    try {
      final activoVM = context.read<ActivoViewModel>();
      final auditoriaVM = context.read<AuditoriaViewModel>();

      await activoVM.procesarEscaneoQr(datosQr);
      if (!mounted) return;

      if (activoVM.activoActual != null) {
        _mostrarDetallesActivo(context, activoVM, auditoriaVM);
      } else {
        _mostrarQrNoEncontrado(context, datosQr, auditoriaVM);
      }
    } catch (e) {
      if (!mounted) return;
      _mostrarError('Error procesando QR: $e');
    } finally {
      // Resetear después de 3 segundos si no se procesó
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          _isProcessing = false;
        }
      });
    }
  }

  void _mostrarDetallesActivo(
    BuildContext context,
    ActivoViewModel activoVM,
    AuditoriaViewModel auditoriaVM,
  ) {
    final activo = activoVM.activoActual;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Equipo Encontrado ✅',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Nombre'),
                subtitle: Text(activo?.nombre ?? ''),
                leading: const Icon(Icons.inventory_2),
              ),
              ListTile(
                title: const Text('Tipo'),
                subtitle: Text(activo?.tipo ?? ''),
                leading: const Icon(Icons.category),
              ),
              ListTile(
                title: const Text('Marca/Modelo'),
                subtitle: Text('${activo?.marca} ${activo?.modelo}'),
                leading: const Icon(Icons.label),
              ),
              ListTile(
                title: const Text('Estado'),
                subtitle: Text(activo?.estado ?? ''),
                leading: const Icon(Icons.check_circle),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        _isProcessing = false; // ← Resetear ANTES de cerrar
                        setState(() {});
                        Navigator.pop(context);
                      },
                      child: const Text('Escanear Otro'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        await auditoriaVM.registrarEscaneo(
                          activo!.id,
                          'presente',
                          null,
                        );
                        _isProcessing = false; // ← Resetear
                        if (mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('✅ Equipo registrado'),
                              backgroundColor: Colors.green,
                              duration: Duration(seconds: 2),
                            ),
                          );
                          setState(() {}); // ← Actualizar UI
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child: const Text('Registrar'),
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

  void _mostrarQrNoEncontrado(
    BuildContext context,
    String codigoQr,
    AuditoriaViewModel auditoriaVM,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Equipo No Encontrado ❌',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Código QR:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      codigoQr,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '¿Qué deseas hacer?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _isProcessing = false;
                    setState(() {});
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Escanear Otro'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await auditoriaVM.registrarEscaneo(
                      codigoQr,
                      'no_esperado',
                      'Equipo no registrado en BD',
                    );
                    Navigator.pop(context);
                    _isProcessing = false;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('⚠️ Registrado como No Esperado'),
                        backgroundColor: Colors.orange,
                        duration: Duration(seconds: 2),
                      ),
                    );
                    setState(() {});
                    
                    // ← AGREGAR ESTO: Cerrar modal después de 1.5 segundos
                    Future.delayed(const Duration(milliseconds: 1500), () {
                      if (mounted && Navigator.canPop(context)) {
                        Navigator.pop(context);
                      }
                    });
                  },
                  icon: const Icon(Icons.warning),
                  label: const Text('Marcar como No Esperado'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleFinalizarAuditoria(
    BuildContext context,
    AuditoriaViewModel auditoriaVM,
  ) {
    final total = auditoriaVM.auditoriaActual?.totalEsperados ?? 0;
    final escaneados = auditoriaVM.escaneosCont;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Finalizar Auditoría'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Equipos escaneados: $escaneados / $total'),
            const SizedBox(height: 8),
            if (escaneados < total)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange),
                ),
                child: const Text(
                  '⚠️ Auditoría incompleta: Faltan equipos por escanear.',
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 12,
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: const Text(
                  '✅ Auditoría completa: Todos los equipos fueron escaneados.',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            const Text(
              '¿Deseas continuar?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext); // Cierra el dialog
              
              final success = await auditoriaVM.finalizarAuditoria();
              
              if (!mounted) return; // ← Verificar antes de usar context
              
              if (success) {
                cameraController.dispose();
                Navigator.of(context).pushReplacementNamed('/resultados-auditoria');
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('❌ Error finalizando auditoría'),
                    backgroundColor: Colors.red,
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            child: const Text('Finalizar'),
          ),
        ],
      ),
    );
  }

  void _mostrarError(String mensaje) {
    _isProcessing = false;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red,
      ),
    );
    setState(() {});
  }
}
