import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:inventario_qr_app/core/theme/app_theme.dart';
import 'package:inventario_qr_app/core/storage/session_manager.dart';
import 'package:inventario_qr_app/viewmodel/auth_viewmodel.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin(BuildContext context, AuthViewModel authVM) async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    setState(() {
      _emailError = null;
      _passwordError = null;
    });

    bool hasError = false;

    // Validar campos vacíos
    if (email.isEmpty) {
      setState(() => _emailError = 'Ingresa tu correo electrónico');
      hasError = true;
    } else if (!email.contains('@')) {
      setState(() => _emailError = 'El formato de correo es inválido');
      hasError = true;
    }

    if (password.isEmpty) {
      setState(() => _passwordError = 'Ingresa tu contraseña');
      hasError = true;
    } else if (password.length < 8) {
      setState(() => _passwordError = 'Debe tener al menos 8 caracteres');
      hasError = true;
    }

    if (hasError) return;

    final success = await authVM.login(email, password);

    if (success && context.mounted) {
      Navigator.of(context).pushReplacementNamed('/main');
    }
  }

  void _showServerConfigDialog(BuildContext context) {
    final serverController = TextEditingController(text: SessionManager.getServerHost());
    bool isTesting = false;
    String? testResult;
    bool testSuccess = false;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Row(
                children: [
                  Icon(Icons.wifi_rounded, color: AppColors.brandBlue),
                  SizedBox(width: 8),
                  Text(
                    'Servidor Backend',
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Configura la IP de tu computadora para que la app funcione sin cable por Wi-Fi o desde otros dispositivos en la red:',
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: serverController,
                      decoration: const InputDecoration(
                        labelText: 'IP o Host del Servidor',
                        hintText: '10.10.3.5',
                        prefixIcon: Icon(Icons.dns_outlined, color: AppColors.brandBlue),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Accesos rápidos:',
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        ActionChip(
                          label: const Text('Wi-Fi (10.10.3.5)', style: TextStyle(fontSize: 11)),
                          onPressed: () {
                            setDialogState(() {
                              serverController.text = '10.10.3.5';
                              testResult = null;
                            });
                          },
                        ),
                        ActionChip(
                          label: const Text('Cable USB (localhost)', style: TextStyle(fontSize: 11)),
                          onPressed: () {
                            setDialogState(() {
                              serverController.text = 'localhost';
                              testResult = null;
                            });
                          },
                        ),
                        ActionChip(
                          label: const Text('Emulador (10.0.2.2)', style: TextStyle(fontSize: 11)),
                          onPressed: () {
                            setDialogState(() {
                              serverController.text = '10.0.2.2';
                              testResult = null;
                            });
                          },
                        ),
                      ],
                    ),
                    if (testResult != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: testSuccess ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              testSuccess ? Icons.check_circle_outline : Icons.error_outline,
                              color: testSuccess ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                testResult!,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: testSuccess ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isTesting
                      ? null
                      : () async {
                          setDialogState(() {
                            isTesting = true;
                            testResult = null;
                          });
                          final host = serverController.text.trim();
                          try {
                            String testUrl = host;
                            if (!testUrl.startsWith('http://') && !testUrl.startsWith('https://')) {
                              testUrl = testUrl.contains(':') ? 'http://$testUrl' : 'http://$testUrl:3000';
                            }
                            if (testUrl.endsWith('/')) {
                              testUrl = testUrl.substring(0, testUrl.length - 1);
                            }
                            final uri = Uri.parse(testUrl.endsWith('/api') ? '$testUrl/inventory' : '$testUrl/api/inventory');
                            final res = await http.get(uri).timeout(const Duration(seconds: 4));
                            setDialogState(() {
                              isTesting = false;
                              testSuccess = (res.statusCode < 500);
                              testResult = testSuccess
                                  ? '¡Conexión establecida exitosamente!'
                                  : 'Respondió con código ${res.statusCode}';
                            });
                          } catch (e) {
                            setDialogState(() {
                              isTesting = false;
                              testSuccess = false;
                              testResult = 'No se pudo conectar a $host:3000. Revisa que estén en la misma red Wi-Fi.';
                            });
                          }
                        },
                  child: isTesting
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Probar Conexión'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryNavy,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    final host = serverController.text.trim();
                    if (host.isNotEmpty) {
                      await SessionManager.saveServerHost(host);
                      if (context.mounted) {
                        setState(() {});
                        Navigator.of(dialogCtx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Servidor guardado: $host:3000'),
                            backgroundColor: AppColors.brandBlue,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            children: [
              // 1. Banda superior en degradado #1E3A8A a #0D47A1
              Container(
                width: double.infinity,
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 32,
                  bottom: 40,
                  left: 24,
                  right: 24,
                ),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primaryNavy, AppColors.brandBlue],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(36),
                    bottomRight: Radius.circular(36),
                  ),
                ),
                child: Column(
                  children: [
                    // Círculo blanco con logo del instituto con fondo transparente
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Image.asset(
                        'assets/images/logo_itbm_splash.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'ITBM Inventario',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sistema de Control de Activos y QR',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),

              // 2. Tarjeta de formulario con campos con borde, etiqueta y errores en línea
              Transform.translate(
                offset: const Offset(0, -20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Iniciar Sesión',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Ingresa tus credenciales institucionales',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 12,
                                      color: AppColors.iconInactive,
                                    ),
                                  ),
                                ],
                              ),
                              IconButton(
                                icon: const Icon(Icons.wifi_rounded, color: AppColors.brandBlue, size: 22),
                                tooltip: 'Configurar IP del Servidor',
                                onPressed: () => _showServerConfigDialog(context),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Campo Correo Electrónico
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            onChanged: (_) {
                              if (_emailError != null) {
                                setState(() => _emailError = null);
                              }
                            },
                            decoration: InputDecoration(
                              labelText: 'Correo electrónico',
                              hintText: 'ejemplo@itbm.edu.bo',
                              prefixIcon: const Icon(
                                Icons.email_outlined,
                                color: AppColors.brandBlue,
                              ),
                              errorText: _emailError,
                              errorMaxLines: 2,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Campo Contraseña con botón mostrar/ocultar
                          TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            onChanged: (_) {
                              if (_passwordError != null) {
                                setState(() => _passwordError = null);
                              }
                            },
                            onSubmitted: (_) {
                              final authVM = context.read<AuthViewModel>();
                              if (!authVM.isLoading) {
                                _handleLogin(context, authVM);
                              }
                            },
                            decoration: InputDecoration(
                              labelText: 'Contraseña',
                              hintText: '••••••••',
                              prefixIcon: const Icon(
                                Icons.lock_outline,
                                color: AppColors.brandBlue,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: AppColors.iconInactive,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              errorText: _passwordError,
                              errorMaxLines: 2,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Botón de 52 dp con estado de carga
                          Consumer<AuthViewModel>(
                            builder: (context, authVM, _) {
                              return SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton(
                                  onPressed: authVM.isLoading
                                      ? null
                                      : () => _handleLogin(context, authVM),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryNavy,
                                    foregroundColor: Colors.white,
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: authVM.isLoading
                                      ? const SizedBox(
                                          height: 22,
                                          width: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    Colors.white),
                                          ),
                                        )
                                      : const Text(
                                          'Acceder al Sistema',
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                ),
                              );
                            },
                          ),

                          // Error en línea si la API o ViewModel retorna error
                          Consumer<AuthViewModel>(
                            builder: (context, authVM, _) {
                              if (authVM.error == null) {
                                return const SizedBox.shrink();
                              }
                              return Container(
                                margin: const EdgeInsets.only(top: 16),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.statusRedBg,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: AppColors.statusRed
                                        .withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.error_outline_rounded,
                                      color: AppColors.statusRedText,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        authVM.error!,
                                        style: const TextStyle(
                                          fontFamily: 'Poppins',
                                          color: AppColors.statusRedText,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 18),
                          Center(
                            child: InkWell(
                              onTap: () => _showServerConfigDialog(context),
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.brandBlue.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: AppColors.brandBlue.withValues(alpha: 0.2)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.wifi_rounded, size: 14, color: AppColors.brandBlue),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Servidor: ${SessionManager.getServerHost()}:3000',
                                      style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.brandBlue,
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
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 3. Pie con nombre del instituto y versión
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Column(
                  children: [
                    const Text(
                      'Instituto Tecnológico Bolivia Mar',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Versión 1.0.0 · ITBM Inventario QR',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: AppColors.iconInactive.withValues(alpha: 0.8),
                      ),
                    ),
                    SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
