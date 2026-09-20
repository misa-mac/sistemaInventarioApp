import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:inventario_qr_app/models/auditoria_model.dart';
import 'package:inventario_qr_app/models/activo_model.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class AuditoriaPdfService {
  // Generar PDF de auditoría
  static Future<void> generarPdfAuditoria({
    required AuditoriaModel auditoria,
    required List<ActivoModel> activosDelAmbiente,
    required List<String> activosEscaneados,
    required String ambienteNombre,
    required String tecnicoNombre,
    String? rutaPersonalizada,
  }) async {
    final pdf = pw.Document();

    // Cargar logo
    final imageData = await rootBundle.load('assets/images/logo_itbm.png');
    final image = pw.MemoryImage(imageData.buffer.asUint8List());

    // Datos para la tabla - TODOS los activos del ambiente
    final activosAMostrar = List<ActivoModel>.from(activosDelAmbiente);
    
    activosAMostrar.sort((a, b) => a.nombre.compareTo(b.nombre));

    // Dividir activos en páginas (máximo 25 por página)
    const int activosPorPagina = 25;
    final int totalPaginas = (activosAMostrar.length / activosPorPagina).ceil();

    // Primera página con datos generales
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.letter.landscape,
        margin: const pw.EdgeInsets.all(15),
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
                        'REPORTE DE AUDITORÍA',
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

              // Datos generales
              pw.Text(
                'DATOS DE LA AUDITORÍA',
                style: const pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 6),

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
                  _buildTableRow('ID Auditoría', auditoria.id),
                  _buildTableRow('Ambiente', ambienteNombre),
                  _buildTableRow('Técnico', tecnicoNombre),
                  _buildTableRow(
                    'Fecha de Inicio',
                    auditoria.fechaInicio.toString().split('.')[0],
                  ),
                  _buildTableRow(
                    'Fecha de Fin',
                    auditoria.fechaFin?.toString().split('.')[0] ?? 'Pendiente',
                  ),
                  _buildTableRow(
                    'Total Esperado',
                    auditoria.totalEsperados.toString(),
                  ),
                  _buildTableRow(
                    'Total Encontrado',
                    auditoria.totalEncontrados.toString(),
                  ),
                  _buildTableRow(
                    'Total Faltantes',
                    (auditoria.totalEsperados - auditoria.totalEncontrados).toString(),
                  ),
                  _buildTableRow(
                    'Estado',
                    auditoria.totalEncontrados == auditoria.totalEsperados
                        ? 'COMPLETADO ✓'
                        : 'INCOMPLETO',
                  ),
                ],
              ),
              pw.SizedBox(height: 12),

              // Resumen
              pw.Text(
                'RESUMEN DE ESCANEOS',
                style: const pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                'Total Activos Escaneados: ${activosAMostrar.length}',
                style: const pw.TextStyle(fontSize: 10),
              ),
              pw.Text(
                'Distribuidos en $totalPaginas página(s)',
                style: const pw.TextStyle(fontSize: 10),
              ),
              pw.SizedBox(height: 10),

              // Tabla de activos (primera página - máximo 20)
              pw.Text(
                'DETALLE DE ACTIVOS ESCANEADOS (Página 1 de $totalPaginas)',
                style: const pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 6),

              pw.Table(
                border: pw.TableBorder.all(width: 0.5),
                columnWidths: {
                  0: const pw.FlexColumnWidth(0.6),
                  1: const pw.FlexColumnWidth(1.8),
                  2: const pw.FlexColumnWidth(1.2),
                  3: const pw.FlexColumnWidth(1.5),
                  4: const pw.FlexColumnWidth(1.2),
                  5: const pw.FlexColumnWidth(1.2),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColor.fromInt(0xFF1E3A8A),
                    ),
                    children: [
                      _buildTableHeader('Nº'),
                      _buildTableHeader('Nombre'),
                      _buildTableHeader('Tipo'),
                      _buildTableHeader('Marca/Modelo'),
                      _buildTableHeader('Serie'),
                      _buildTableHeader('Estado'),
                    ],
                  ),
                  ...activosAMostrar
                      .take(activosPorPagina)
                      .toList()
                      .asMap()
                      .entries
                      .map((entry) {
                    final index = entry.key + 1;
                    final activo = entry.value;
                    final estaEscaneado = activosEscaneados.contains(activo.id);
                    final estado = estaEscaneado ? 'ENCONTRADO' : 'NO ENCONTRADO';
                    
                    return _buildTableRow6Columnas(
                      index.toString(),
                      activo.nombre,
                      activo.tipo,
                      '${activo.marca} ${activo.modelo}',
                      activo.numeroSerie,
                      estado,
                    );
                  }),
                ],
              ),

              pw.SizedBox(height: 10),

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

    // Páginas adicionales si hay más de 25 activos
    if (totalPaginas > 1) {
      for (int pagina = 1; pagina < totalPaginas; pagina++) {
        final inicio = pagina * activosPorPagina;
        final fin = (pagina + 1) * activosPorPagina;
        final activosPagina = activosAMostrar.sublist(
          inicio,
          fin > activosAMostrar.length ? activosAMostrar.length : fin,
        );

        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.letter.landscape,
            margin: const pw.EdgeInsets.all(15),
            build: (pw.Context context) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Mini encabezado
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'REPORTE DE AUDITORÍA - ${ambienteNombre.toUpperCase()}',
                        style: const pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Página ${pagina + 1} de $totalPaginas',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                  pw.Divider(thickness: 1),
                  pw.SizedBox(height: 8),

                  // Tabla de activos continuación
                  pw.Text(
                    'DETALLE DE ACTIVOS ESCANEADOS (Página ${pagina + 1} de $totalPaginas)',
                    style: const pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 6),

                  pw.Table(
                    border: pw.TableBorder.all(width: 0.5),
                    columnWidths: {
                      0: const pw.FlexColumnWidth(0.6),
                      1: const pw.FlexColumnWidth(1.8),
                      2: const pw.FlexColumnWidth(1.2),
                      3: const pw.FlexColumnWidth(1.5),
                      4: const pw.FlexColumnWidth(1.2),
                      5: const pw.FlexColumnWidth(1.2),
                    },
                    children: [
                      pw.TableRow(
                        decoration: const pw.BoxDecoration(
                          color: PdfColor.fromInt(0xFF1E3A8A),
                        ),
                        children: [
                          _buildTableHeader('Nº'),
                          _buildTableHeader('Nombre'),
                          _buildTableHeader('Tipo'),
                          _buildTableHeader('Marca/Modelo'),
                          _buildTableHeader('Serie'),
                          _buildTableHeader('Estado'),
                        ],
                      ),
                      ...activosPagina.asMap().entries.map((entry) {
                        final indexGlobal = inicio + entry.key + 1;
                        final activo = entry.value;
                        final estaEscaneado = activosEscaneados.contains(activo.id);
                        final estado = estaEscaneado ? '✓ ENCONTRADO' : '✗ NO ENCONTRADO';
                        
                        return _buildTableRow6Columnas(
                          indexGlobal.toString(),
                          activo.nombre,
                          activo.tipo,
                          '${activo.marca} ${activo.modelo}',
                          activo.numeroSerie,
                          estado,
                        );
                      }),
                    ],
                  ),

                  pw.SizedBox(height: 20),

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
      }
    }

    // Descargar
    await _descargarPdf(
      pdf,
      'Auditoria_${auditoria.id}_${DateTime.now().toString().split(' ')[0]}.pdf',
      rutaPersonalizada,
    );
  }

  // Construir fila de tabla (2 columnas)
  static pw.TableRow _buildTableRow(String col1, String col2) {
    return pw.TableRow(
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.all(5),
          child: pw.Text(col1, style: const pw.TextStyle(fontSize: 9)),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.all(5),
          child: pw.Text(col2, style: const pw.TextStyle(fontSize: 9)),
        ),
      ],
    );
  }


  static pw.TableRow _buildTableRow6Columnas(
    String col1,
    String col2,
    String col3,
    String col4,
    String col5,
    String col6,
  ) {
    return pw.TableRow(
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Text(col1, style: const pw.TextStyle(fontSize: 7)),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Text(col2, style: const pw.TextStyle(fontSize: 7)),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Text(col3, style: const pw.TextStyle(fontSize: 7)),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Text(col4, style: const pw.TextStyle(fontSize: 7)),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Text(col5, style: const pw.TextStyle(fontSize: 7)),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Text(
            col6,
            style: pw.TextStyle(
              fontSize: 7,
              fontWeight: pw.FontWeight.bold,
              color: col6.contains('ENCONTRADO') && !col6.contains('NO')
                  ? PdfColors.green
                  : PdfColors.red,
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildTableHeader(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        text,
        style: const pw.TextStyle(
          color: PdfColors.white,
          fontWeight: pw.FontWeight.bold,
          fontSize: 9,
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
