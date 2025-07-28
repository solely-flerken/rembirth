import 'package:collection/collection.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:rembirth/model/birthday_entry_category.dart';
import 'package:rembirth/save/isar_database.dart';
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

  const BirthdayEntryCreationForm({super.key, this.initialEntry, required this.categories});

  @override
  State<BirthdayEntryCreationForm> createState() => _BirthdayEntryCreationFormState();
}

class _BirthdayEntryCreationFormState extends State<BirthdayEntryCreationForm> {
  String? _name;
  BirthdayEntryCategory? _category;
  PartialDate? _selectedDate;

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
    }
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

    // Validate
    if (_nameError != null || _dateError != null) {
      logger.w('Creation form: Validation failed.');
      return;
    }
    logger.d('Creation form: Passed validation.');

    int? id = widget.initialEntry?.id;
    id ??= IsarDatabase.instance.birthdayEntrys.autoIncrement();

    final newEntry = BirthdayEntry()
      ..id = id
      ..name = _name
      ..categoryId = _category?.id
      ..year = _selectedDate?.year
      ..month = _selectedDate?.month
      ..day = _selectedDate?.day;

    Navigator.of(context).pop(newEntry);
  }

  void _cancelForm() {
    Navigator.of(context).pop();
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    /// Construct page title
    final title = l10n.entry_creation_label;

    final words = title.split(' ');
    final highlightIndex = words.length ~/ 2;

    List<InlineSpan> spans = [];

    for (var i = 0; i < words.length; i++) {
      spans.add(
        TextSpan(
          text: i < words.length - 1 ? '${words[i]} ' : words[i],
          style: TextStyle(color: i == highlightIndex ? theme.colorScheme.primary : null),
        ),
      );
    }

    return Dialog(
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20.0))),
      child: SizedBox(
        width: double.maxFinite,
        height: 560,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  height: 40,
                  child: Text.rich(
                    TextSpan(
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                      children: spans,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ),

              // Divider
              Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: const Divider(thickness: 2)),
              const SizedBox(height: 16),

              /// Name
              TextField(
                style: const TextStyle(fontWeight: FontWeight.w400, fontSize: 20),
                controller: nameController,
                decoration: InputDecoration(
                  labelText: l10n.name,
                  border: const OutlineInputBorder(),
                  errorText: _nameError,
                ),
                onChanged: (value) {
                  setState(() {
                    _name = value;
                  });
                },
              ),
              const SizedBox(height: 16),

              /// Category
              DropdownButtonFormField2<BirthdayEntryCategory?>(
                value: _category,
                items: [
                  DropdownMenuItem<BirthdayEntryCategory?>(value: null, child: Text(l10n.entry_creation_no_category)),
                  ..._categories.map((category) {
                    return DropdownMenuItem(value: category, child: Text(category.name ?? l10n.entry_creation_unknown_category));
                  }),
                ],
                onChanged: (value) {
                  setState(() {
                    _category = value;
                  });
                },
                style: TextStyle(fontWeight: FontWeight.w400, fontSize: 20, color: theme.colorScheme.onSurface),
                decoration: InputDecoration(labelText: l10n.entry_creation_category, border: const OutlineInputBorder()),
                dropdownStyleData: DropdownStyleData(decoration: BoxDecoration(borderRadius: BorderRadius.circular(8))),
              ),
              const SizedBox(height: 16),

              /// Date
              InkWell(
                onTap: () => _openDatePicker(context, DatePickerStep.year, null, _selectedDate),
                child: InputDecorator(
                  decoration: InputDecoration(labelText: l10n.entry_creation_date, border: OutlineInputBorder(), errorText: _dateError),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: InteractiveDateDisplay(
                          year: _selectedDate?.year,
                          month: _selectedDate?.month,
                          day: _selectedDate?.day,
                          placeholderText: l10n.select_a_date,
                          baseStyle: const TextStyle(fontWeight: FontWeight.w400, fontSize: 20),
                          monthStyle: TextStyle(color: theme.colorScheme.primary),
                          onDayTap: () => _openDatePicker(context, DatePickerStep.day, DatePickerStep.day, _selectedDate),
                          onMonthTap: () => _openDatePicker(context, DatePickerStep.month, DatePickerStep.month, _selectedDate),
                          onYearTap: () => _openDatePicker(context, DatePickerStep.year, DatePickerStep.year, _selectedDate),
                        ),
                      ),
                      const Icon(Icons.calendar_today),
                    ],
                  ),
                ),
              ),

              /// Spacer
              const Spacer(),

              /// Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _cancelForm,
                    style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 14.0)),
                    child: Text(style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w400), l10n.cancel),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 14.0),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600), l10n.save),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
