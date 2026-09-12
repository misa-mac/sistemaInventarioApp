import 'package:hive_flutter/hive_flutter.dart';

class HiveManager {
  static const String _activosBox = 'activos_cache';
  static const String _auditoriasBox = 'auditorias_cache';
  static const String _sessionBox = 'session';

  static Future<void> initHive() async {
    await Hive.initFlutter();
    
    // Abrir boxes
    await Hive.openBox(_activosBox);
    await Hive.openBox(_auditoriasBox);
    await Hive.openBox(_sessionBox);
  }

  static Box getActivosBox() => Hive.box(_activosBox);
  static Box getAuditoriasBox() => Hive.box(_auditoriasBox);
  static Box getSessionBox() => Hive.box(_sessionBox);

  static Future<void> clearAllCache() async {
    await Hive.box(_activosBox).clear();
    await Hive.box(_auditoriasBox).clear();
  }
}
