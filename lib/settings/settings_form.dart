import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rembirth/settings/settings_controller.dart';
import 'package:rembirth/settings/themes.dart';

import '../birthday/birthday_entry_category_creation_form.dart';
import '../l10n/app_localizations.dart';
import '../model/birthday_entry_category.dart';
import '../save/save_manager.dart';
import '../util/language_local.dart';

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
  }

  Future<void> _handleCategoryDelete(BirthdayEntryCategory category) async {
    setState(() {
      _categories.removeWhere((e) => e.id == category.id);
    });

    await _categoryManager.delete(category.id);
  }

  void _showLanguageSelectionDialog(BuildContext context) {
    final settingsController = context.read<SettingsController>();
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    void handleLanguageSelected(String? newLanguageCode) {
      settingsController.setLanguage(newLanguageCode);
      Navigator.pop(context);

      final locale = newLanguageCode != null
          ? Locale(newLanguageCode)
          : WidgetsBinding.instance.platformDispatcher.locale;

      AppLocalizations.delegate.load(locale).then((newL10n) {
        final message = newL10n.settingsLanguageSetTo(newLanguageCode ?? newL10n.settingsSystemDefault);
        showStatus(message);
      });
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        final currentLanguageCode = settingsController.settings.languageCode;

        return SimpleDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(l10n.settingsLanguage, style: TextStyle(color: theme.colorScheme.primary)),
          children: [
            // System Default option
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4),
              child: SimpleDialogOption(
                onPressed: () => handleLanguageSelected(null),
                child: Row(
                  children: [
                    Expanded(child: Text(l10n.settingsSystemDefault, style: TextStyle(fontSize: 16))),
                    if (currentLanguageCode == null) const Icon(Icons.check, color: Colors.green),
                  ],
                ),
              ),
            ),
            const Divider(indent: 16, endIndent: 16),
            // Language options
            ...AppLocalizations.supportedLocales.map((locale) {
              final languageCode = locale.languageCode;
              final isSelected = languageCode == currentLanguageCode;

              return SimpleDialogOption(
                onPressed: () => handleLanguageSelected(languageCode),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(LanguageLocal.getLanguageNativeName(languageCode), style: TextStyle(fontSize: 16)),
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
    final l10n = AppLocalizations.of(context)!;
    final settingsController = context.watch<SettingsController>();
    final categoryManager = context.read<SaveManager<BirthdayEntryCategory>>();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // --- Themes ---
          ListTile(
            title: Text(l10n.theme),
            subtitle: SegmentedButton<ThemeSetting>(
              segments: <ButtonSegment<ThemeSetting>>[
                ButtonSegment<ThemeSetting>(
                  value: ThemeSetting.light,
                  label: Text(l10n.themeLight),
                  icon: const Icon(Icons.wb_sunny_outlined),
                ),
                ButtonSegment<ThemeSetting>(
                  value: ThemeSetting.dark,
                  label: Text(l10n.themeDark),
                  icon: const Icon(Icons.nightlight_round),
                ),
                ButtonSegment<ThemeSetting>(
                  value: ThemeSetting.system,
                  label: Text(l10n.themeSystem),
                  icon: const Icon(Icons.brightness_auto_outlined),
                ),
              ],
              selected: <ThemeSetting>{settingsController.settings.theme},
              onSelectionChanged: (Set<ThemeSetting> newSelection) {
                context.read<SettingsController>().setTheme(newSelection.first);
                showStatus(l10n.switchedTheme(newSelection.first.name));
              },
            ),
          ),

          // --- Layout ---
          const Divider(),
          ListTile(
            title: Text(l10n.toolbarLayout),
            subtitle: SegmentedButton<bool>(
              segments: <ButtonSegment<bool>>[
                ButtonSegment<bool>(
                  value: false,
                  label: Text(l10n.toolbarPositionTop),
                  icon: const Icon(Icons.vertical_align_top),
                ),
                ButtonSegment<bool>(
                  value: true,
                  label: Text(l10n.toolbarPositionBottom),
                  icon: const Icon(Icons.vertical_align_bottom),
                ),
              ],
              selected: <bool>{settingsController.settings.positionToolbarBottom},
              onSelectionChanged: (Set<bool> newSelection) {
                final pushToBottom = newSelection.first;
                context.read<SettingsController>().setPositionToolbarBottom(pushToBottom);
                final position = pushToBottom ? 'bottom' : 'top';
                showStatus(l10n.toolbarMoved(position));
              },
            ),
          ),

          // --- Languages ---
          const Divider(),
          ListTile(
            title: Text(l10n.settingsLanguage),
            subtitle: Text(
              LanguageLocal.getLanguageNativeName(settingsController.settings.languageCode ?? l10n.localeName),
            ),
            trailing: const Icon(Icons.language, size: 32),
            onTap: () {
              _showLanguageSelectionDialog(context);
            },
          ),

          // --- Notifications Toggle ---
          const Divider(),
          SwitchListTile(
            title: Text(l10n.enableNotifications),
            value: settingsController.settings.notificationsEnabled,
            onChanged: (isEnabled) async {
              await context.read<SettingsController>().setNotificationsEnabled(isEnabled);
              final message = isEnabled ? l10n.notificationsEnabled : l10n.notificationsDisabled;
              showStatus(message);
            },
          ),

          // --- Notification Time Picker ---
          ListTile(
            title: Text(l10n.notificationTime),
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
                showStatus(l10n.notificationTimeSet(pickedTime.format(context)));
              }
            },
          ),

          // --- Categories ---
          const Divider(),
          ListTile(
            title: Text(l10n.categories),
            trailing: const Icon(Icons.add_circle_outline, size: 32),
            onTap: () {
              _handleCategoryTap(null);
              showStatus(l10n.addedCategory);
            },
          ),

          StreamBuilder<List<BirthdayEntryCategory>>(
            stream: categoryManager.watchAll(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return ListTile(title: Text(l10n.errorLoadingCategories), subtitle: Text(snapshot.error.toString()));
              }

              _categories = snapshot.data ?? _categories;

              if (_categories.isEmpty) {
                return ListTile(title: Text(l10n.noCategoriesYet), subtitle: Text(l10n.tapToAddCategory));
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
                          await _handleCategoryTap(category);
                          showStatus(l10n.editedCategory(category.name!));
                        },
                        child: Chip(
                          label: Text(category.name!, style: TextStyle(color: textColor, fontSize: 16)),
                          backgroundColor: categoryColor,
                          shape: RoundedRectangleBorder(side: BorderSide.none, borderRadius: BorderRadius.circular(12)),
                          deleteIcon: const Icon(Icons.close, size: 20),
                          deleteIconColor: textColor,
                          onDeleted: () {
                            _handleCategoryDelete(category);
                            showStatus(l10n.deletedCategory(category.name!));
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
          ListTile(title: Text(l10n.about), subtitle: const Text('Rembirth v1.0.0'), onTap: () => {}),

          // --- Restore Defaults ---
          const Divider(),
          ListTile(
            title: Text(l10n.restoreDefaults, style: const TextStyle(color: Colors.red)),
            trailing: const Icon(Icons.restore, color: Colors.red, size: 32),
            onTap: () async {
              await context.read<SettingsController>().restoreDefaults();
              showStatus(l10n.restoredDefaultSettings);
            },
          ),
        ],
      ),
    );
  }
}
