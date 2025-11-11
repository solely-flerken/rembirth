import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:rembirth/l10n/app_localizations.dart';
import 'package:rembirth/model/birthday_entry.dart';
import 'package:rembirth/model/birthday_entry_category.dart';
import 'package:rembirth/notifications/notification_service.dart';
import 'package:rembirth/save/save_manager.dart';
import 'package:rembirth/settings/settings_form.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../settings/settings_controller.dart';
import '../util/date_util.dart';
import 'action_bar.dart';
import 'birthday_entry.dart';
import 'birthday_entry_category_creation_form.dart';
import 'birthday_entry_creation_form.dart';

class BirthdayListWidget extends StatefulWidget {
  const BirthdayListWidget({super.key});

  @override
  State<BirthdayListWidget> createState() => _BirthdayListWidgetState();
}

class _BirthdayListWidgetState extends State<BirthdayListWidget> {
  // Managers
  late final SaveManager<BirthdayEntry> _entryManager;
  late final SaveManager<BirthdayEntryCategory> _categoryManager;
  late final NotificationService _notificationService;

  // Data
  List<BirthdayEntry> _entries = [];
  List<BirthdayEntryCategory> _categories = [];
  int? _selectedEntryId;

  // UI
  final Map<int, bool> _expandedStates = {};

  /// A virtual category used for entries that don't have a category assigned
  static final _generalCategory = BirthdayEntryCategory()
    ..id = -1
    ..name = 'General'
    ..colorValue = Colors.grey.shade400.toARGB32();

  @override
  void initState() {
    super.initState();
    _entryManager = context.read<SaveManager<BirthdayEntry>>();
    _categoryManager = context.read<SaveManager<BirthdayEntryCategory>>();
    _notificationService = context.read<NotificationService>();

    _promptForBackgroundPermission();
  }

  //#region Permissions

