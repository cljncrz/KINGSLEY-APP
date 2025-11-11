import 'package:capstone/utils/app_textstyles.dart';
import 'package:flutter/material.dart';

class Services extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final categories = ['Wash\nServices', 'Detailing\nServices'];

  Services({super.key, required this.selectedIndex, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(
          categories.length,
          (index) => ChoiceChip(
            label: Text(
              categories[index],
              style: AppTextStyle.withColor(
                AppTextStyle.withWeight(
                  AppTextStyle.bodySmall,
                  FontWeight.w600,
                ),
                Colors.white,
              ),
            ),
            selected: selectedIndex == index,
            onSelected: (bool selected) {
              if (selected) {
                onSelected(index);
              }
            },
            selectedColor: Theme.of(context).primaryColor,
            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 0,
            pressElevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            labelPadding: const EdgeInsets.symmetric(
              horizontal: 4,
              vertical: 1,
            ),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            side: const BorderSide(color: Colors.transparent, width: 1),
          ),
        ),
      ),
    );
  }
}
