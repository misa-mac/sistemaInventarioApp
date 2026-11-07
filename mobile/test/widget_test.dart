import 'package:flutter_test/flutter_test.dart';
import 'package:inventario_qr_app/view/widgets/floating_bottom_nav_bar.dart';
import 'package:inventario_qr_app/models/activo_model.dart';

void main() {
  testWidgets('App smoke test: roles and nav items', (WidgetTester tester) async {
    final tecnicoItems = FloatingBottomNavBar.getItemsForRole('tecnico');
    expect(tecnicoItems.length, equals(2));

    final auditorItems = FloatingBottomNavBar.getItemsForRole('auditor');
    expect(auditorItems.length, equals(3));

    final adminItems = FloatingBottomNavBar.getItemsForRole('admin');
    expect(adminItems.length, equals(4));
  });

  test('ActivoModel parsea correctamente toda la ficha técnica detallada (ambiente, marca, origen, etc.)', () {
    final json = {
      'id': '550e8400-e29b-41d4-a716-446655440000',
      'uuid': '550e8400-e29b-41d4-a716-446655440000',
      'codigo_activo': '1261020-04',
      'numero_correlativo': 4,
      'nombre': 'Computadora de Escritorio Core i7',
      'tipo': {'id': 't-1', 'nombre': 'CPU / Computadora', 'codigo': 10},
      'marca': 'HP',
      'modelo': 'Pavilion ProDesk 400 G6',
      'numero_serie': 'MXL12345XYZ',
      'estado': 'Activo',
      'ambiente_id': 'amb-1',
      'ambiente': {
        'id': 'amb-1',
        'nombre': 'Laboratorio 1',
        'codigo': 20,
        'ubicacion': 'Bloque de Sistemas, Planta Alta'
      },
      'ambiente_registro': {
        'id': 'amb-1',
        'nombre': 'Laboratorio 1'
      },
      'origen': 'Compra Directa',
      'especificacion_origen': 'Licitación Pública Nacional 2024',
      'descripcion': 'Equipo de cómputo para prácticas de laboratorio de redes.',
      'responsable': 'Ing. Juan Pérez',
      'fecha_ingreso': '2024-03-15',
      'valor': 5400.50,
      'observaciones': 'Equipo entregado con periféricos completos y cable de red.',
      'imagen_url': '/uploads/hp-prodesk.jpg'
    };

    final activo = ActivoModel.fromJson(json);

    expect(activo.id, '550e8400-e29b-41d4-a716-446655440000');
    expect(activo.qrCodigo, '1261020-04');
    expect(activo.numeroCorrelativo, 4);
    expect(activo.nombre, 'Computadora de Escritorio Core i7');
    expect(activo.tipo, 'CPU / Computadora');
    expect(activo.marca, 'HP');
    expect(activo.modelo, 'Pavilion ProDesk 400 G6');
    expect(activo.numeroSerie, 'MXL12345XYZ');
    expect(activo.ambienteNombre, 'Laboratorio 1');
    expect(activo.ambienteUbicacion, 'Bloque de Sistemas, Planta Alta');
    expect(activo.ambienteRegistroNombre, 'Laboratorio 1');
    expect(activo.origen, 'Compra Directa');
    expect(activo.especificacionOrigen, 'Licitación Pública Nacional 2024');
    expect(activo.descripcion, 'Equipo de cómputo para prácticas de laboratorio de redes.');
    expect(activo.responsable, 'Ing. Juan Pérez');
    expect(activo.fechaIngreso, '2024-03-15');
    expect(activo.valor, 5400.50);
    expect(activo.observaciones, 'Equipo entregado con periféricos completos y cable de red.');
    expect(activo.imagenUrl, '/uploads/hp-prodesk.jpg');
  });
}
