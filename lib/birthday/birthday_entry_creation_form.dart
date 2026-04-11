import 'package:collection/collection.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:rembirth/birthday/birthday_entry_category_creation_form.dart';
import 'package:rembirth/birthday/reminders_list_widget.dart';
import 'package:rembirth/model/birthday_entry_category.dart';
import 'package:rembirth/save/save_manager.dart';
import 'package:rembirth/util/logger.dart';

import '../datepicker/date_display.dart';
import '../datepicker/date_picker.dart';
import '../datepicker/util.dart';
import '../l10n/app_localizations.dart';
import '../model/birthday_entry.dart';
import '../datepicker/partial_date.dart';

class BirthdayEntryCreationForm extends StatefulWidget {
  final BirthdayEntry? initialEntry;
  final List<BirthdayEntryCategory> categories;
  final SaveManager<BirthdayEntryCategory> categoryManager;

  const BirthdayEntryCreationForm({
    super.key,
    this.initialEntry,
    required this.categories,
    required this.categoryManager,
  });

  @override
  State<BirthdayEntryCreationForm> createState() => _BirthdayEntryCreationFormState();
}

class _BirthdayEntryCreationFormState extends State<BirthdayEntryCreationForm> {
  String? _name;
  BirthdayEntryCategory? _category;
  PartialDate? _selectedDate;
  List<int> _reminders = [0];

  List<BirthdayEntryCategory> _categories = [];

  String? _nameError;
  String? _dateError;

  final nameController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _categories = widget.categories;

    if (widget.initialEntry != null) {
      _name = widget.initialEntry!.name!;
      nameController.text = _name!;

      _category = _categories.firstWhereOrNull((c) => c.id == widget.initialEntry!.categoryId);

      _selectedDate = PartialDate(
        year: widget.initialEntry!.year,
        month: widget.initialEntry!.month!,
        day: widget.initialEntry!.day!,
      );

      final existing = widget.initialEntry!.reminders ?? [];
      _reminders = ({0, ...existing}).toList()..sort();
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  void _submitForm() {
    final l10n = AppLocalizations.of(context)!;

    logger.d(
      'Creation form: Attempting to submit with values -> '
      'name: $_name, '
      'category: ${_category?.name}, '
      'date: $_selectedDate',
    );

    setState(() {
      _nameError = _name == null || _name!.trim().isEmpty ? l10n.name_validation_error : null;
      _dateError = _selectedDate == null ? l10n.entry_creation_date_validation_error : null;
    });

    if (_nameError != null || _dateError != null) {
      logger.w('Creation form: Validation failed.');
      return;
    }
    logger.d('Creation form: Passed validation.');

    final id = widget.initialEntry?.id;

    final newEntry = BirthdayEntry()
      ..name = _name
      ..categoryId = _category?.id
      ..year = _selectedDate?.year
      ..month = _selectedDate?.month
      ..day = _selectedDate?.day
      ..reminders = List<int>.from(_reminders);

    if (id != null) {
      newEntry.id = id;
    }

    Navigator.of(context).pop(newEntry);
  }

  Future<void> _openDatePicker(
    BuildContext context,
    DatePickerStep step,
    DatePickerStep? stop,
    PartialDate? initialDate,
  ) async {
    final selectedDate = await CustomDatePicker.show(
      context,
      initialStep: step,
      stopStep: stop,
      initialDate: initialDate,
    );
    if (selectedDate != null) {
      setState(() {
        _selectedDate = selectedDate;
        _dateError = null;
      });
    }
  }

  Future<void> _openCategoryCreationDialog() async {
    final newCategory = await showDialog<BirthdayEntryCategory>(
      context: context,
      builder: (context) => const BirthdayEntryCategoryCreationForm(),
    );

    if (newCategory == null) return;

    try {
      final id = await widget.categoryManager.save(newCategory);
      if (id == null) return;

      newCategory.id = id;
      setState(() {
        _categories = [..._categories, newCategory];
        _category = newCategory;
      });
    } on Exception catch (e) {
      logger.e('Failed to save new category: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    /// Construct page title
    final title = l10n.entry_creation_label;
    final words = title.split(' ');
    final highlightIndex = words.length ~/ 2;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Title
                    Center(
                      child: Text.rich(
                        TextSpan(
                          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                          children: List.generate(words.length, (i) {
                            return TextSpan(
                              text: i < words.length - 1 ? '${words[i]} ' : words[i],
                              style: TextStyle(color: i == highlightIndex ? theme.colorScheme.primary : null),
                            );
                          }),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Divider(thickness: 1.5),
                    const SizedBox(height: 24),

                    /// Name Field
                    TextField(
                      controller: nameController,
                      style: const TextStyle(fontSize: 18),
                      decoration: InputDecoration(
                        labelText: l10n.name,
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        errorText: _nameError,
                      ),
                      onChanged: (value) => setState(() => _name = value),
                    ),
                    const SizedBox(height: 24),

                    /// Category Dropdown
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: DropdownButtonFormField2<BirthdayEntryCategory?>(
                            value: _category,
                            hint: Text(l10n.entry_creation_category),
                            items: [
                              DropdownMenuItem<BirthdayEntryCategory?>(
                                value: null,
                                child: Text(l10n.entry_creation_no_category),
                              ),
                              ..._categories.map(
                                (category) => DropdownMenuItem(
                                  value: category,
                                  child: Text(category.name ?? l10n.entry_creation_unknown_category),
                                ),
                              ),
                            ],
                            onChanged: (value) => setState(() => _category = value),
                            buttonStyleData: const ButtonStyleData(padding: EdgeInsets.only(right: 8)),
                            dropdownStyleData: DropdownStyleData(
                              decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
                            ),
                            decoration: InputDecoration(
                              labelText: l10n.entry_creation_category,
                              prefixIcon: const Icon(Icons.category_outlined),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          height: 56,
                          width: 56,
                          child: IconButton.outlined(
                            onPressed: _openCategoryCreationDialog,
                            icon: const Icon(Icons.add, size: 20),
                            tooltip: 'New category',
                            style: IconButton.styleFrom(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    /// Date Picker
                    InkWell(
                      onTap: () => _openDatePicker(context, DatePickerStep.year, null, _selectedDate),
                      borderRadius: BorderRadius.circular(12),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: l10n.entry_creation_date,
                          prefixIcon: const Icon(Icons.calendar_today_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          errorText: _dateError,
                        ),
                        child: InteractiveDateDisplay(
                          year: _selectedDate?.year,
                          month: _selectedDate?.month,
                          day: _selectedDate?.day,
                          placeholderText: l10n.select_a_date,
                          baseStyle: const TextStyle(fontSize: 18),
                          monthStyle: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                          onDayTap: () => _openDatePicker(context, DatePickerStep.day, DatePickerStep.day, _selectedDate),
                          onMonthTap: () => _openDatePicker(context, DatePickerStep.month, DatePickerStep.month, _selectedDate),
                          onYearTap: () => _openDatePicker(context, DatePickerStep.year, DatePickerStep.year, _selectedDate),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    /// Reminders
                    RemindersListWidget(
                      reminders: _reminders,
                      onRemindersChanged: (updated) => setState(() => _reminders = updated),
                    ),
                  ],
                ),
              ),
            ),

            /// Action Buttons
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(l10n.cancel, style: const TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: Text(l10n.save, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
