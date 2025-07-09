import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rembirth/settings/settings_controller.dart';
import 'package:rembirth/settings/themes.dart';

import '../birthday/birthday_entry_category_creation_form.dart';
import '../model/birthday_entry_category.dart';
import '../save/save_manager.dart';

class SettingsPageWidget extends StatefulWidget {
  const SettingsPageWidget({super.key});

  @override
  State<SettingsPageWidget> createState() => _SettingsPageWidgetState();
}

class _SettingsPageWidgetState extends State<SettingsPageWidget> {
  late final SaveManager<BirthdayEntryCategory> _categoryManager;
  List<BirthdayEntryCategory> _categories = [];

  @override
  void initState() {
    super.initState();
    _categoryManager = context.read<SaveManager<BirthdayEntryCategory>>();
  }

  void showStatus(String message) {
    if (message.isEmpty || !mounted) return;

    ScaffoldMessenger.of(context)
      ..removeCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 6,
        ),
      );
  }

  Future<void> _handleCategoryTap(BirthdayEntryCategory? category) async {
    final newCategory = await showDialog<BirthdayEntryCategory>(
      context: context,
      builder: (context) => BirthdayEntryCategoryCreationForm(initialCategory: category),
    );

    if (newCategory == null) return;

    setState(() {
      final index = _categories.indexWhere((e) => e.id == newCategory.id);
      if (index != -1) {
        _categories[index] = newCategory;
      } else {
        _categories.add(newCategory);
      }
    });

    await _categoryManager.save(newCategory);
    showStatus('Added category "${newCategory.name}"');
  }

  Future<void> _handleCategoryDelete(BirthdayEntryCategory category) async {
    setState(() {
      _categories.removeWhere((e) => e.id == category.id);
    });

    await _categoryManager.delete(category.id);
    showStatus('Deleted category: "${category.name}"');
  }

  @override
  Widget build(BuildContext context) {
    final settingsController = context.watch<SettingsController>();
    final categoryManager = context.read<SaveManager<BirthdayEntryCategory>>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // --- Themes ---
          ListTile(
            title: const Text('Theme'),
            subtitle: SegmentedButton<ThemeSetting>(
              segments: const <ButtonSegment<ThemeSetting>>[
                ButtonSegment<ThemeSetting>(
                  value: ThemeSetting.light,
                  label: Text('Light'),
                  icon: Icon(Icons.wb_sunny_outlined),
                ),
                ButtonSegment<ThemeSetting>(
                  value: ThemeSetting.dark,
                  label: Text('Dark'),
                  icon: Icon(Icons.nightlight_round),
                ),
                ButtonSegment<ThemeSetting>(
                  value: ThemeSetting.system,
                  label: Text('System'),
                  icon: Icon(Icons.brightness_auto_outlined),
                ),
              ],
              selected: <ThemeSetting>{settingsController.settings.theme},
              onSelectionChanged: (Set<ThemeSetting> newSelection) {
                context.read<SettingsController>().setTheme(newSelection.first);
                showStatus('Switched to ${newSelection.first.name} theme');
              },
            ),
          ),

          // --- Layout ---
          const Divider(),
          ListTile(
            title: const Text('Toolbar Position'),
            subtitle: SegmentedButton<bool>(
              segments: const <ButtonSegment<bool>>[
                ButtonSegment<bool>(
                  value: false,
                  label: Text('Top'),
                  icon: Icon(Icons.vertical_align_top),
                ),
                ButtonSegment<bool>(
                  value: true,
                  label: Text('Bottom'),
                  icon: Icon(Icons.vertical_align_bottom),
                ),
              ],
              selected: <bool>{settingsController.settings.positionToolbarBottom},
              onSelectionChanged: (Set<bool> newSelection) {
                final pushToBottom = newSelection.first;
                context.read<SettingsController>().setPositionToolbarBottom(pushToBottom);
                showStatus('Toolbar moved to ${pushToBottom ? "bottom" : "top"}');
              },
            ),
          ),

          // --- Notifications Toggle ---
          const Divider(),
          SwitchListTile(
            title: const Text('Enable Notifications'),
            value: settingsController.settings.notificationsEnabled,
            onChanged: (isEnabled) async {
              await context.read<SettingsController>().setNotificationsEnabled(isEnabled);
              showStatus('Notifications ${isEnabled ? "enabled" : "disabled"}');
            },
          ),

          // --- Notification Time Picker ---
          ListTile(
            title: const Text('Notification Time'),
            subtitle: Text(settingsController.settings.notificationTime.format(context)),
            trailing: const Icon(Icons.schedule, size: 32),
            enabled: settingsController.settings.notificationsEnabled,
            onTap: () async {
              final pickedTime = await showTimePicker(
                context: context,
                initialTime: settingsController.settings.notificationTime,
              );

              if (!context.mounted) return;

              if (pickedTime != null) {
                await context.read<SettingsController>().updateNotificationTime(pickedTime);
                if (!context.mounted) return;
                showStatus('Notification time set to ${pickedTime.format(context)}');
              }
            },
          ),

          // --- Categories ---
          const Divider(),
          ListTile(
            title: Text('Categories'),
            trailing: const Icon(Icons.add_circle_outline, size: 32),
            onTap: () => _handleCategoryTap(null),
          ),

          StreamBuilder<List<BirthdayEntryCategory>>(
            stream: categoryManager.watchAll(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return ListTile(
                  title: const Text('Error loading categories'),
                  subtitle: Text(snapshot.error.toString()),
                );
              }

              _categories = snapshot.data ?? _categories;

              if (_categories.isEmpty) {
                return const ListTile(
                  title: Text('No categories yet.'),
                  subtitle: Text('Tap the "+" icon above to add a category.'),
                );
              }

              return ListTile(
                subtitle: Wrap(
                  spacing: 8.0,
                  runSpacing: 4.0,
                  children: _categories.map((category) {
                    final categoryColor = category.color ?? Colors.grey.shade400;
                    final textColor = ThemeData.estimateBrightnessForColor(categoryColor) == Brightness.dark
                        ? Colors.white
                        : Colors.black;

                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => _handleCategoryTap(category),
                        child: Chip(
                          label: Text(category.name!, style: TextStyle(color: textColor, fontSize: 16)),
                          backgroundColor: categoryColor,
                          shape: RoundedRectangleBorder(side: BorderSide.none, borderRadius: BorderRadius.circular(12)),
                          deleteIcon: const Icon(Icons.close, size: 20),
                          deleteIconColor: textColor,
                          onDeleted: () => _handleCategoryDelete(category)
                        ),
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),

          // --- About ---
          const Divider(),
          ListTile(title: const Text('About'), subtitle: const Text('Rembirth v1.0.0'), onTap: () => {}),

          // --- Restore Defaults ---
          const Divider(),
          ListTile(
            title: const Text('Restore Defaults', style: TextStyle(color: Colors.red)),
            trailing: const Icon(Icons.restore, color: Colors.red, size: 32),
            onTap: () async {
              await context.read<SettingsController>().restoreDefaults();
              showStatus('Restored default settings');
            },
          ),
        ],
      ),
    );
  }
}
