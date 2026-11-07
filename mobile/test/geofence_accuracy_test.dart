import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:inventario_qr_app/core/services/location_service.dart';
import 'package:inventario_qr_app/models/ambiente_model.dart';

void main() {
  group('Geocercas Oficiales y Regla de Precisión GPS (<= 30m)', () {
    late LocationService locationService;

    setUp(() {
      locationService = LocationService();
    });

    test('1. Configuración oficial de las 6 geocercas con coordenadas y radios exactos', () {
      expect(LocationService.officialGeofences.length, 6);

      final lab1 = LocationService.officialGeofences.firstWhere((g) => g.name == 'Lab 1');
      expect(lab1.lat, -16.577738);
      expect(lab1.lng, -68.196556);
      expect(lab1.radius, 18);

      final lab2 = LocationService.officialGeofences.firstWhere((g) => g.name == 'Lab 2');
      expect(lab2.lat, -16.577660);
      expect(lab2.lng, -68.196602);
      expect(lab2.radius, 17);

      final lab3 = LocationService.officialGeofences.firstWhere((g) => g.name == 'Lab 3');
      expect(lab3.lat, -16.577892);
      expect(lab3.lng, -68.196768);
      expect(lab3.radius, 22);

      final taller1 = LocationService.officialGeofences.firstWhere((g) => g.name == 'Taller 1');
      expect(taller1.lat, -16.577840);
      expect(taller1.lng, -68.196590);
      expect(taller1.radius, 18);

      final taller2 = LocationService.officialGeofences.firstWhere((g) => g.name == 'Taller 2');
      expect(taller2.lat, -16.577850);
      expect(taller2.lng, -68.196580);
      expect(taller2.radius, 18);

      final oficina = LocationService.officialGeofences.firstWhere((g) => g.name == 'Oficina');
      expect(oficina.lat, -16.577785);
      expect(oficina.lng, -68.196520);
      expect(oficina.radius, 15);
    });

    test('2. findGeofenceForName mapea nombres alternativos y canónicos correctamente', () {
      expect(LocationService.findGeofenceForName('Laboratorio 1')?.name, 'Lab 1');
      expect(LocationService.findGeofenceForName('Lab 2')?.name, 'Lab 2');
      expect(LocationService.findGeofenceForName('Laboratorio 3')?.name, 'Lab 3');
      expect(LocationService.findGeofenceForName('Taller 1')?.name, 'Taller 1');
      expect(LocationService.findGeofenceForName('Taller 2')?.name, 'Taller 2');
      expect(LocationService.findGeofenceForName('Oficina Central')?.name, 'Oficina');
    });

    test('3. AmbienteModel asigna automáticamente la geocerca oficial si lat/lng son 0.0', () {
      final model = AmbienteModel.fromJson({
        'id': 'amb-1',
        'nombre': 'Laboratorio 1',
        'descripcion': 'Lab de computadoras',
        'latitude': null,
        'longitude': null,
        'radio_geofence': null,
      });

      expect(model.latitude, -16.577738);
      expect(model.longitude, -68.196556);
      expect(model.radioGeofence, 18.0);
    });

    test('3.1 AmbienteModel con radio antiguo 50.0 o desde SQLite resuelve a radio oficial', () {
      final modelLab1 = AmbienteModel(
        id: '1',
        nombre: 'Laboratorio 1',
        descripcion: '',
        tieneInternet: true,
        latitude: -16.577738,
        longitude: -68.196556,
        radioGeofence: 50.0,
      );
      expect(modelLab1.radioGeofence, 18.0);

      final modelLab2 = AmbienteModel(
        id: '2',
        nombre: 'Laboratorio 2',
        descripcion: '',
        tieneInternet: true,
        latitude: -16.577660,
        longitude: -68.196602,
        radioGeofence: 50.0,
      );
      expect(modelLab2.radioGeofence, 17.0);

      final modelLab3 = AmbienteModel(
        id: '3',
        nombre: 'Laboratorio 3',
        descripcion: '',
        tieneInternet: true,
        latitude: -16.577892,
        longitude: -68.196768,
        radioGeofence: 50.0,
      );
      expect(modelLab3.radioGeofence, 22.0);

      final modelOficina = AmbienteModel(
        id: '4',
        nombre: 'Oficina Central',
        descripcion: '',
        tieneInternet: true,
        latitude: -16.577785,
        longitude: -68.196520,
        radioGeofence: 50.0,
      );
      expect(modelOficina.radioGeofence, 15.0);
    });

    test('4. Regla de validación: GPS con precisión <= 30m es válido y evalúa geocerca', () {
      // Usuario ubicado en el centro exacto de Lab 1 con precisión de 12 metros
      final posValida = Position(
        latitude: -16.577738,
        longitude: -68.196556,
        timestamp: DateTime.now(),
        accuracy: 12.0,
        altitude: 3600.0,
        heading: 0.0,
        speed: 0.0,
        altitudeAccuracy: 0.0,
        headingAccuracy: 0.0,
        speedAccuracy: 0.0,
      );

      final eval = locationService.evaluateGeofence(
        position: posValida,
        targetLat: -16.577738,
        targetLon: -68.196556,
        radiusMeters: 18.0,
        ambienteNombre: 'Lab 1',
      );

      expect(eval.accuracyValid, isTrue);
      expect(eval.accuracyMeters, 12.0);
      expect(eval.distanceMeters, lessThan(1.0));
      expect(eval.isInside, isTrue);
    });

    test('5. Regla de validación: If GPS accuracy > 30 meters, se rechaza y no se da como válido', () {
      // Usuario ubicado en Lab 1 pero con precisión degradada a 35 metros (> 30m)
      final posImprecisa = Position(
        latitude: -16.577738,
        longitude: -68.196556,
        timestamp: DateTime.now(),
        accuracy: 35.0,
        altitude: 3600.0,
        heading: 0.0,
        speed: 0.0,
        altitudeAccuracy: 0.0,
        headingAccuracy: 0.0,
        speedAccuracy: 0.0,
      );

      final eval = locationService.evaluateGeofence(
        position: posImprecisa,
        targetLat: -16.577738,
        targetLon: -68.196556,
        radiusMeters: 18.0,
        ambienteNombre: 'Lab 1',
      );

      // Precisión mayor a 30m debe invalidar la lectura
      expect(eval.accuracyValid, isFalse);
      expect(eval.isInside, isFalse);
      expect(eval.message, contains('Precisión GPS insuficiente'));
    });

    test('6. Usuario fuera del radio permitido resulta en isInside == false', () {
      // Coordenada desplazada (~80 metros)
      final posFuera = Position(
        latitude: -16.578500,
        longitude: -68.196556,
        timestamp: DateTime.now(),
        accuracy: 10.0,
        altitude: 3600.0,
        heading: 0.0,
        speed: 0.0,
        altitudeAccuracy: 0.0,
        headingAccuracy: 0.0,
        speedAccuracy: 0.0,
      );

      final eval = locationService.evaluateGeofence(
        position: posFuera,
        targetLat: -16.577738,
        targetLon: -68.196556,
        radiusMeters: 18.0,
        ambienteNombre: 'Lab 1',
      );

      expect(eval.accuracyValid, isTrue);
      expect(eval.isInside, isFalse);
      expect(eval.distanceMeters, greaterThan(18.0));
      expect(eval.message, contains('Fuera de'));
    });

    test('7. Regla de desambiguación: Usuario en Lab 3 intentando auditar Lab 1 es rechazado (isInside == false y detecta cercanía a Lab 3)', () {
      // Usuario ubicado en el centro exacto de Lab 3 (-16.577892, -68.196768) con buena precisión (8m)
      final posEnLab3 = Position(
        latitude: -16.577892,
        longitude: -68.196768,
        timestamp: DateTime.now(),
        accuracy: 8.0,
        altitude: 3600.0,
        heading: 0.0,
        speed: 0.0,
        altitudeAccuracy: 0.0,
        headingAccuracy: 0.0,
        speedAccuracy: 0.0,
      );

      final eval = locationService.evaluateGeofence(
        position: posEnLab3,
        targetLat: -16.577738, // Lab 1
        targetLon: -68.196556, // Lab 1
        radiusMeters: 18.0,
        ambienteNombre: 'Laboratorio 1',
      );

      expect(eval.accuracyValid, isTrue);
      expect(eval.isInside, isFalse, reason: 'No debe permitir auditar Lab 1 si el usuario está en Lab 3');
      expect(eval.message, contains('Lab 3'));
    });

    test('8. Regla de desambiguación: Usuario con lectura a 17m de Lab 1 pero más cerca de otro ambiente es rechazado para Lab 1', () {
      // Posición a ~17m de Lab 1 pero más cerca de otro ambiente (zona de solapamiento teórico)
      final posIntermedia = Position(
        latitude: -16.577830,
        longitude: -68.196683,
        timestamp: DateTime.now(),
        accuracy: 10.0,
        altitude: 3600.0,
        heading: 0.0,
        speed: 0.0,
        altitudeAccuracy: 0.0,
        headingAccuracy: 0.0,
        speedAccuracy: 0.0,
      );

      final eval = locationService.evaluateGeofence(
        position: posIntermedia,
        targetLat: -16.577738, // Lab 1
        targetLon: -68.196556, // Lab 1
        radiusMeters: 18.0,
        ambienteNombre: 'Laboratorio 1',
      );

      expect(eval.accuracyValid, isTrue);
      expect(eval.isInside, isFalse, reason: 'Debe rechazar Lab 1 porque el usuario está más cerca de otro ambiente');
      expect(eval.message, contains('Estás más cerca de'));
    });
  });
}
