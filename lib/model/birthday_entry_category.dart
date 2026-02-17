import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:isar_community/isar.dart';
import 'package:rembirth/model/syncable_item.dart';

part 'birthday_entry_category.g.dart';

@collection
class BirthdayEntryCategory extends SyncableItem {
  BirthdayEntryCategory();

  @override
  Id id = Isar.autoIncrement;

  String? name;
  int? colorValue;

  @ignore
  Color? get color => colorValue != null ? Color(colorValue!) : null;

  factory BirthdayEntryCategory.fromJson(Map<String, dynamic> json) {
    final category = BirthdayEntryCategory()
      ..name = json['name'] as String?
      ..colorValue = json['colorValue'] as int?;

    if (json['id'] != null) {
      category.id = json['id'] as int;
    }

    if (json['createdAt'] != null) {
      category.createdAt = DateTime.parse(json['createdAt'] as String);
    }
    if (json['updatedAt'] != null) {
      category.updatedAt = DateTime.parse(json['updatedAt'] as String);
    }

    return category;
  }

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
