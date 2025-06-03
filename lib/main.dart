import 'package:flutter/material.dart';
import 'package:rembirth/model/birthday_entry.dart';
import 'package:rembirth/model/birthday_entry_category.dart';
import 'package:rembirth/save/isar_database.dart';
import 'package:rembirth/save/isar_save_service.dart';
import 'package:rembirth/save/save_manager.dart';
import 'package:rembirth/save/save_mode.dart';
import 'package:rembirth/util/logger.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await IsarDatabase.open([BirthdayEntrySchema, BirthdayEntryCategorySchema]);

  final isarService = IsarSaveService<BirthdayEntry>();
  final birthdayEntryCategoryService = IsarSaveService<BirthdayEntryCategory>();

  final newEntryCategory = BirthdayEntryCategory()
    ..id = IsarDatabase.instance.birthdayEntryCategorys.autoIncrement()
    ..name = "Family";

  final saveManagerCategory = SaveManager(localService: birthdayEntryCategoryService, saveMode: SaveMode.local);

  await saveManagerCategory.save(newEntryCategory);

  final newEntry = BirthdayEntry()
    ..id = IsarDatabase.instance.birthdayEntrys.autoIncrement()
    ..category = null
    ..name = 'Adrian'
    ..day = 6
    ..month = 8
    ..year = 2000;

  final saveManager = SaveManager(localService: isarService, saveMode: SaveMode.local);

  await saveManager.save(newEntry);
  logger.i('Main: Saving entry: $newEntry');

  var loaded = await saveManager.load(newEntry.id);
  logger.i('Main: Loaded entry: $loaded');

  await saveManager.delete(newEntry.id);

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(body: Center(child: Text('Hello World!'))),
    );
  }
}
