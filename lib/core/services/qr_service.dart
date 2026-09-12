import 'package:permission_handler/permission_handler.dart';

class QrService {
  Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  String extractUuidFromQr(String qrData) {
    // El QR contiene UUID en el formato: uuid=<valor>
    if (qrData.contains('uuid=')) {
      return qrData.split('uuid=')[1].split('&')[0];
    }
    return qrData;
  }
}
