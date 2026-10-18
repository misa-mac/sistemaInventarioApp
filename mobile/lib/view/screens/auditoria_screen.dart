import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:vibration/vibration.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:inventario_qr_app/core/theme/app_theme.dart';
import 'package:inventario_qr_app/viewmodel/auditoria_viewmodel.dart';
import 'package:inventario_qr_app/viewmodel/ambiente_viewmodel.dart';
import 'package:inventario_qr_app/viewmodel/auth_viewmodel.dart';
import 'package:inventario_qr_app/viewmodel/activo_viewmodel.dart';

class AuditoriaScreen extends StatefulWidget {
  const AuditoriaScreen({super.key});

  @override
  State<AuditoriaScreen> createState() => _AuditoriaScreenState();
}

class _AuditoriaScreenState extends State<AuditoriaScreen> {
  final MobileScannerController _cameraController = MobileScannerController();
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _isProcessing = false;
  bool _scanFlash = false;
  String? _ultimoCodigoEscaneado;
  int _noEsperadosCount = 0;

  // Control de tiempo de espera (cooldown) y prevención de lecturas duplicadas
  static const int _cooldownDurationMs = 2500; // 2.5s tiempo de espera para leer otro QR
  bool _enCooldown = false;
  double _cooldownProgress = 0.0;
  Timer? _cooldownTimer;
  Timer? _animTimer;
  DateTime? _ultimoEscaneoTime;
  String? _mensajeEstado;
  Color _mensajeEstadoColor = Colors.white;
  final Set<String> _codigosAuditados = {}; // Registro local de QRs ya leídos en la sesión

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _iniciarAuditoria();
    });
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _animTimer?.cancel();
    _cameraController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _iniciarAuditoria() async {
    final ambienteVM = context.read<AmbienteViewModel>();
    final auditoriaVM = context.read<AuditoriaViewModel>();
    final authVM = context.read<AuthViewModel>();

    final ambiente = ambienteVM.ambienteSeleccionado;
    final usuario = authVM.usuario;

    if (ambiente == null || usuario == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: Ambiente o usuario no seleccionado'),
            backgroundColor: AppColors.statusRed,
          ),
        );
      }
      return;
    }

    await context.read<AmbienteViewModel>().cargarAmbientes();
    if (!mounted) return;

    final activosVM = context.read<ActivoViewModel>();
    await activosVM.cargarActivosPorAmbiente(ambiente.id);
    final totalEsperados = activosVM.activos.length;

    final success = await auditoriaVM.iniciarAuditoria(
      ambiente.id,
      usuario.id,
      totalEsperados,
    );

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al inicializar la auditoría'),
          backgroundColor: AppColors.statusRed,
        ),
      );
    }
  }

  Future<void> _reproducirSonido() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/beep_success.mp3'));
    } catch (_) {}
  }

  /// Inicia el temporizador de enfriamiento (cooldown) y actualiza la animación en pantalla
  void _iniciarCooldown({
    int durationMs = _cooldownDurationMs,
    String? mensaje,
    Color? color,
  }) {
    _cooldownTimer?.cancel();
    _animTimer?.cancel();

    final startTime = DateTime.now();
    if (mounted) {
      setState(() {
        _enCooldown = true;
        _cooldownProgress = 1.0;
        if (mensaje != null) {
          _mensajeEstado = mensaje;
          _mensajeEstadoColor = color ?? AppColors.brandBlue;
        }
      });
    }

    // Actualización progresiva suave para el indicador visual
    _animTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final elapsed = DateTime.now().difference(startTime).inMilliseconds;
      final remaining = (durationMs - elapsed) / durationMs;
      if (remaining <= 0) {
        timer.cancel();
      } else {
        setState(() {
          _cooldownProgress = remaining.clamp(0.0, 1.0);
        });
      }
    });

    _cooldownTimer = Timer(Duration(milliseconds: durationMs), () {
      if (mounted) {
        setState(() {
          _enCooldown = false;
          _isProcessing = false;
          _cooldownProgress = 0.0;
          _mensajeEstado = null;
        });
      }
    });
  }

  void _procesarEscaneoQr(String codigoQr) async {
    final cleanCode = codigoQr.trim();
    if (cleanCode.isEmpty) return;

    // 1. Si está procesando actualmente la API o en período de espera (cooldown), ignorar
    if (_isProcessing || _enCooldown) return;

    final now = DateTime.now();

    // 2. Si es EXACTAMENTE el mismo código que el último leído:
    // Evitar re-recolectar el mismo código si se mantiene en foco la cámara
    if (_ultimoCodigoEscaneado == cleanCode) {
      if (_ultimoEscaneoTime != null &&
          now.difference(_ultimoEscaneoTime!).inSeconds < 5) {
        return; // Ignorar silenciosamente mientras permanezca apuntando al mismo QR
      }
    }

    // 3. Si el activo ya fue auditado previamente en esta sesión de auditoría:
    final auditoriaVM = context.read<AuditoriaViewModel>();
    if (_codigosAuditados.contains(cleanCode)) {
      _ultimoCodigoEscaneado = cleanCode;
      _ultimoEscaneoTime = now;
      await Vibration.vibrate(duration: 100);
      if (mounted) {
        _iniciarCooldown(
          durationMs: 2000,
          mensaje: '⚠️ Este equipo ya fue registrado en esta auditoría',
          color: AppColors.statusAmberText,
        );
      }
      return;
    }

    // 4. Iniciar procesamiento del nuevo código QR
    _isProcessing = true;
    _ultimoCodigoEscaneado = cleanCode;
    _ultimoEscaneoTime = now;

    try {
      final activoVM = context.read<ActivoViewModel>();

      await activoVM.procesarEscaneoQr(cleanCode);

      if (activoVM.activoActual != null) {
        final activoId = activoVM.activoActual!.id;

        // Doble verificación: comprobar si el ID del activo ya fue auditado
        if (auditoriaVM.isActivoAuditado(activoId)) {
          _codigosAuditados.add(cleanCode);
          await Vibration.vibrate(duration: 100);
          if (mounted) {
            _iniciarCooldown(
              durationMs: 2000,
              mensaje: '⚠️ El activo "${activoVM.activoActual!.nombre}" ya fue auditado',
              color: AppColors.statusAmberText,
            );
          }
          return;
        }

        final success = await auditoriaVM.registrarEscaneo(
          activoId,
          'presente',
          null,
        );

        if (success) {
          _codigosAuditados.add(cleanCode);

          // Confirmación visual (flash verde) + vibración + sonido
          if (mounted) {
            setState(() => _scanFlash = true);
          }
          await Vibration.vibrate(duration: 50);
          _reproducirSonido();

          Future.delayed(const Duration(milliseconds: 350), () {
            if (mounted) {
              setState(() => _scanFlash = false);
            }
          });

          // Iniciar tiempo de espera (2.5s) para enfocar el siguiente QR sin lecturas duplicadas
          if (mounted) {
            _iniciarCooldown(
              durationMs: _cooldownDurationMs,
              mensaje: '✓ Registrado: $cleanCode • Espera 2.5s para siguiente QR',
              color: AppColors.statusGreen,
            );
          }
        } else {
          if (mounted) {
            _iniciarCooldown(durationMs: 1200);
          }
        }
      } else {
        await Vibration.vibrate(duration: 150);
        if (mounted) {
          _mostrarModalNoEsperado(context, cleanCode, auditoriaVM);
        }
      }
    } catch (e) {
      debugPrint('Error en auditoría QR: $e');
      if (mounted) {
        _iniciarCooldown(durationMs: 1200);
      }
    }
  }

  void _mostrarModalNoEsperado(
    BuildContext context,
    String codigoQr,
    AuditoriaViewModel auditoriaVM,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: AppColors.statusAmberText, size: 28),
                SizedBox(width: 10),
                Text(
                  'Activo No Esperado',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.statusAmberBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.statusAmber.withValues(alpha: 0.4)),
              ),
              child: Text(
                'Código leído: $codigoQr\nEste activo no pertenece a este ambiente según el registro actual.',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: AppColors.statusAmberText,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _iniciarCooldown(
                        durationMs: 2000,
                        mensaje: 'Código no esperado ignorado',
                        color: AppColors.statusAmberText,
                      );
                    },
                    child: const Text('Ignorar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      await auditoriaVM.registrarEscaneo(
                        codigoQr,
                        'no_esperado',
                        'Equipo no esperado en ambiente',
                      );
                      _codigosAuditados.add(codigoQr);
                      setState(() {
                        _noEsperadosCount++;
                      });
                      if (ctx.mounted) Navigator.pop(ctx);
                      _iniciarCooldown(
                        durationMs: _cooldownDurationMs,
                        mensaje: '✓ Registrado como no esperado: $codigoQr',
                        color: AppColors.statusAmberText,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.statusAmber,
                      foregroundColor: AppColors.statusAmberText,
                    ),
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

  Future<bool> _confirmarSalida(BuildContext context) async {
    final salir = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.statusAmber, size: 28),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                '¿Salir de la auditoría?',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        content: const Text(
          'Hay una auditoría en curso. Si sales ahora, el progreso no finalizado se perderá.',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Continuar auditoría',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                color: AppColors.brandBlue,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text(
              'Abandonar',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
    return salir ?? false;
  }

  void _finalizarAuditoria(BuildContext context, AuditoriaViewModel auditoriaVM) async {
    final total = auditoriaVM.auditoriaActual?.totalEsperados ?? 0;
    final escaneados = auditoriaVM.escaneosCont;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Finalizar Auditoría',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          '¿Estás seguro de finalizar la auditoría?\n\n'
          '• Total esperados: $total\n'
          '• Verificados presentes: $escaneados\n'
          '• Faltantes: ${(total - escaneados) < 0 ? 0 : (total - escaneados)}\n'
          '• No esperados: $_noEsperadosCount',
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Continuar escaneando'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryNavy,
              foregroundColor: Colors.white,
            ),
            child: const Text('Finalizar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      final success = await auditoriaVM.finalizarAuditoria();
      if (success && context.mounted) {
        Navigator.of(context).pushReplacementNamed('/resultados-auditoria');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final salir = await _confirmarSalida(context);
        if (salir && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.primaryNavy,
          foregroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () async {
              final salir = await _confirmarSalida(context);
              if (salir && context.mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
          title: const Text(
            'Auditoría en Curso',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          actions: [
            // Control de linterna en el AppBar
            ValueListenableBuilder<TorchState>(
              valueListenable: _cameraController.torchState,
              builder: (context, state, child) {
                final isTorchOn = state == TorchState.on;
                return IconButton(
                  icon: Icon(
                    isTorchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                    color: isTorchOn ? Colors.amberAccent : Colors.white,
                  ),
                  tooltip: 'Linterna',
                  onPressed: () => _cameraController.toggleTorch(),
                );
              },
            ),
          ],
        ),
        body: Consumer2<AuditoriaViewModel, AmbienteViewModel>(
          builder: (context, auditoriaVM, ambienteVM, _) {
            if (auditoriaVM.auditoriaActual == null) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(strokeWidth: 2.5),
                    SizedBox(height: 12),
                    Text(
                      'Inicializando auditoría...',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: AppColors.iconInactive,
                      ),
                    ),
                  ],
                ),
              );
            }

            final ambiente = ambienteVM.ambienteSeleccionado;
            final dentroGeofence = ambienteVM.dentroDeGeofence;
            final totalEsperados = auditoriaVM.auditoriaActual?.totalEsperados ?? 0;
            final presentes = auditoriaVM.escaneosCont;
            final faltantes = (totalEsperados - presentes) < 0 ? 0 : (totalEsperados - presentes);
            final progreso = totalEsperados > 0 ? (presentes / totalEsperados).clamp(0.0, 1.0) : 0.0;

            return Column(
              children: [
                // 1. Encabezado con ambiente y chip de geofence
                Container(
                  width: double.infinity,
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              ambiente?.nombre ?? 'Ambiente Seleccionado',
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Chip de Geofence (dentro o fuera)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: dentroGeofence
                                  ? AppColors.statusGreenBg
                                  : AppColors.statusAmberBg,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: dentroGeofence
                                    ? AppColors.statusGreen.withValues(alpha: 0.4)
                                    : AppColors.statusAmber.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  dentroGeofence
                                      ? Icons.check_circle_rounded
                                      : Icons.location_off_rounded,
                                  size: 14,
                                  color: dentroGeofence
                                      ? AppColors.statusGreenText
                                      : AppColors.statusAmberText,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  dentroGeofence ? 'Dentro de rango' : 'Fuera de rango',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: dentroGeofence
                                        ? AppColors.statusGreenText
                                        : AppColors.statusAmberText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Contador "escaneados de esperados" con barra de progreso
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '$presentes de $totalEsperados verificados',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            '${(progreso * 100).toStringAsFixed(0)}%',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.brandBlue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: progreso,
                          minHeight: 8,
                          backgroundColor: AppColors.border,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            progreso >= 1.0 ? AppColors.statusGreen : AppColors.brandBlue,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Contadores de presente, faltante y no esperado (con texto oscuro sobre fondo claro)
                      Row(
                        children: [
                          // Presente
                          Expanded(
                            child: _buildMetricCard(
                              icon: Icons.check_circle_rounded,
                              label: 'Presente',
                              count: presentes,
                              bgColor: AppColors.statusGreenBg,
                              textColor: AppColors.statusGreenText,
                              borderColor: AppColors.statusGreen.withValues(alpha: 0.3),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Faltante
                          Expanded(
                            child: _buildMetricCard(
                              icon: Icons.cancel_rounded,
                              label: 'Faltante',
                              count: faltantes,
                              bgColor: AppColors.statusRedBg,
                              textColor: AppColors.statusRedText,
                              borderColor: AppColors.statusRed.withValues(alpha: 0.3),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // No esperado
                          Expanded(
                            child: _buildMetricCard(
                              icon: Icons.warning_rounded,
                              label: 'No esperado',
                              count: _noEsperadosCount,
                              bgColor: AppColors.statusAmberBg,
                              textColor: AppColors.statusAmberText,
                              borderColor: AppColors.statusAmber.withValues(alpha: 0.3),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // 2. Visor de cámara con marco guía y linterna
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Scanner de cámara
                      MobileScanner(
                        controller: _cameraController,
                        onDetect: (capture) {
                          final barcodes = capture.barcodes;
                          if (barcodes.isNotEmpty) {
                            final raw = barcodes.first.rawValue ?? '';
                            _procesarEscaneoQr(raw);
                          }
                        },
                      ),

                      // Marco guía de enfoque reactivo al estado
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 230,
                        height: 230,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _scanFlash
                                ? AppColors.statusGreen
                                : (_enCooldown
                                    ? _mensajeEstadoColor.withValues(alpha: 0.85)
                                    : Colors.white.withValues(alpha: 0.85)),
                            width: _scanFlash
                                ? 3.5
                                : (_enCooldown ? 3.0 : 2.5),
                          ),
                        ),
                      ),

                      // Confirmación visual al escanear (flash sutil verde + check)
                      if (_scanFlash)
                        Positioned.fill(
                          child: Container(
                            color: AppColors.statusGreen.withValues(alpha: 0.25),
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check_rounded,
                                  color: AppColors.statusGreen,
                                  size: 42,
                                ),
                              ),
                            ),
                          ),
                        ),

                      // Indicador dinámico de estado / cooldown / último código escaneado
                      Positioned(
                        bottom: 16,
                        left: 16,
                        right: 16,
                        child: Center(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.78),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: _enCooldown
                                    ? _mensajeEstadoColor.withValues(alpha: 0.7)
                                    : AppColors.statusGreen.withValues(alpha: 0.5),
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_enCooldown) ...[
                                  SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      value: _cooldownProgress > 0 ? _cooldownProgress : null,
                                      strokeWidth: 2,
                                      color: _mensajeEstadoColor,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ] else ...[
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: AppColors.statusGreen,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                Flexible(
                                  child: Text(
                                    _enCooldown
                                        ? (_mensajeEstado ?? 'Pausa entre lecturas...')
                                        : (_ultimoCodigoEscaneado != null
                                            ? 'Listo • Último: $_ultimoCodigoEscaneado'
                                            : 'Apunta la cámara al código QR'),
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      color: _enCooldown ? _mensajeEstadoColor : Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 3. Botón para finalizar auditoría
                Container(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    12,
                    16,
                    12 + MediaQuery.of(context).padding.bottom,
                  ),
                  color: Colors.white,
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () => _finalizarAuditoria(context, auditoriaVM),
                      icon: const Icon(Icons.check_circle_outline_rounded, size: 20),
                      label: Text(
                        'Finalizar Auditoría ($presentes/$totalEsperados)',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryNavy,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String label,
    required int count,
    required Color bgColor,
    required Color textColor,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: textColor),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            count.toString(),
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
