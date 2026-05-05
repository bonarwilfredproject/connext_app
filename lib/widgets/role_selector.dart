import 'package:flutter/material.dart';
import 'package:connext_app/constants/app_theme.dart';
import 'package:connext_app/constants/style_text.dart';

class RoleSelector extends StatelessWidget {
  final String role;
  final Function(String) onChanged;

  const RoleSelector({super.key, required this.role, required this.onChanged});

  Widget buildItem(String value, String label) {
    final bool selected = role == value;

    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected ? AppTheme.secondary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: styleText().copyWith(
              fontWeight: FontWeight.w600,
              color: selected ? AppTheme.primary : AppTheme.secondary,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          buildItem("Attendee", "Attendee"),
          buildItem("Committee", "Committee"),
        ],
      ),
    );
  }
}
