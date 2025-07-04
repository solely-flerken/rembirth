import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:rembirth/model/birthday_entry_category.dart';
import 'package:rembirth/save/isar_database.dart';
import 'package:rembirth/util/logger.dart';

class BirthdayEntryCategoryCreationForm extends StatefulWidget {
  final BirthdayEntryCategory? initialCategory;

  const BirthdayEntryCategoryCreationForm({super.key, this.initialCategory});

  @override
  State<BirthdayEntryCategoryCreationForm> createState() => _BirthdayEntryCategoryCreationFormState();
}

class _BirthdayEntryCategoryCreationFormState extends State<BirthdayEntryCategoryCreationForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  Color _selectedColor = Colors.blue;

  @override
  void initState() {
    super.initState();

    if (widget.initialCategory != null) {
      _nameController.text = widget.initialCategory!.name ?? '';
      _selectedColor = widget.initialCategory!.color ?? Colors.black;
    } else {
      _nameController.text = '';
      _selectedColor = _generateRandomColor();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submitForm() {
    final name = _nameController.text.trim();

    if (!_formKey.currentState!.validate()) {
      logger.w('Category creation form: Validation failed.');
      return;
    }
    logger.d('Category creation form: Passed validation.');

    int? id = widget.initialCategory?.id;
    id ??= IsarDatabase.instance.birthdayEntryCategorys.autoIncrement();

    final newEntry = BirthdayEntryCategory()
      ..id = id
      ..name = name
      ..colorValue = _selectedColor.toARGB32();

    Navigator.of(context).pop(newEntry);
  }

  Color _generateRandomColor() {
    final random = Random();
    return HSLColor.fromAHSL(
      1.0, // Alpha
      random.nextDouble() * 360, // Hue
      0.7, // Saturation
      0.6, // Lightness
    ).toColor();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20.0))),
      child: SizedBox(
        width: double.maxFinite,
        height: 560,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              /// Scrollable Content
              Expanded(
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: SizedBox(
                            height: 40,
                            child: Text.rich(
                              TextSpan(
                                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                                children: [
                                  TextSpan(text: 'Create '),
                                  TextSpan(
                                    text: 'Category',
                                    style: TextStyle(color: Theme.of(context).colorScheme.primary),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        /// Divider
                        Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: const Divider(thickness: 2)),
                        const SizedBox(height: 16),

                        /// Name
                        TextFormField(
                          style: const TextStyle(fontWeight: FontWeight.w400, fontSize: 20),
                          controller: _nameController,
                          decoration: InputDecoration(labelText: 'Name', border: const OutlineInputBorder()),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Category name is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        /// Color Picker
                        ColorPicker(
                          pickerColor: _selectedColor,
                          onColorChanged: (color) => setState(() => _selectedColor = color),
                          pickerAreaHeightPercent: 0.6,
                          enableAlpha: false,
                          labelTypes: [],
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),

              /// Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 14.0),
                    ),
                    child: const Text(style: TextStyle(fontSize: 18, fontWeight: FontWeight.w400), 'Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () => _submitForm(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 14.0),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text(style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600), 'Save'),
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
