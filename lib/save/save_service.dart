abstract class SaveService<T> {
  Future<void> save(T item);

  Future<T?> load(dynamic id);

  Future<void> delete(dynamic id);

  Future<List<T>> loadAll();
}
