import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rembirth/model/birthday_entry.dart';
import 'package:rembirth/model/birthday_entry_category.dart';
import 'package:rembirth/save/save_manager.dart';

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

  // Data
  Future<Map<String, List<BirthdayEntry>>>? _groupedEntriesFuture;
  Map<String, List<BirthdayEntry>>? _currentGroupedEntries;
  List<BirthdayEntry> _entries = [];
  BirthdayEntry? _selectedEntry;
  List<BirthdayEntryCategory> _categories = [];

  // UI
  final Map<String, bool> _expandedStates = {};
  bool _isCategoryView = true;

  final today = DateTime.now();

  @override
  void initState() {
    super.initState();

    _entryManager = context.read<SaveManager<BirthdayEntry>>();
    _categoryManager = context.read<SaveManager<BirthdayEntryCategory>>();

    _groupedEntriesFuture = _loadGroupedEntries();
  }

  //#region Data

  /// Loads all birthday entries and categories, then groups the entries by their
  /// associated category.
  ///
  /// If an entry has no category or its category does not exist in the loaded
  /// categories, it is assigned to a default "General" category.
  Future<Map<String, List<BirthdayEntry>>> _loadGroupedEntries() async {
    _entries = await _entryManager.loadAll();
    _categories = await _categoryManager.loadAll();

    final Map<String, List<BirthdayEntry>> grouped = {};

    for (var entry in _entries) {
      var entryCategory = entry.category;

      if (entryCategory == null || !_categories.any((x) => x.name == entryCategory)) {
        entryCategory = 'General';
      }

      grouped.putIfAbsent(entryCategory, () => []).add(entry);
    }

    for (final category in grouped.keys) {
      grouped[category]!.sort((a, b) => _compareByDaysUntilBirthday(a, b, today));
    }

    // List containing all birthday entries grouped by their category
    return grouped;
  }

  void _syncData() {
    setState(() {
      _currentGroupedEntries = null; // Clear current data
      _groupedEntriesFuture = _loadGroupedEntries(); // Re-assign the future to trigger reload
    });
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

  void _expandAll() {
    if (_currentGroupedEntries == null) return;

    setState(() {
      _expandedStates.addEntries(_currentGroupedEntries!.keys.map((key) => MapEntry(key, true)));
    });
  }

  void _collapseAll() {
    if (_currentGroupedEntries == null) return;

    setState(() {
      _expandedStates.addEntries(_currentGroupedEntries!.keys.map((key) => MapEntry(key, false)));
    });
  }

  void _toggleCategoryView() {
    setState(() {
      _isCategoryView = !_isCategoryView;
    });
  }

  Color _generateCategoryColor(String categoryName) {
    final List<Color> availableColors = [
      Colors.blue.shade300,
      Colors.green.shade300,
      Colors.purple.shade300,
      Colors.orange.shade300,
      Colors.red.shade300,
      Colors.teal.shade300,
      Colors.pink.shade300,
      Colors.indigo.shade300,
      Colors.amber.shade300,
      Colors.cyan.shade300,
    ];

    int index = categoryName.hashCode.abs() % availableColors.length;
    return availableColors[index];
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
    _entryManager.save(returnedEntry);
  }

  Future<void> _editEntry(BirthdayEntry? entry) async {
    if (entry == null) return;

    final returnedEntry = await Navigator.push<BirthdayEntry?>(
      context,
      DialogRoute(
        builder: (context) => BirthdayEntryCreationForm(initialEntry: entry, categories: _categories),
        context: context,
      ),
    );

    if (returnedEntry == null) return;
    _entryManager.save(returnedEntry);
  }

  void _deleteItem() {
    if (_selectedEntry == null) return;
    _entryManager.delete(_selectedEntry?.id);
  }

  void _handleEntryTap(BirthdayEntry entry) {
    setState(() {
      _selectedEntry = entry == _selectedEntry ? null : entry;
    });
  }

  //#endregion

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, List<BirthdayEntry>>>(
      future: _groupedEntriesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          _currentGroupedEntries = null;
          return _buildEmptyState();
        }

        _currentGroupedEntries = snapshot.data!;
        return _builtContent(_currentGroupedEntries!);
      },
    );
  }

  Widget _buildEmptyState() {
    return SafeArea(
      child: Column(
        children: [
          _builtActionBar(),
          const Expanded(child: Center(child: Text("No birthday entries found. Tap '+' to add one!"))),
        ],
      ),
    );
  }

  Widget _builtContent(Map<String, List<BirthdayEntry>> groupedEntries) {
    final groupKeys = groupedEntries.keys.toList()..sort();
    final flatList = _getSortedFlatList();

    for (var key in groupKeys) {
      _expandedStates.putIfAbsent(key, () => false);
    }

    return SafeArea(
      child: Column(
        children: [
          _builtActionBar(),
          Expanded(child: _isCategoryView ? _builtCategoryList(groupKeys, groupedEntries) : _buildFlatList(flatList)),
        ],
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
                    color: _generateCategoryColor(groupName),
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
                        isSelected: entry == _selectedEntry,
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
        return BirthdayEntryTile(entry: entry, onTap: _handleEntryTap, isSelected: entry == _selectedEntry);
      },
    );
  }

  Widget _builtActionBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: SizedBox(
        height: 56.0 + 16.0,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _buildActionButton(icon: Icons.add, onPressed: _addEntry),
              const SizedBox(width: 8.0),
              _buildActionButton(icon: Icons.edit, onPressed: () => _editEntry(_selectedEntry)),
              const SizedBox(width: 8.0),
              _buildActionButton(icon: Icons.delete, onPressed: _deleteItem),
              const SizedBox(width: 8.0),
              _buildActionButton(icon: Icons.refresh, onPressed: _syncData),
              const SizedBox(width: 8.0),
              _buildActionButton(
                icon: _isCategoryView ? Icons.view_list : Icons.grid_view,
                onPressed: _toggleCategoryView,
              ),
              const SizedBox(width: 8.0),
              _buildActionButton(icon: Icons.unfold_more, onPressed: _isCategoryView ? _expandAll : null),
              const SizedBox(width: 8.0),
              _buildActionButton(icon: Icons.unfold_less, onPressed: _isCategoryView ? _collapseAll : null),
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
