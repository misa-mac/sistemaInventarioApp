import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:provider/provider.dart';
import 'package:inventario_qr_app/core/database/local_database.dart';
import 'package:inventario_qr_app/core/storage/session_manager.dart';
import 'package:inventario_qr_app/core/utils/app_theme.dart';
import 'package:inventario_qr_app/core/utils/app_routes.dart';
import 'package:inventario_qr_app/viewmodel/auth_viewmodel.dart';
import 'package:inventario_qr_app/viewmodel/ambiente_viewmodel.dart';
import 'package:inventario_qr_app/viewmodel/activo_viewmodel.dart';
import 'package:inventario_qr_app/viewmodel/auditoria_viewmodel.dart';
import 'package:inventario_qr_app/viewmodel/solicitud_viewmodel.dart';
import 'package:inventario_qr_app/view/widgets/auth_wrapper.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  
  // Inicializar sesión y almacenamiento local SQLite
  await SessionManager.init();
  await LocalDatabase.instance.database;
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // ViewModels
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => AmbienteViewModel()),
        ChangeNotifierProvider(create: (_) => ActivoViewModel()),
        ChangeNotifierProvider(create: (_) => AuditoriaViewModel()),
        ChangeNotifierProvider(create: (_) => SolicitudViewModel()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'ITBM - Sistema de Inventario',
        theme: AppTheme.lightTheme,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('es', 'ES'), // Español, España
        ],
        home: const AuthWrapper(),
        onGenerateRoute: AppRoutes.generateRoute,
      ),
    );
  }
}
