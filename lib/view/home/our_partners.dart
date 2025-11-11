import 'package:capstone/utils/app_textstyles.dart';
import 'package:flutter/material.dart';

class OurPartners extends StatelessWidget {
  const OurPartners({super.key});

  final List<String> partnerLogos = const [
    'assets/images/meguiars.png',
    'assets/images/eagle.png',
    'assets/images/armor.png',
    'assets/images/turtle wax.png',
    // Add more logo paths here
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 20, top: 20, bottom: 10),
          child: Text(
            'Our Partners',
            style: AppTextStyle.withColor(
              AppTextStyle.bodyMedium,
              isDark ? Colors.white : Colors.black,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: partnerLogos
                .map(
                  (logo) => Expanded(
                    child: SizedBox(
                      height: 60,
                      child: Image.asset(logo, fit: BoxFit.contain),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}
