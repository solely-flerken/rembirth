import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rembirth/model/birthday_entry.dart';
import 'package:rembirth/model/birthday_entry_category.dart';
import 'package:rembirth/notifications/notification_service.dart';
import 'package:rembirth/save/save_manager.dart';
import 'package:rembirth/settings/settings_form.dart';

import '../settings/settings_controller.dart';
import '../util/date_util.dart';
import 'birthday_entry.dart';
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
  final Map<String, bool> _expandedStates = {};
  bool _isCategoryView = true;

  final today = DateTime.now();

  @override
  void initState() {
    super.initState();
    _entryManager = context.read<SaveManager<BirthdayEntry>>();
    _categoryManager = context.read<SaveManager<BirthdayEntryCategory>>();
    _notificationService = context.read<NotificationService>();
  }

  //#region Data

  /// Groups a list of birthday entries by category.
  Map<String, List<BirthdayEntry>> _groupEntries(
      List<BirthdayEntry> entries, List<BirthdayEntryCategory> categories) {
    final Map<String, List<BirthdayEntry>> grouped = {};

    for (var entry in entries) {
      var entryCategory = entry.category;

      if (entryCategory == null || !categories.any((x) => x.name == entryCategory)) {
        entryCategory = 'General';
      }

      grouped.putIfAbsent(entryCategory, () => []).add(entry);
    }

    for (final category in grouped.keys) {
      grouped[category]!.sort((a, b) => _compareByDaysUntilBirthday(a, b, today));
    }

    return grouped;
  }

  Future<void> _handleRefresh() async {
    // TODO: Currently just a placebo refresh
    await _notificationService.setupScheduledNotificationsFromPrefs(_entries);
  }

  List<BirthdayEntry> _getSortedFlatList() {
    return _entries.where((entry) => entry.month != null && entry.day != null).toList()
      ..sort((a, b) => _compareByDaysUntilBirthday(a, b, today));
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

  void _toggleExpansion(String categoryName) {
    setState(() {
      _expandedStates[categoryName] = !(_expandedStates[categoryName] ?? false);
    });
  }

  void _expandAll(Iterable<String> categoryKeys) {
    setState(() {
      _expandedStates.addEntries(categoryKeys.map((key) => MapEntry(key, true)));
    });
  }

  void _collapseAll(Iterable<String> categoryKeys) {
    setState(() {
      _expandedStates.addEntries(categoryKeys.map((key) => MapEntry(key, false)));
    });
  }

  void _toggleCategoryView() {
    setState(() {
      _isCategoryView = !_isCategoryView;
    });
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

    setState(() {
      _entries.add(returnedEntry);
      _selectedEntryId = returnedEntry.id;
    });

    _entryManager.save(returnedEntry);

    if(!mounted) return;

    final notificationTime = context.read<SettingsController>().settings.notificationTime;
    await _notificationService.scheduleBirthdayNotification(
      returnedEntry,
      notificationTime: notificationTime,
    );
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

    setState(() {
      final index = _entries.indexWhere((e) => e.id == returnedEntry.id);
      if (index != -1) {
        _entries[index] = returnedEntry;
      }
      _selectedEntryId = returnedEntry.id;
    });

    _entryManager.save(returnedEntry);

    if(!mounted) return;

    final notificationTime = context.read<SettingsController>().settings.notificationTime;
    await _notificationService.scheduleBirthdayNotification(
      returnedEntry,
      notificationTime: notificationTime,
    );
  }

  void _deleteItem() async {
    if (_selectedEntryId == null) return;
    final entryToDelete = _entries.firstWhereOrNull((e) => e.id == _selectedEntryId);
    if(entryToDelete == null) return;

    setState(() {
      _entries.removeWhere((e) => e.id == _selectedEntryId);
      _selectedEntryId = null;
    });

    await _notificationService.cancelBirthdayNotification(entryToDelete.id);
    await _entryManager.delete(entryToDelete.id);
  }

  void _handleEntryTap(BirthdayEntry entry) {
    setState(() {
      _selectedEntryId  = entry.id == _selectedEntryId ? null : entry.id;
    });
  }

  //#endregion

  void _openSettings() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => SettingsPageWidget()));
  }

  @override
  Widget build(BuildContext context) {
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
            return _builtContent(groupedEntries);
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return SafeArea(
      child: Column(
        children: [
          _builtActionBar(const []),
          const Expanded(child: Center(child: Text("No birthday entries found. Tap '+' to add one!"))),
        ],
      ),
    );
  }

  Widget _builtContent(Map<String, List<BirthdayEntry>> groupedEntries) {
    final settingsController = context.watch<SettingsController>();

    final groupKeys = groupedEntries.keys.toList()..sort();
    final flatList = _getSortedFlatList();

    for (var key in groupKeys) {
      _expandedStates.putIfAbsent(key, () => false);
    }

    final toolbar = _builtActionBar(groupKeys);
    final listContent = Expanded(
      child: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: _isCategoryView
            ? _builtCategoryList(groupKeys, groupedEntries)
            : _buildFlatList(flatList),
      ),
    );

    final contentWidgets = settingsController.settings.positionToolbarBottom
        ? [listContent, toolbar]
        : [toolbar, listContent];

    return SafeArea(
      child: Column(
        children: contentWidgets,
      ),
    );
  }

  Widget _builtCategoryList(List<String> categoryKeys, Map<String, List<BirthdayEntry>> groupedEntries) {
    return ListView.builder(
      itemCount: categoryKeys.length,
      padding: const EdgeInsets.all(16.0),
      itemBuilder: (context, groupIndex) {
        final groupName = categoryKeys[groupIndex];
        final groupEntries = groupedEntries[groupName]!;
        final isExpanded = _expandedStates[groupName] ?? false;

        final category = _categories.firstWhereOrNull((c) => c.name == groupName);
        final Color headerColor = category?.color ?? Colors.grey.shade400;

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
                onTap: () => _toggleExpansion(groupName),
                borderRadius: BorderRadius.circular(12.0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: headerColor,
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        groupName,
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

  Widget _builtActionBar(Iterable<String> categoryKeys) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: SizedBox(
        height: 56.0 + 16.0,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // TODO: Remove this button. Only for testing
              // _buildActionButton(
              //   icon: Icons.notifications_active,
              //   onPressed: () => _selectedEntry != null
              //       ? NotificationService().scheduleBirthdayNotification(_selectedEntry!, testMode: true)
              //       : null,
              // ),
              // const SizedBox(width: 8.0),
              _buildActionButton(icon: Icons.add, onPressed: _addEntry),
              const SizedBox(width: 8.0),
              _buildActionButton(
                icon: Icons.edit,
                onPressed: _selectedEntryId != null ? _editEntry : null,
              ),
              const SizedBox(width: 8.0),
              _buildActionButton(icon: Icons.delete, onPressed: _selectedEntryId != null ? _deleteItem : null),
              const SizedBox(width: 8.0),
              _buildActionButton(
                icon: _isCategoryView ? Icons.view_list : Icons.grid_view,
                onPressed: _toggleCategoryView,
              ),
              const SizedBox(width: 8.0),
              _buildActionButton(icon: Icons.unfold_more, onPressed: _isCategoryView ? () => _expandAll(categoryKeys) : null),
              const SizedBox(width: 8.0),
              _buildActionButton(icon: Icons.unfold_less, onPressed: _isCategoryView ? () => _collapseAll(categoryKeys) : null),
              const SizedBox(width: 8.0),
              _buildActionButton(icon: Icons.settings, onPressed: _openSettings),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({required IconData icon, required VoidCallback? onPressed}) {
    return SizedBox(
      width: 56.0,
      height: 56.0,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        ),
        child: Icon(icon, size: 28.0),
      ),
    );
  }
}
