import 'package:isar_community/isar.dart';

abstract class SyncableItem {
  Id get id;

  set id(Id value);

  @Index()
  DateTime createdAt = DateTime.now();

  @Index()
  DateTime updatedAt = DateTime.now();
}
