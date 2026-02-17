import 'package:isar_community/isar.dart';
import 'package:rembirth/model/syncable_item.dart';

part 'birthday_entry.g.dart';

@collection
class BirthdayEntry extends SyncableItem {
  BirthdayEntry();

  @override
  Id id = Isar.autoIncrement;

  String? name;
  int? year;
  int? month;
  int? day;

  // Since Isar v4 doesn't support links yet, we need to use a workaround.
  @Index()
  int? categoryId;

  factory BirthdayEntry.fromJson(Map<String, dynamic> json) {
    final entry = BirthdayEntry()
      ..name = json['name'] as String?
      ..year = json['year'] as int?
      ..month = json['month'] as int?
      ..day = json['day'] as int?
      ..categoryId = json['categoryId'] as int?;

    // Restore ID if present (Crucial for linking to categories)
    if (json['id'] != null) {
      entry.id = json['id'] as int;
    }

    // Restore SyncableItem fields
    if (json['createdAt'] != null) {
      entry.createdAt = DateTime.parse(json['createdAt'] as String);
    }
    if (json['updatedAt'] != null) {
      entry.updatedAt = DateTime.parse(json['updatedAt'] as String);
    }

    return entry;
  }
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
