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

          // Información inferior
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
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_isProcessing)
                    const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                      ),
                    )
                  else
                    Text(
                      'Procesando código...',
                      style: TextStyle(color: Colors.grey[400]),
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

      // Procesar el escaneo
      await activoVM.procesarEscaneoQr(datosQr);

      if (!mounted) return;

      if (activoVM.activoActual != null) {
        // Mostrar detalles del activo
        _mostrarDetallesActivo(context, activoVM, auditoriaVM);
      } else {
        _mostrarError('Activo no encontrado');
      }
    } catch (e) {
      _mostrarError('Error procesando QR: $e');
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
      builder: (modalContext) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detalles del Activo',
              style: Theme.of(modalContext).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Nombre'),
              subtitle: Text(activo?.nombre ?? ''),
            ),
            ListTile(
              title: const Text('Tipo'),
              subtitle: Text(activo?.tipo ?? ''),
            ),
            ListTile(
              title: const Text('Marca/Modelo'),
              subtitle: Text('${activo?.marca} ${activo?.modelo}'),
            ),
            ListTile(
              title: const Text('Estado'),
              subtitle: Text(activo?.estado ?? ''),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(modalContext);
                      _isProcessing = false;
                      setState(() {});
                    },
                    child: const Text('Otro Escaneo'),
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
                      
                      if (!modalContext.mounted) return;
                      Navigator.pop(modalContext);
                      
                      if (!mounted) return;
                      _isProcessing = false;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✓ Equipo registrado'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      setState(() {});
                    },
                    child: const Text('Registrar'),
                  ),
                ),
              ],
            ),
          ],
        ),
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
