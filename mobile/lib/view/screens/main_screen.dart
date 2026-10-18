import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:inventario_qr_app/core/theme/app_theme.dart';
import 'package:inventario_qr_app/core/utils/app_routes.dart';
import 'package:inventario_qr_app/viewmodel/auth_viewmodel.dart';
import 'package:inventario_qr_app/view/screens/inventario_screen.dart';
import 'package:inventario_qr_app/view/screens/reportes_screen.dart';
import 'package:inventario_qr_app/view/screens/equipos_management_screen.dart';
import 'package:inventario_qr_app/view/screens/perfil_screen.dart';
import 'package:inventario_qr_app/view/widgets/floating_bottom_nav_bar.dart';
import 'package:inventario_qr_app/view/widgets/connectivity_banner.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  List<Widget> _getScreensForRole(String rol) {
    switch (rol.toLowerCase()) {
      case 'tecnico':
        return const [
          InventarioScreen(),
          PerfilScreen(),
        ];
      case 'auditor':
        return const [
          InventarioScreen(),
          ReportesScreen(),
          PerfilScreen(),
        ];
      case 'admin':
      default:
        return const [
          InventarioScreen(),
          ReportesScreen(),
          EquiposManagementScreen(),
          PerfilScreen(),
        ];
    }
  }

  void _handleScanTap(BuildContext context, String rol) {
    if (rol.toLowerCase() == 'tecnico') {
      Navigator.of(context).pushNamed(AppRoutes.qrScanSimple);
    } else {
      _showScanOptionsSheet(context);
    }
  }

  void _showScanOptionsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const Text(
                  'Opciones de Escaneo',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Selecciona una modalidad para comenzar:',
                  style: TextStyle(
                    color: AppColors.iconInactive,
                    fontSize: 13,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 20),
                _buildSheetOption(
                  context: ctx,
                  icon: Icons.qr_code_2_rounded,
                  title: 'Escaneo simple',
                  subtitle: 'Escanear un QR para ver información del equipo',
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.of(context).pushNamed(AppRoutes.qrScanSimple);
                  },
                ),
                const SizedBox(height: 12),
                _buildSheetOption(
                  context: ctx,
                  icon: Icons.checklist_rounded,
                  title: 'Auditoría por ambiente',
                  subtitle: 'Verificar todos los equipos de un laboratorio',
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.of(context).pushNamed(AppRoutes.selectAmbienteAuditoria);
                  },
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSheetOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.surfaceVariant),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primary, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.iconInactive,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: AppColors.iconInactive,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rol = context.watch<AuthViewModel>().usuario?.rol ?? 'tecnico';
    final screens = _getScreensForRole(rol);

    if (_selectedIndex >= screens.length) {
      _selectedIndex = 0;
    }

    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    final bottomBarHeight = isKeyboardOpen ? 0.0 : FloatingBottomNavBar.totalOccupiedHeight(context);

    // Definición centralizada: el MediaQuery inyecta la altura ocupada por la barra
    // inferior flotante para que todos los Scaffolds, FABs y Listas hijos la respeten automáticamente.
    final currentMq = MediaQuery.of(context);
    final scopedMq = currentMq.copyWith(
      padding: currentMq.padding.copyWith(
        bottom: isKeyboardOpen ? currentMq.padding.bottom : bottomBarHeight,
      ),
      viewPadding: currentMq.viewPadding.copyWith(
        bottom: isKeyboardOpen ? currentMq.viewPadding.bottom : bottomBarHeight,
      ),
    );

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: MediaQuery(
              data: scopedMq,
              child: IndexedStack(
                index: _selectedIndex,
                children: screens,
              ),
            ),
          ),
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: ConnectivityBanner(),
            ),
          ),
          if (!isKeyboardOpen)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: FloatingBottomNavBar(
                rol: rol,
                currentIndex: _selectedIndex,
                onTap: (index) {
                  setState(() {
                    _selectedIndex = index;
                  });
                },
                onScanTap: () => _handleScanTap(context, rol),
              ),
            ),
        ],
      ),
    );
  }
}
