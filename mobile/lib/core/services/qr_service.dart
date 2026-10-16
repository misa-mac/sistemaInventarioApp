class QrService {
  String extractUuidFromQr(String qrData) {
    // El QR contiene UUID en el formato: uuid=<valor>
    if (qrData.contains('uuid=')) {
      return qrData.split('uuid=')[1].split('&')[0];
    }
    return qrData;
  }
}
