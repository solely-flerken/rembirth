abstract class SaveService<T> {
  Future<int> save(T item);

  Future<T?> load(dynamic id);

  Future<void> delete(dynamic id);

  Future<List<T>> loadAll();

  Stream<List<T>> watchAll();
}
