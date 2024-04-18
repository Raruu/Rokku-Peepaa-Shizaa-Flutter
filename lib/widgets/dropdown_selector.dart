import 'package:flutter/material.dart';

class DropDownSelector extends StatelessWidget {
  const DropDownSelector(
      {super.key,
      required this.items,
      required this.value,
      required this.onItemChanged});

  final List<String> items;
  final String value;
  final void Function(String? value) onItemChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: DropdownButton(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down),
          iconSize: 30,
          underline: const SizedBox(),
          items: items.map((String value) {
            return DropdownMenuItem(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (value) => onItemChanged(value),
        ),
      ),
    );
  }
}
