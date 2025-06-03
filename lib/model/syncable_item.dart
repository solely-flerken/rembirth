import 'package:isar/isar.dart';

abstract class SyncableItem {
  int get id;
  set id(int value);

  @Index()
  DateTime createdAt = DateTime.now();

  @Index()
  DateTime updatedAt = DateTime.now();
}
