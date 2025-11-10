import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';

class IsarDatabase {
  static Isar? _instance;

  static Future<void> open(List<CollectionSchema> schemas) async {
    if (_instance != null) return;

    final dir = await getApplicationDocumentsDirectory();

    _instance = await Isar.open(
      schemas,
      directory: dir.path,
      inspector: true,
      name: 'rembirth_db'
    );
  }

  static Isar get instance {
    if (_instance == null) {
      throw Exception(
        "Isar database has not been initialized. Call open() first.",
      );
    }
    return _instance!;
  }

  static Future<void> close() async {
    _instance?.close();
    _instance = null;
  }
}
