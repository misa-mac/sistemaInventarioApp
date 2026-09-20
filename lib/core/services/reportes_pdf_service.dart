import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:inventario_qr_app/models/auditoria_model.dart';
import 'package:inventario_qr_app/models/activo_model.dart';

import 'dart:io';
import 'package:path_provider/path_provider.dart';

class ReportesPdfService {
  // Generar PDF de reportes
  static Future<void> generarPdfReportes({
    required AuditoriaModel? ultimaAuditoria,
    required ActivoModel? ultimoEscaneado,
    required List<DetalleAuditoriaModel> movimientosRecientes,
    required List<ActivoModel> activosNuevos,
    required List<ActivoModel> activosDeBaja,
    String? rutaPersonalizada,
  }) async {
    final pdf = pw.Document();

    // Cargar logo
    final imageData = await rootBundle.load('assets/images/logo_itbm.png');
    final image = pw.MemoryImage(imageData.buffer.asUint8List());

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Encabezado
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Container(
                    width: 60,
                    height: 60,
                    child: pw.Image(image),
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'INFORME GENERAL',
                        style: const pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Dirección Administrativa - Manejo de Bienes - Activos Fijos',
                        style: const pw.TextStyle(fontSize: 8),
                      ),
                    ],
                  ),
                ],
              ),
              pw.Divider(thickness: 1),
              pw.SizedBox(height: 10),

              // 1. ÚLTIMA AUDITORÍA
              pw.Text(
                '1. ÚLTIMA AUDITORÍA',
                style: const pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 6),
              
              if (ultimaAuditoria != null)
                pw.Table(
                  border: pw.TableBorder.all(width: 0.5),
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(
                        color: PdfColor.fromInt(0xFF1E3A8A),
                      ),
                      children: [
                        _buildTableHeader('Concepto'),
                        _buildTableHeader('Valor'),
                      ],
                    ),
                    _buildTableRow('ID', ultimaAuditoria.id),
                    _buildTableRow(
                      'Fecha',
                      ultimaAuditoria.fechaInicio.toString().split('.')[0],
                    ),
                    _buildTableRow(
                      'Equipos Encontrados',
                      '${ultimaAuditoria.totalEncontrados}/${ultimaAuditoria.totalEsperados}',
                    ),
                    _buildTableRow(
                      'Estado',
                      ultimaAuditoria.totalEncontrados == ultimaAuditoria.totalEsperados
                          ? 'COMPLETADO'
                          : 'INCOMPLETO',
                    ),
                  ],
                )
              else
                pw.Text(
                  'Sin auditorías realizadas',
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey),
                ),

              pw.SizedBox(height: 15),

              // 2. ÚLTIMO ESCANEO
              pw.Text(
                '2. ÚLTIMO ESCANEO',
                style: const pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 6),

              if (ultimoEscaneado != null)
                pw.Table(
                  border: pw.TableBorder.all(width: 0.5),
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(
                        color: PdfColor.fromInt(0xFF1E3A8A),
                      ),
                      children: [
                        _buildTableHeader('Concepto'),
                        _buildTableHeader('Valor'),
                      ],
                    ),
                    _buildTableRow('Nombre', ultimoEscaneado.nombre),
                    _buildTableRow('Tipo', ultimoEscaneado.tipo),
                    _buildTableRow('Marca', ultimoEscaneado.marca),
                    _buildTableRow('Estado', ultimoEscaneado.estado),
                  ],
                )
              else
                pw.Text(
                  'Sin escaneos realizados',
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey),
                ),

              pw.SizedBox(height: 15),

              // 3. ESCANEOS RECIENTES
              pw.Text(
                '3. ESCANEOS RECIENTES',
                style: const pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 6),

              if (movimientosRecientes.isNotEmpty)
                pw.Table(
                  border: pw.TableBorder.all(width: 0.5),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(1.5),
                    1: const pw.FlexColumnWidth(2),
                    2: const pw.FlexColumnWidth(1),
                  },
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(
                        color: PdfColor.fromInt(0xFF1E3A8A),
                      ),
                      children: [
                        _buildTableHeader('Activo ID'),
                        _buildTableHeader('Fecha'),
                        _buildTableHeader('Estado'),
                      ],
                    ),
                    ...movimientosRecientes.map((m) => _buildTableRow3Columnas(
                          m.activoId.substring(0, 8),
                          m.fechaEscaneo.toString().split('.')[0],
                          m.estado,
                        )),
                  ],
                )
              else
                pw.Text(
                  'Sin movimientos registrados',
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey),
                ),

              pw.SizedBox(height: 15),

              // 4. DISPOSITIVOS NUEVOS
              pw.Text(
                '4. DISPOSITIVOS NUEVOS',
                style: const pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 6),

              if (activosNuevos.isNotEmpty)
                pw.Table(
                  border: pw.TableBorder.all(width: 0.5),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(2),
                    1: const pw.FlexColumnWidth(1),
                    2: const pw.FlexColumnWidth(1.5),
                  },
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(
                        color: PdfColor.fromInt(0xFF1E3A8A),
                      ),
                      children: [
                        _buildTableHeader('Nombre'),
                        _buildTableHeader('Tipo'),
                        _buildTableHeader('Marca'),
                      ],
                    ),
                    ...activosNuevos.map((a) => _buildTableRow3Columnas(
                          a.nombre,
                          a.tipo,
                          a.marca,
                        )),
                  ],
                )
              else
                pw.Text(
                  'Sin dispositivos nuevos',
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey),
                ),

              pw.SizedBox(height: 15),

              // 5. DISPOSITIVOS DE BAJA
              pw.Text(
                '5. DISPOSITIVOS DE BAJA',
                style: const pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 6),

              if (activosDeBaja.isNotEmpty)
                pw.Table(
                  border: pw.TableBorder.all(width: 0.5),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(2),
                    1: const pw.FlexColumnWidth(1),
                    2: const pw.FlexColumnWidth(1.5),
                  },
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(
                        color: PdfColor.fromInt(0xFF1E3A8A),
                      ),
                      children: [
                        _buildTableHeader('Nombre'),
                        _buildTableHeader('Tipo'),
                        _buildTableHeader('Marca'),
                      ],
                    ),
                    ...activosDeBaja.map((a) => _buildTableRow3Columnas(
                          a.nombre,
                          a.tipo,
                          a.marca,
                        )),
                  ],
                )
              else
                pw.Text(
                  'Sin dispositivos de baja',
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey),
                ),

              pw.SizedBox(height: 20),

              // Pie de página
              pw.Align(
                alignment: pw.Alignment.bottomRight,
                child: pw.Text(
                  'Fecha de Generación: ${DateTime.now().toString().split('.')[0]}',
                  style: const pw.TextStyle(fontSize: 8),
                ),
              ),
            ],
          );
        },
      ),
    );

    // Descargar con ruta personalizada
    await _descargarPdf(
      pdf,
      'Reportes_${DateTime.now().toString().split(' ')[0]}.pdf',
      rutaPersonalizada,
    );
  }

  // Construir fila de tabla (2 columnas)
  static pw.TableRow _buildTableRow(String col1, String col2) {
    return pw.TableRow(
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.all(5),
          child: pw.Text(col1, style: const pw.TextStyle(fontSize: 8)),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.all(5),
          child: pw.Text(col2, style: const pw.TextStyle(fontSize: 8)),
        ),
      ],
    );
  }

  // Construir fila de tabla (3 columnas)
  static pw.TableRow _buildTableRow3Columnas(
    String col1,
    String col2,
    String col3,
  ) {
    return pw.TableRow(
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.all(5),
          child: pw.Text(col1, style: const pw.TextStyle(fontSize: 8)),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.all(5),
          child: pw.Text(col2, style: const pw.TextStyle(fontSize: 8)),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.all(5),
          child: pw.Text(col3, style: const pw.TextStyle(fontSize: 8)),
        ),
      ],
    );
  }

  // Construir header de tabla
  static pw.Widget _buildTableHeader(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        text,
        style: const pw.TextStyle(
          color: PdfColors.white,
          fontWeight: pw.FontWeight.bold,
          fontSize: 8,
        ),
      ),
    );
  }

  // Descargar PDF
  static Future<void> _descargarPdf(
    pw.Document pdf,
    String filename,
    String? rutaPersonalizada,
  ) async {
    try {
      String rutaFinal;

      if (rutaPersonalizada != null && rutaPersonalizada.isNotEmpty) {
        // Usar ruta personalizada
        rutaFinal = '$rutaPersonalizada/$filename';
      } else {
        // Usar Descargas por defecto
        final directory = await getDownloadsDirectory();
        if (directory == null) {
          debugPrint('No se puede acceder al directorio de descargas');
          return;
        }
        rutaFinal = '${directory.path}/$filename';
      }

      final file = File(rutaFinal);
      await file.writeAsBytes(await pdf.save());

      debugPrint('✅ PDF descargado: $rutaFinal');
    } catch (e) {
      debugPrint('❌ Error descargando PDF: $e');
    }
  }
}
