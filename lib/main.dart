import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:inventario_qr_app/core/hive/hive_manager.dart';
import 'package:inventario_qr_app/core/utils/app_theme.dart';
import 'package:inventario_qr_app/core/utils/app_routes.dart';
import 'package:inventario_qr_app/viewmodel/auth_viewmodel.dart';
import 'package:inventario_qr_app/viewmodel/ambiente_viewmodel.dart';
import 'package:inventario_qr_app/viewmodel/activo_viewmodel.dart';
import 'package:inventario_qr_app/viewmodel/auditoria_viewmodel.dart';
import 'package:inventario_qr_app/view/widgets/auth_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar Hive
  await HiveManager.initHive();
  
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
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'ITBM - Sistema de Inventario',
        theme: AppTheme.lightTheme,
        home: const AuthWrapper(),
        onGenerateRoute: AppRoutes.generateRoute,
        initialRoute: AppRoutes.login,
      ),
    );
  }
}
