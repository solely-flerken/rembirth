import 'package:isar_community/isar.dart';
import 'package:rembirth/save/save_service.dart';

import 'isar_database.dart';

class IsarSaveService<T> implements SaveService<T> {
  @override
  Future<int> save(T item) {
    final isar = IsarDatabase.instance;

    return isar.writeTxn(() async {
      return isar.collection<T>().put(item);
    });
  }

  @override
  Future<void> delete(id) {
    final isar = IsarDatabase.instance;

    return isar.writeTxn(() async {
      await isar.collection<T>().delete(id);
    });
  }

  @override
  Future<T?> load(id) {
    final isar = IsarDatabase.instance;

    return isar.collection<T>().get(id);
  }

  @override
  Future<List<T>> loadAll() {
    final isar = IsarDatabase.instance;

    return isar.collection<T>().where().findAll();
  }

  @override
  Stream<List<T>> watchAll() {
    final isar = IsarDatabase.instance;

    return isar.collection<T>().where().watch(fireImmediately: true);
  }
}
