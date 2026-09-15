import 'package:flutter/material.dart';

class EscaneoScreen extends StatefulWidget {
  const EscaneoScreen({super.key});

  @override
  State<EscaneoScreen> createState() => _EscaneoScreenState();
}

class _EscaneoScreenState extends State<EscaneoScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Opciones de Escaneo',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 40),

            // Opción 1: Auditoría
            _buildEscaneoCard(
              context,
              icon: Icons.checklist,
              titulo: 'Auditoría',
              descripcion: 'Verificar todos los equipos\nde un laboratorio',
              color: Colors.blue,
              onTap: () => Navigator.of(context).pushNamed('/select-ambiente-auditoria'),
            ),
            const SizedBox(height: 20),

            // Opción 2: Escaneo Simple
            _buildEscaneoCard(
              context,
              icon: Icons.qr_code_2,
              titulo: 'Escaneo Simple',
              descripcion: 'Escanear un QR para\nver información del equipo',
              color: Colors.green,
              onTap: () => Navigator.of(context).pushNamed('/qr-scan-simple'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEscaneoCard(
    BuildContext context, {
    required IconData icon,
    required String titulo,
    required String descripcion,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Card(
        elevation: 4,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [color.withValues(alpha: 0.1), color.withValues(alpha: 0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 32),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      descripcion,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward, color: color),
            ],
          ),
        ),
      ),
    );
  }
}