  Future<void> _promptForBackgroundPermission() async {
    await WidgetsBinding.instance.endOfFrame;

    // TODO: Maybe add this to settings (so restoring defaults would also lead to this dialog to be enabled again)
    final prefs = await SharedPreferences.getInstance();
    const String backgroundPromptKey = 'background_task_prompt';
    final bool alreadyPrompted = prefs.getBool(backgroundPromptKey) ?? false;

    if (alreadyPrompted) {
      return;
    }

    if(!mounted) return;

    final l10n = AppLocalizations.of(context)!;

    await showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: Text(l10n.backgroundPermissionDialogTitle),
            content: Text(l10n.backgroundPermissionDialogContent),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.backgroundPermissionDialogLater)),
              TextButton(
                onPressed: () async {
                  openAppSettings();
                  Navigator.of(context).pop();
                  await prefs.setBool(backgroundPromptKey, true);
                },
                child: Text(l10n.backgroundPermissionDialogSettings),
              ),
            ],
          ),
    );
  }

  //#endregion

  //#region Data

  /// Groups a list of birthday entries by category.
  Map<BirthdayEntryCategory, List<BirthdayEntry>> _groupEntries(
    List<BirthdayEntry> entries,
    List<BirthdayEntryCategory> categories,
  ) {
    final Map<BirthdayEntryCategory, List<BirthdayEntry>> grouped = {};

    final categoryMap = {for (var cat in categories) cat.id: cat};

    for (final entry in entries) {
      final category = categoryMap[entry.categoryId] ?? _generalCategory;
      grouped.putIfAbsent(category, () => []).add(entry);
    }

    for (final category in grouped.keys) {
      grouped[category]!.sort((a, b) => _compareByDaysUntilBirthday(a, b, DateTime.now()));
    }

    return grouped;
  }

  Future<void> _handleRefresh() async {
    // TODO: Currently just a placebo refresh
    await _notificationService.setupScheduledNotificationsFromPrefs(_entries);
  }

  List<BirthdayEntry> _getSortedFlatList() {
    return _entries.where((entry) => entry.month != null && entry.day != null).toList()
      ..sort((a, b) => _compareByDaysUntilBirthday(a, b, DateTime.now()));
  }

  static int _compareByDaysUntilBirthday(BirthdayEntry a, BirthdayEntry b, DateTime today) {
    int daysUntil(BirthdayEntry e) {
      if (e.month != null && e.day != null) {
        return DateUtil.daysUntilDate(today, DateTime(today.year, e.month!, e.day!));
      }
      return 9999;
    }

    return daysUntil(a).compareTo(daysUntil(b));
  }

  //#endregion

  //#region UI

  void _toggleExpansion(int categoryId) {
    setState(() {
      _expandedStates[categoryId] = !(_expandedStates[categoryId] ?? false);
    });
  }

  void _expandAll(Iterable<int> categoryIds) {
    setState(() {
      _expandedStates.addEntries(categoryIds.map((key) => MapEntry(key, true)));
    });
  }

  void _collapseAll(Iterable<int> categoryIds) {
    setState(() {
      _expandedStates.addEntries(categoryIds.map((key) => MapEntry(key, false)));
    });
  }

  void _toggleCategoryView() async {
    final isCategoryView = !context.read<SettingsController>().settings.categoryViewEnabled;
    await context.read<SettingsController>().setCategoryViewEnabled(isCategoryView);
  }

  //#endregion

  //#region Entry managing

  Future<void> _addEntry() async {
    final returnedEntry = await Navigator.push<BirthdayEntry?>(
      context,
      DialogRoute(
        builder: (context) => BirthdayEntryCreationForm(categories: _categories),
        context: context,
      ),
    );

    if (returnedEntry == null) return;

    final newEntryId = await _entryManager.save(returnedEntry);
    returnedEntry.id = newEntryId!;

    setState(() {
      _entries.add(returnedEntry);
      _selectedEntryId = returnedEntry.id;
    });


    if (!mounted) return;

    final notificationTime = context.read<SettingsController>().settings.notificationTime;
    await _notificationService.scheduleBirthdayNotification(returnedEntry, notificationTime: notificationTime);
  }

  Future<void> _editEntry() async {
    if (_selectedEntryId == null) return;
    final entryToEdit = _entries.firstWhereOrNull((e) => e.id == _selectedEntryId);
    if (entryToEdit == null) return;

    final returnedEntry = await Navigator.push<BirthdayEntry?>(
      context,
      DialogRoute(
        builder: (context) => BirthdayEntryCreationForm(initialEntry: entryToEdit, categories: _categories),
        context: context,
      ),
    );

    if (returnedEntry == null) return;

    final newEntryId = await _entryManager.save(returnedEntry);
    returnedEntry.id = newEntryId!;

    setState(() {
      final index = _entries.indexWhere((e) => e.id == returnedEntry.id);
      if (index != -1) {
        _entries[index] = returnedEntry;
      }
      _selectedEntryId = returnedEntry.id;
    });

    if (!mounted) return;

    final notificationTime = context.read<SettingsController>().settings.notificationTime;
    await _notificationService.scheduleBirthdayNotification(returnedEntry, notificationTime: notificationTime);
  }

  void _deleteItem() async {
    if (_selectedEntryId == null) return;
    final entryToDelete = _entries.firstWhereOrNull((e) => e.id == _selectedEntryId);
    if (entryToDelete == null) return;

    setState(() {
      _entries.removeWhere((e) => e.id == _selectedEntryId);
      _selectedEntryId = null;
    });

    await _notificationService.cancelBirthdayNotification(entryToDelete.id);
    await _entryManager.delete(entryToDelete.id);
  }

  void _handleEntryTap(BirthdayEntry entry) {
    setState(() {
      _selectedEntryId = entry.id == _selectedEntryId ? null : entry.id;
    });
  }

  //#endregion

  //#region Category managing

  Future<void> _handleCategoryEdit(BirthdayEntryCategory? category) async {
    final editedCategory = await showDialog<BirthdayEntryCategory>(
      context: context,
      builder: (context) => BirthdayEntryCategoryCreationForm(initialCategory: category),
    );

    if (editedCategory == null) return;

    setState(() {
      final index = _categories.indexWhere((e) => e.id == editedCategory.id);
      if (index != -1) {
        _categories[index] = editedCategory;
      }
    });

    await _categoryManager.save(editedCategory);
  }

  //#endregion

  void _openSettings() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => SettingsPageWidget()));
  }

  @override
  Widget build(BuildContext context) {
    final settingsController = context.watch<SettingsController>();

    final toolbar = ActionBar(
      categoryIds: _categories.map((c) => c.id),
      isEntrySelected: _selectedEntryId != null,
      onAdd: _addEntry,
      onEdit: _selectedEntryId != null ? _editEntry : null,
      onDelete: _selectedEntryId != null ? _deleteItem : null,
      onExpandAll: _expandAll,
      onCollapseAll: _collapseAll,
      onOpenSettings: _openSettings,
      onToggleCategoryView: _toggleCategoryView,
    );

    final listContent = Expanded(child: _buildContentArea());

    final contentWidgets = settingsController.settings.positionToolbarBottom
        ? [listContent, toolbar]
        : [toolbar, listContent];

    return SafeArea(child: Column(children: contentWidgets,),);
  }

  Widget _buildContentArea() {
    return StreamBuilder<List<BirthdayEntryCategory>>(
      stream: _categoryManager.watchAll(),
      builder: (context, categorySnapshot) {
        if (categorySnapshot.connectionState == ConnectionState.waiting && _categories.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (categorySnapshot.hasError) {
          return Center(child: Text("Error loading categories: ${categorySnapshot.error}"));
        }

        _categories = categorySnapshot.data ?? _categories;

        return StreamBuilder<List<BirthdayEntry>>(
          stream: _entryManager.watchAll(),
          builder: (context, entrySnapshot) {
            if (entrySnapshot.connectionState == ConnectionState.waiting && _entries.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            if (entrySnapshot.hasError) {
              return Center(child: Text("Error loading entries: ${entrySnapshot.error}"));
            }

            _entries = entrySnapshot.data ?? _entries;

            if (_entries.isEmpty) {
              return _buildEmptyState();
            }

            final groupedEntries = _groupEntries(_entries, _categories);
            return _buildListContent(groupedEntries);
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: Text(l10n.list_no_entries_found, textAlign: TextAlign.center),
      ),
    );
  }

  Widget _buildListContent(Map<BirthdayEntryCategory, List<BirthdayEntry>> groupedEntries) {
    final settingsController = context.watch<SettingsController>();
    final categoryKeys = groupedEntries.keys.toList()..sort((a, b) => a.name!.compareTo(b.name!));

    for (var key in categoryKeys) {
      _expandedStates.putIfAbsent(key.id, () => false);
    }

    final flatList = _getSortedFlatList();

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: settingsController.settings.categoryViewEnabled
          ? _builtCategoryList(categoryKeys, groupedEntries)
          : _buildFlatList(flatList),
    );
  }

  Widget _builtCategoryList(
    List<BirthdayEntryCategory> categories,
    Map<BirthdayEntryCategory, List<BirthdayEntry>> groupedEntries,
  ) {
    return ListView.builder(
      itemCount: categories.length,
      padding: const EdgeInsets.all(16.0),
      itemBuilder: (context, groupIndex) {
        final category = categories[groupIndex];
        final groupEntries = groupedEntries[category]!;
        final isExpanded = _expandedStates[category.id] ?? false;

        final Color headerColor = category.color ?? Colors.grey.shade400;
        final String categoryName = category.name!;

        return Card(
          margin: const EdgeInsets.only(bottom: 16.0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
          elevation: 2.0,
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category header
              InkWell(
                onTap: () => _toggleExpansion(category.id),
                onLongPress: () {
                  if (category.id != -1) {
                    _handleCategoryEdit(category);
                  }
                },
                borderRadius: BorderRadius.circular(12.0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(color: headerColor, borderRadius: BorderRadius.circular(12.0)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        categoryName,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      Icon(isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: Colors.white),
                    ],
                  ),
                ),
              ),
              // Entries
              AnimatedCrossFade(
                firstChild: Container(),
                secondChild: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Column(
                    children: groupEntries.map((entry) {
                      return BirthdayEntryTile(
                        entry: entry,
                        onTap: _handleEntryTap,
                        isSelected: entry.id == _selectedEntryId,
                      );
                    }).toList(),
                  ),
                ),
                crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 300),
                firstCurve: Curves.easeInOut,
                secondCurve: Curves.easeInOut,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFlatList(List<BirthdayEntry> entries) {
    return ListView.builder(
      itemCount: entries.length,
      padding: const EdgeInsets.all(8.0),
      itemBuilder: (context, index) {
        final entry = entries[index];
        return BirthdayEntryTile(entry: entry, onTap: _handleEntryTap, isSelected: entry.id == _selectedEntryId);
      },
    );
  }
}
