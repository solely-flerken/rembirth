import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:rembirth/model/syncable_item.dart';

part 'birthday_entry_category.g.dart';

@collection
class BirthdayEntryCategory extends SyncableItem {
  @override
  int id = 0;

  String? name;

  int? colorValue;

  @ignore
  Color? get color => colorValue != null ? Color(colorValue!) : null;
}
