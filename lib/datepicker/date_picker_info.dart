import 'package:flutter/material.dart';

class DatePickerInfoCard extends StatelessWidget {
  final String label;
  final String text;
  final Color? textColor;
  final Color? backgroundColor;
  final Color borderColor;

  const DatePickerInfoCard({
    super.key,
    required this.label,
    required this.text,
    this.textColor,
    this.backgroundColor,
    this.borderColor = Colors.transparent,
  });

  @override
  Widget build(BuildContext context) {
    final normalTextColor = Theme.of(context).textTheme.bodyLarge?.color;

    return Row(
      children: [
        SizedBox(
          width: 90,
          height: 90,
          child: Card(
            color: backgroundColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
              side: BorderSide(color: borderColor, width: 3),
            ),
            elevation: 5,
            child: Center(
              child: Text(
                text,
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: textColor ?? normalTextColor),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
        ),
      ],
    );
  }
}
