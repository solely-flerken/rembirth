import 'dart:convert';
import 'dart:io';

import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rembirth/model/birthday_entry.dart';
import 'package:rembirth/model/birthday_entry_category.dart';
import 'package:rembirth/save/save_manager.dart';
import 'package:share_plus/share_plus.dart';

import '../util/logger.dart';

class BackupService {
  final SaveManager<BirthdayEntry> _entryManager;
  final SaveManager<BirthdayEntryCategory> _categoryManager;

  BackupService({
    required SaveManager<BirthdayEntry> entryManager,
    required SaveManager<BirthdayEntryCategory> categoryManager,
  })  : _entryManager = entryManager,
        _categoryManager = categoryManager;

  String get _fileName {
    final dateStr = DateTime.now().toIso8601String().split('T').first;
    return 'rembirth_backup_$dateStr.json';
  }

  Future<File> _createTempBackupFile() async {
    final categories = await _categoryManager.loadAll();
    final entries = await _entryManager.loadAll();

    final exportMap = {
      'meta': {
        'version': 1,
        'appName': 'Rembirth',
        'exportedAt': DateTime.now().toIso8601String(),
      },
      'categories': categories.map((c) => c.toJson()).toList(),
      'entries': entries.map((e) => e.toJson()).toList(),
    };

    final jsonString = const JsonEncoder.withIndent('  ').convert(exportMap);
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/$_fileName');

    return file.writeAsString(jsonString);
  }

  Future<bool> saveBackupToDevice() async {
    try {
      final tempFile = await _createTempBackupFile();

      final params = SaveFileDialogParams(
        sourceFilePath: tempFile.path,
        fileName: _fileName,
        mimeTypesFilter: ['application/json'],
      );

      final finalPath = await FlutterFileDialog.saveFile(params: params);

      if (finalPath != null) {
        logger.i('BackupService: File saved to $finalPath');
        return true;
      }

      return false;
    } catch (e, stack) {
      logger.e('BackupService: Save to device failed', error: e, stackTrace: stack);
      rethrow;
    }
  }

  Future<void> shareBackup() async {
    try {
      final tempFile = await _createTempBackupFile();

      final xFile = XFile(
        tempFile.path,
        mimeType: 'application/json',
        name: _fileName,
      );

      final result = await SharePlus.instance.share(
        ShareParams(
          files: [xFile],
          subject: 'Rembirth Backup',
          text: 'Here is my birthday backup file.',
        ),
      );

      if (result.status == ShareResultStatus.success) {
        logger.i('BackupService: Share completed');
      }
    } catch (e, stack) {
      logger.e('BackupService: Share failed', error: e, stackTrace: stack);
      rethrow;
    }
  }

  Future<bool> importData() async {
    try {
      // Pick the file
      final params = const OpenFileDialogParams(
        dialogType: OpenFileDialogType.document,
        sourceType: SourceType.photoLibrary,
      );

      final filePath = await FlutterFileDialog.pickFile(params: params);
      if (filePath == null) return false;

      logger.i('BackupService: Reading import file from $filePath');

      final file = File(filePath);
      final jsonString = await file.readAsString();

      if (jsonString.isEmpty) throw const FormatException("File is empty");

      final Map<String, dynamic> data = json.decode(jsonString);

      // Validation
      if (data['meta'] == null || data['meta']['appName'] != 'Rembirth') {
        throw const FormatException('Invalid backup file. Missing metadata.');
      }

      logger.i('BackupService: Valid backup found. Starting import...');

      // Restore Categories
      if (data['categories'] != null) {
        final List<dynamic> categoryList = data['categories'];
        for (var categoryJson in categoryList) {
          final category = BirthdayEntryCategory.fromJson(categoryJson);
          await _categoryManager.save(category);
        }
      }

      // Restore Entries
      if (data['entries'] != null) {
        final List<dynamic> entryList = data['entries'];
        for (var entryJson in entryList) {
          final entry = BirthdayEntry.fromJson(entryJson);
          await _entryManager.save(entry);
        }
      }

      logger.i('BackupService: Import completed successfully');
      return true;
    } catch (e, stack) {
      logger.e('BackupService: Import failed', error: e, stackTrace: stack);
      rethrow;
    }
  }
}