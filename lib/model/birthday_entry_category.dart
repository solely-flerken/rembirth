import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:isar_community/isar.dart';
import 'package:rembirth/model/syncable_item.dart';

part 'birthday_entry_category.g.dart';

@collection
class BirthdayEntryCategory extends SyncableItem {
  @override
  Id id = Isar.autoIncrement;

  String? name;

  int? colorValue;

  @ignore
  Color? get color => colorValue != null ? Color(colorValue!) : null;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'colorValue': colorValue,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
