import 'package:capstone/utils/app_textstyles.dart';
import 'package:flutter/material.dart';

class OnsiteServices extends StatelessWidget {
  const OnsiteServices({super.key});

  final List<Map<String, String>> _services = const [
    {'title': 'Service #1', 'description': 'Hydrophobic & Engine Wash'},
    {'title': 'Service #2', 'description': 'Interior Detailing & Vacuum'},
    {'title': 'Service #3', 'description': 'Paint Correction & Wax'},
    {'title': 'Service #4', 'description': 'Basic Wash & Wax'},
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title Text
        Padding(
          padding: const EdgeInsets.only(left: 20, top: 20, bottom: 10),
          child: Text(
            'Ongoing Onsite Services',
            style: AppTextStyle.withColor(
              AppTextStyle.bodyMedium,
              isDark ? Colors.white : Colors.black,
            ),
          ),
        ),
        // Services Grid
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _services.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              childAspectRatio: 1.5,
            ),
            itemBuilder: (context, index) {
              return _buildServiceCard(context, _services[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildServiceCard(BuildContext context, Map<String, String> service) {
    return InkWell(
      onTap: () {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Booking Details'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Service: ${service['title']}'),
                  Text('Description: ${service['description']}'),
                  const SizedBox(height: 10),
                  Text('Customer: John Doe'),
                  Text('Date: 2023-10-15'),
                  Text('Time: 10:00 AM'),
                  Text('Status: Confirmed'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              service['title']!,
              style: AppTextStyle.withColor(
                AppTextStyle.bodySmall,
                Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              service['description']!,
              style: AppTextStyle.withColor(AppTextStyle.small, Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
