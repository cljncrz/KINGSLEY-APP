import 'package:capstone/utils/app_textstyles.dart';
import 'package:flutter/material.dart';

class SizeSelector extends StatelessWidget {
  final List<String> sizes;
  final String? selectedSize;
  final Function(String) onSizeSelected;

  const SizeSelector({
    super.key,
    required this.sizes,
    this.selectedSize,
    required this.onSizeSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: sizes.map((size) {
        final isSelected = selectedSize == size;
        return ChoiceChip(
          label: Text(size),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) {
              onSizeSelected(size);
            }
          },
          selectedColor: Theme.of(context).primaryColor,
          backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
          labelStyle: AppTextStyle.withColor(
            AppTextStyle.bodyMedium,
            isSelected
                ? Colors.white
                : (isDark ? Colors.white70 : Colors.black87),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        );
      }).toList(),
    );
  }
}
