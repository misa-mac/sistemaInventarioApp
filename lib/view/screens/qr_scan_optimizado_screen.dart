import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:vibration/vibration.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:inventario_qr_app/viewmodel/auditoria_viewmodel.dart';
import 'package:inventario_qr_app/viewmodel/activo_viewmodel.dart';

class QrScanOptimizadoScreen extends StatefulWidget {
  const QrScanOptimizadoScreen({super.key});

  @override
  State<QrScanOptimizadoScreen> createState() => _QrScanOptimizadoScreenState();
}

class _QrScanOptimizadoScreenState extends State<QrScanOptimizadoScreen> {
  MobileScannerController cameraController = MobileScannerController();
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  bool _isProcessing = false;
  String? _ultimoCodigoEscaneado;

  @override
  void dispose() {
    cameraController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escaneo Rápido de Auditoría'),
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
                _procesarQrOptimizado(barcodes.first.rawValue ?? '');
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

          // Información superior - Contador y Progreso
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Consumer<AuditoriaViewModel>(
              builder: (context, auditoriaVM, _) {
                final total = auditoriaVM.auditoriaActual?.totalEsperados ?? 0;
                final escaneados = auditoriaVM.escaneosCont;
                final porcentaje = total > 0 ? (escaneados / total) : 0.0;

                return Container(
                  color: Colors.black87,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'CONTADOR DE EQUIPOS',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Número grande del contador
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            escaneados.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '/ $total',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 24,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Barra de progreso
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: porcentaje,
                          minHeight: 8,
                          backgroundColor: Colors.grey[700],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            porcentaje >= 1.0 ? Colors.green : Colors.blue,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Porcentaje
                      Text(
                        '${(porcentaje * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          color: porcentaje >= 1.0 ? Colors.green : Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Información central - Último código escaneado
          Positioned(
            left: 0,
            right: 0,
            top: 200,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green, width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'ÚLTIMO CÓDIGO ESCANEADO',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _ultimoCodigoEscaneado != null
                      ? Text(
                          _ultimoCodigoEscaneado!,
                          style: const TextStyle(
                            color: Colors.green,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        )
                      : const Text(
                          'Esperando escaneo...',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                ],
              ),
            ),
          ),

          // Información inferior - Botón Finalizar
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
                  Text(
                    'Apunta la cámara al código QR',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _handleFinalizarAuditoria(context),
                      icon: const Icon(Icons.check_circle),
                      label: Consumer<AuditoriaViewModel>(
                        builder: (context, auditoriaVM, _) {
                          final total = auditoriaVM.auditoriaActual?.totalEsperados ?? 0;
                          final escaneados = auditoriaVM.escaneosCont;
                          return Text(
                            'Finalizar ($escaneados/$total)',
                          );
                        },
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _procesarQrOptimizado(String codigoQr) async {
    // SIN validación de duplicado - permitir escaneos múltiples
    _isProcessing = true;
    _ultimoCodigoEscaneado = codigoQr;

    try {
      final activoVM = context.read<ActivoViewModel>();
      final auditoriaVM = context.read<AuditoriaViewModel>();

      // Procesar el QR
      await activoVM.procesarEscaneoQr(codigoQr);

      if (activoVM.activoActual != null) {
        // QR válido - Registrar automáticamente
        final success = await auditoriaVM.registrarEscaneo(
          activoVM.activoActual!.id,
          'presente',
          null,
        );

        if (success) {
          // Éxito - Feedback positivo
          await _reproducirSonidoExito();
          await Vibration.vibrate(duration: 50);
          
          if (mounted) {
            setState(() {});
            _mostrarNotificacionExito();
          }
        }
      } else {
        // QR no encontrado - mostrar opciones
        await Vibration.vibrate(duration: 150);
        if (mounted) {
          _mostrarQrNoEncontrado(context, codigoQr, auditoriaVM);
        }
      }
    } catch (e) {
      debugPrint('❌ Error: $e');
      await Vibration.vibrate(duration: 200);
    } finally {
      if (mounted) {
        _isProcessing = false;
      }
    }
  }

  Future<void> _reproducirSonidoExito() async {
    try {
      // Usar sonido del sistema
      await _audioPlayer.play(AssetSource('sounds/beep_success.mp3'));
    } catch (e) {
      debugPrint('Error reproduciendo sonido: $e');
      // Continuar aunque no haya sonido
    }
  }

  void _mostrarNotificacionExito() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Equipo registrado'),
        backgroundColor: Colors.green,
        duration: Duration(milliseconds: 800),
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
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        if (mounted) {
                          _isProcessing = false;
                        }
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Seguir'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await auditoriaVM.registrarEscaneo(
                          codigoQr,
                          'no_esperado',
                          'Equipo no registrado',
                        );
                        if (context.mounted) {
                          Navigator.pop(context);
                        }
                        if (mounted) {
                          _isProcessing = false;
                          _mostrarNotificacionExito();
                          setState(() {});
                        }
                      },
                      icon: const Icon(Icons.warning),
                      label: const Text('Marcar No Esperado'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
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

  void _handleFinalizarAuditoria(BuildContext context) {
    final auditoriaVM = context.read<AuditoriaViewModel>();
    final total = auditoriaVM.auditoriaActual?.totalEsperados ?? 0;
    final escaneados = auditoriaVM.escaneosCont;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Verificando Auditoría'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Equipos escaneados: $escaneados / $total'),
            const SizedBox(height: 16),
            if (escaneados < total)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange),
                ),
                child: const Text(
                  '⚠️ Auditoría incompleta: faltan equipos',
                  style: TextStyle(color: Colors.orange),
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
                  '✅ Auditoría completa',
                  style: TextStyle(color: Colors.green),
                ),
              ),
            const SizedBox(height: 16),
            const Text(
              'Se verificará y limpiarán duplicados...',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext); // Cerrar diálogo anterior sincrónicamente
              _procesarFinalizacion(auditoriaVM);
            },
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
  }

  void _procesarFinalizacion(AuditoriaViewModel auditoriaVM) async {

    // Mostrar diálogo de carga con animación
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (loadingContext) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animación de carga circular
            SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.blue[900]!,
                ),
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Verificando duplicados...',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Por favor espera mientras se procesan los datos',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );

    try {
      // Limpiar duplicados
      debugPrint('🔄 Iniciando limpieza de duplicados...');
      await auditoriaVM.limpiarDuplicados();

      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      // Cerrar diálogo de carga
      Navigator.pop(context);

      // Mostrar resultado
      final total = auditoriaVM.auditoriaActual?.totalEsperados ?? 0;
      final escaneados = auditoriaVM.escaneosCont;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (resultContext) => AlertDialog(
          title: const Text('✅ Verificación Completada'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Resultado Final:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text('Total Esperado: $total'),
                    Text('Total Escaneado: $escaneados'),
                    const SizedBox(height: 8),
                    Text(
                      escaneados == total
                          ? '✓ AUDITORÍA COMPLETA'
                          : '⚠️ AUDITORÍA INCOMPLETA',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: escaneados == total ? Colors.green : Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '¿Deseas finalizar la auditoría?',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(resultContext),
              child: const Text('Volver'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(resultContext);
                
                // Finalizar auditoría
                final success = await auditoriaVM.finalizarAuditoria();
                
                if (success && mounted) {
                  cameraController.dispose();
                  Navigator.of(context).pushReplacementNamed('/resultados-auditoria');
                } else if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('❌ Error finalizando auditoría'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text(
                'Finalizar Auditoría',
                style: TextStyle(color: Colors.green),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Cerrar diálogo de carga

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
