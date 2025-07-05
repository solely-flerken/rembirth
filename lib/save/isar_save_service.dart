import 'package:isar/isar.dart';
import 'package:rembirth/save/save_service.dart';

import 'isar_database.dart';

class IsarSaveService<T> implements SaveService<T> {
  @override
  Future<void> save(T item) {
    final isar = IsarDatabase.instance;

    return isar.writeAsync((isar) {
      return isar.collection<int, T>().put(item);
    });
  }

  @override
  Future<void> delete(id) {
    final isar = IsarDatabase.instance;

    return isar.writeAsync((isar) {
      isar.collection<int, T>().delete(id);
      return;
    });
  }

  @override
  Future<T?> load(id) {
    final isar = IsarDatabase.instance;

    return isar.collection<int, T>().getAsync(id);
  }

  @override
  Future<List<T>> loadAll() {
    final isar = IsarDatabase.instance;

    return isar.collection<int, T>().where().findAllAsync();
  }

  @override
  Stream<List<T>> watchAll() {
    final isar = IsarDatabase.instance;

    return isar.collection<int, T>().where().watch(fireImmediately: true);
  }

  Future<List<T>> query({Filter? filter, List<SortProperty>? sortBy, List<DistinctProperty>? distinctBy}) async {
    final isar = IsarDatabase.instance;

    final query = isar.collection<int, T>().buildQuery<T>(filter: filter, sortBy: sortBy, distinctBy: distinctBy);

    return query.findAll();
  }
}
