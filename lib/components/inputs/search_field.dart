import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class SearchField extends StatelessWidget {
  const SearchField({
    super.key,
    this.controller,
    this.hintText = 'Buscar',
    this.onChanged,
  });

  final TextEditingController? controller;
  final String hintText;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: context.colors.input,
        border: Border.all(color: context.colors.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.search, size: 18, color: context.colors.muted),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: TextStyle(fontSize: 13, color: context.colors.text),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: hintText,
                hintStyle: TextStyle(fontSize: 13, color: context.colors.muted),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
