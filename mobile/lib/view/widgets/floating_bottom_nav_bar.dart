import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:inventario_qr_app/core/theme/app_theme.dart';

/// Modelo de ítem de navegación para la barra inferior.
class NavItemData {
  final String label;
  final IconData outlineIcon;
  final IconData filledIcon;
  final int tabIndex;

  const NavItemData({
    required this.label,
    required this.outlineIcon,
    required this.filledIcon,
    required this.tabIndex,
  });
}

/// Barra de navegación inferior flotante en forma de píldora
/// con botón central elevado para escaneo QR y destinos dinámicos por rol.
class FloatingBottomNavBar extends StatelessWidget {
  final String rol;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onScanTap;

  const FloatingBottomNavBar({
    super.key,
    required this.rol,
    required this.currentIndex,
    required this.onTap,
    required this.onScanTap,
  });

  /// Obtiene los ítems según el rol del usuario autenticado:
  /// - tecnico: Inventario | [Escanear] | Perfil
  /// - auditor: Inventario, Reportes | [Escanear] | Perfil (sobrante a la derecha)
  /// - admin: Inventario, Reportes | [Escanear] | Gestión, Perfil
  static List<NavItemData> getItemsForRole(String rol) {
    switch (rol.toLowerCase()) {
      case 'tecnico':
        return const [
          NavItemData(
            label: 'Inventario',
            outlineIcon: Icons.inventory_2_outlined,
            filledIcon: Icons.inventory_2,
            tabIndex: 0,
          ),
          NavItemData(
            label: 'Perfil',
            outlineIcon: Icons.person_outline,
            filledIcon: Icons.person,
            tabIndex: 1,
          ),
        ];
      case 'auditor':
        return const [
          NavItemData(
            label: 'Inventario',
            outlineIcon: Icons.inventory_2_outlined,
            filledIcon: Icons.inventory_2,
            tabIndex: 0,
          ),
          NavItemData(
            label: 'Reportes',
            outlineIcon: Icons.assessment_outlined,
            filledIcon: Icons.assessment,
            tabIndex: 1,
          ),
          NavItemData(
            label: 'Perfil',
            outlineIcon: Icons.person_outline,
            filledIcon: Icons.person,
            tabIndex: 2,
          ),
        ];
      case 'admin':
      default:
        return const [
          NavItemData(
            label: 'Inventario',
            outlineIcon: Icons.inventory_2_outlined,
            filledIcon: Icons.inventory_2,
            tabIndex: 0,
          ),
          NavItemData(
            label: 'Reportes',
            outlineIcon: Icons.assessment_outlined,
            filledIcon: Icons.assessment,
            tabIndex: 1,
          ),
          NavItemData(
            label: 'Gestión',
            outlineIcon: Icons.settings_outlined,
            filledIcon: Icons.settings,
            tabIndex: 2,
          ),
          NavItemData(
            label: 'Perfil',
            outlineIcon: Icons.person_outline,
            filledIcon: Icons.person,
            tabIndex: 3,
          ),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = getItemsForRole(rol);
    final totalItems = items.length;

    // Regla de distribución simétrica:
    // Si es impar (ej: 3 ítems en auditor), el sobrante va a la derecha.
    final leftCount = totalItems ~/ 2;
    final leftItems = items.sublist(0, leftCount);
    final rightItems = items.sublist(leftCount);

    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: [
        // Contenedor principal en forma de píldora
        Container(
          height: 64,
          margin: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: 12 + bottomPadding,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Íconos del lado izquierdo
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: leftItems
                      .map((item) => _NavItemWidget(
                            item: item,
                            isSelected: currentIndex == item.tabIndex,
                            onTap: () => onTap(item.tabIndex),
                          ))
                      .toList(),
                ),
              ),

              // Espacio central para el botón flotante (64 dp + margen)
              const SizedBox(width: 72),

              // Íconos del lado derecho
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: rightItems
                      .map((item) => _NavItemWidget(
                            item: item,
                            isSelected: currentIndex == item.tabIndex,
                            onTap: () => onTap(item.tabIndex),
                          ))
                      .toList(),
                ),
              ),
            ],
          ),
        ),

        // Botón central elevado que sobresale 24 dp sobre la píldora
        Positioned(
          bottom: 12 + bottomPadding + 24,
          child: CenterScanButton(
            onPressed: onScanTap,
          ),
        ),
      ],
    );
  }
}

/// Ítem individual de navegación con accesibilidad Semantics,
/// área táctil mínima de 48dp y animación suave de 200 ms.
class _NavItemWidget extends StatelessWidget {
  final NavItemData item;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItemWidget({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.of(context).disableAnimations;
    final duration =
        disableAnimations ? Duration.zero : const Duration(milliseconds: 200);

    return Semantics(
      label: item.label,
      selected: isSelected,
      button: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: 48,
          minHeight: 48,
        ),
        child: InkResponse(
          onTap: onTap,
          radius: 28,
          containedInkWell: true,
          splashColor: AppColors.primary.withValues(alpha: 0.12),
          highlightColor: Colors.transparent,
          child: AnimatedContainer(
            duration: duration,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedSwitcher(
                  duration: duration,
                  child: Icon(
                    isSelected ? item.filledIcon : item.outlineIcon,
                    key: ValueKey<bool>(isSelected),
                    size: 24,
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.iconInactive,
                  ),
                ),
                if (isSelected) ...[
                  const SizedBox(height: 2),
                  AnimatedDefaultTextStyle(
                    duration: duration,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                    ),
                    child: Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Botón central elevado (cuadrado redondeado de 64x64, esquinas de 20dp)
/// con icono QR blanco, fondo #0D47A1 y feedback háptico + escala 0.95.
class CenterScanButton extends StatefulWidget {
  final VoidCallback onPressed;

  const CenterScanButton({
    super.key,
    required this.onPressed,
  });

  @override
  State<CenterScanButton> createState() => _CenterScanButtonState();
}

class _CenterScanButtonState extends State<CenterScanButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.of(context).disableAnimations;
    final duration =
        disableAnimations ? Duration.zero : const Duration(milliseconds: 100);

    return Semantics(
      label: 'Escanear código QR',
      button: true,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          HapticFeedback.lightImpact();
          widget.onPressed();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedScale(
          scale: _isPressed ? 0.95 : 1.0,
          duration: duration,
          curve: Curves.easeInOut,
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(
              Icons.qr_code_scanner_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
        ),
      ),
    );
  }
}
