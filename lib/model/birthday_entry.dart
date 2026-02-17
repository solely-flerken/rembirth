import 'package:isar_community/isar.dart';
import 'package:rembirth/model/syncable_item.dart';

part 'birthday_entry.g.dart';

@collection
class BirthdayEntry extends SyncableItem {
  @override
  Id id = Isar.autoIncrement;

  String? name;
  int? year;
  int? month;
  int? day;

  // Since Isar v4 doesn't support links yet, we need to use a workaround.
  @Index()
  int? categoryId;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'year': year,
      'month': month,
      'day': day,
      'categoryId': categoryId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'BirthdayEntry(id: ${id.toString()}, name: $name, date: $year-$month-$day)';
  }
}
