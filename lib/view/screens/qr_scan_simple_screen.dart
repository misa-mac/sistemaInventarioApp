import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:inventario_qr_app/viewmodel/activo_viewmodel.dart';

class QrScanSimpleScreen extends StatefulWidget {
  const QrScanSimpleScreen({super.key});

  @override
  State<QrScanSimpleScreen> createState() => _QrScanSimpleScreenState();
}

class _QrScanSimpleScreenState extends State<QrScanSimpleScreen> {
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
        title: const Text('Información del Equipo'),
        leading: const BackButton(),
      ),
      body: Stack(
        children: [
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

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.black87,
              padding: const EdgeInsets.all(16),
              child: const Text(
                'Apunta la cámara al código QR',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
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
      await activoVM.procesarEscaneoQr(datosQr);

      if (!mounted) return;

      if (activoVM.activoActual != null) {
        _mostrarDetallesActivo(context, activoVM);
      } else {
        _mostrarError('Activo no encontrado');
      }
    } catch (e) {
      if (!mounted) return;
      _mostrarError('Error procesando QR: $e');
    }
  }

  void _mostrarDetallesActivo(BuildContext context, ActivoViewModel activoVM) {
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
            Text(
              'Información del Equipo',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
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
              title: const Text('Marca'),
              subtitle: Text(activo?.marca ?? ''),
              leading: const Icon(Icons.label),
            ),
            ListTile(
              title: const Text('Modelo'),
              subtitle: Text(activo?.modelo ?? ''),
              leading: const Icon(Icons.info),
            ),
            ListTile(
              title: const Text('Serie'),
              subtitle: Text(activo?.numeroSerie ?? ''),
              leading: const Icon(Icons.numbers),
            ),
            ListTile(
              title: const Text('Estado'),
              subtitle: Text(activo?.estado ?? ''),
              leading: const Icon(Icons.check_circle),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _isProcessing = false;
                  setState(() {});
                },
                child: const Text('Escanear otro'),
              ),
            ),
          ],
        ),
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
