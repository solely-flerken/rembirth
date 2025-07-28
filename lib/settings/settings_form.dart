import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rembirth/settings/settings_controller.dart';
import 'package:rembirth/settings/themes.dart';

import '../birthday/birthday_entry_category_creation_form.dart';
import '../l10n/app_localizations.dart';
import '../model/birthday_entry_category.dart';
import '../save/save_manager.dart';
import '../util/locale_util.dart';

class SettingsPageWidget extends StatefulWidget {
  const SettingsPageWidget({super.key});

  @override
  State<SettingsPageWidget> createState() => _SettingsPageWidgetState();
}

class _SettingsPageWidgetState extends State<SettingsPageWidget> {
  late final SaveManager<BirthdayEntryCategory> _categoryManager;
  List<BirthdayEntryCategory> _categories = [];

  AppLocalizations get _l10n => AppLocalizations.of(context)!;

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

    final statusMessage = category == null
        ? _l10n.settings_categories_status_added
        : _l10n.settings_categories_status_edited(newCategory.name!);
    showStatus(statusMessage);
  }

  Future<void> _handleCategoryDelete(BirthdayEntryCategory category) async {
    setState(() {
      _categories.removeWhere((e) => e.id == category.id);
    });

    await _categoryManager.delete(category.id);
  }

  void _showLocaleSelectionDialog() {
    final settingsController = context.read<SettingsController>();
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    void handleLocaleSelected(Locale? newLocale) {
      settingsController.setLocale(newLocale?.toString());
      Navigator.pop(context);

      AppLocalizations.delegate.load(settingsController.settings.locale).then((l10n) {
        final languageName = LocaleUtil.getLanguageNativeName(settingsController.settings.locale.toString());
        final message = l10n.settings_locale_status_set(languageName);
        showStatus(message);
      });
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        final currentLocaleCode = settingsController.settings.localeCode;

        return SimpleDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(l10n.settings_language_label, style: TextStyle(color: theme.colorScheme.primary)),
          children: [
            // System Default option
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4),
              child: SimpleDialogOption(
                onPressed: () => handleLocaleSelected(null),
                child: Row(
                  children: [
                    Expanded(child: Text(l10n.settings_option_system, style: TextStyle(fontSize: 16))),
                    if (currentLocaleCode == null) const Icon(Icons.check, color: Colors.green),
                  ],
                ),
              ),
            ),
            const Divider(indent: 16, endIndent: 16),
            // Locale options
            ...AppLocalizations.supportedLocales.map((locale) {
              final localeCode = locale.toString();
              final isSelected = localeCode == currentLocaleCode;

              return SimpleDialogOption(
                onPressed: () => handleLocaleSelected(locale),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(LocaleUtil.getLanguageNativeName(localeCode), style: TextStyle(fontSize: 16)),
                      ),
                      if (isSelected) const Icon(Icons.check, color: Colors.green),
                    ],
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final settingsController = context.watch<SettingsController>();
    final categoryManager = context.read<SaveManager<BirthdayEntryCategory>>();

    return Scaffold(
      appBar: AppBar(title: Text(_l10n.settings_page_label)),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // --- Themes ---
          ListTile(
            title: Text(_l10n.settings_theme_label),
            subtitle: SegmentedButton<ThemeSetting>(
              segments: <ButtonSegment<ThemeSetting>>[
                ButtonSegment<ThemeSetting>(
                  value: ThemeSetting.light,
                  label: Text(_l10n.settings_theme_option_light),
                  icon: const Icon(Icons.wb_sunny_outlined),
                ),
                ButtonSegment<ThemeSetting>(
                  value: ThemeSetting.dark,
                  label: Text(_l10n.settings_theme_option_dark),
                  icon: const Icon(Icons.nightlight_round),
                ),
                ButtonSegment<ThemeSetting>(
                  value: ThemeSetting.system,
                  label: Text(_l10n.settings_option_system),
                  icon: const Icon(Icons.brightness_auto_outlined),
                ),
              ],
              selected: <ThemeSetting>{settingsController.settings.theme},
              onSelectionChanged: (Set<ThemeSetting> newSelection) {
                context.read<SettingsController>().setTheme(newSelection.first);
                showStatus(_l10n.settings_theme_status_switched_theme(newSelection.first.name));
              },
            ),
          ),

          // --- Layout ---
          const Divider(),
          ListTile(
            title: Text(_l10n.settings_toolbar_position_label),
            subtitle: SegmentedButton<bool>(
              segments: <ButtonSegment<bool>>[
                ButtonSegment<bool>(
                  value: false,
                  label: Text(_l10n.settings_toolbar_position_option_top),
                  icon: const Icon(Icons.vertical_align_top),
                ),
                ButtonSegment<bool>(
                  value: true,
                  label: Text(_l10n.settings_toolbar_position_option_bottom),
                  icon: const Icon(Icons.vertical_align_bottom),
                ),
              ],
              selected: <bool>{settingsController.settings.positionToolbarBottom},
              onSelectionChanged: (Set<bool> newSelection) {
                final pushToBottom = newSelection.first;
                context.read<SettingsController>().setPositionToolbarBottom(pushToBottom);
                final position = pushToBottom ? 'bottom' : 'top';
                showStatus(_l10n.settings_toolbar_position_status_moved(position));
              },
            ),
          ),

          // --- Languages ---
          const Divider(),
          ListTile(
            title: Text(_l10n.settings_language_label),
            subtitle: Text(
              LocaleUtil.getLanguageNativeName(_l10n.localeName),
            ),
            trailing: const Icon(Icons.language, size: 32),
            onTap: _showLocaleSelectionDialog,
          ),

          // --- Notifications Toggle ---
          const Divider(),
          SwitchListTile(
            title: Text(_l10n.settings_notifications_label),
            value: settingsController.settings.notificationsEnabled,
            onChanged: (isEnabled) async {
              await context.read<SettingsController>().setNotificationsEnabled(isEnabled);
              final message = isEnabled
                  ? _l10n.settings_notifications_status_enabled
                  : _l10n.settings_notifications_status_disabled;
              showStatus(message);
            },
          ),

          // --- Notification Time Picker ---
          ListTile(
            title: Text(_l10n.settings_notification_time_label),
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
                showStatus(_l10n.settings_notification_time_status_set(pickedTime.format(context)));
              }
            },
          ),

          // --- Categories ---
          const Divider(),
          ListTile(
            title: Text(_l10n.settings_categories_label),
            trailing: const Icon(Icons.add_circle_outline, size: 32),
            onTap: () async {
              _handleCategoryTap(null);
            },
          ),

          StreamBuilder<List<BirthdayEntryCategory>>(
            stream: categoryManager.watchAll(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return ListTile(
                  title: Text(_l10n.settings_categories_error_loading),
                  subtitle: Text(snapshot.error.toString()),
                );
              }

              _categories = snapshot.data ?? _categories;

              if (_categories.isEmpty) {
                return ListTile(
                  title: Text(_l10n.settings_categories_no_categories),
                  subtitle: Text(_l10n.settings_categories_instructions),
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
                        onTap: () async {
                          _handleCategoryTap(category);
                        },
                        child: Chip(
                          label: Text(category.name!, style: TextStyle(color: textColor, fontSize: 16)),
                          backgroundColor: categoryColor,
                          shape: RoundedRectangleBorder(side: BorderSide.none, borderRadius: BorderRadius.circular(12)),
                          deleteIcon: const Icon(Icons.close, size: 20),
                          deleteIconColor: textColor,
                          onDeleted: () {
                            _handleCategoryDelete(category);
                            showStatus(_l10n.settings_categories_status_deleted(category.name!));
                          },
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
          ListTile(title: Text(_l10n.settings_about_label), subtitle: const Text('Rembirth v1.0.0'), onTap: () => {}),

          // --- Restore Defaults ---
          const Divider(),
          ListTile(
            title: Text(_l10n.settings_restore_defaults_label, style: const TextStyle(color: Colors.red)),
            trailing: const Icon(Icons.restore, color: Colors.red, size: 32),
            onTap: () async {
              await context.read<SettingsController>().restoreDefaults();
              showStatus(_l10n.settings_restore_defaults_status_restored);
            },
          ),
        ],
      ),
    );
  }
}
