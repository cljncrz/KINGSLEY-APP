import 'dart:async';
import 'package:capstone/models/walkin.dart';
import 'package:capstone/services/walkin_service.dart';
import 'package:capstone/utils/app_textstyles.dart';
import 'package:flutter/material.dart';

class OnsiteServices extends StatefulWidget {
  final Function? onRefresh;

  const OnsiteServices({super.key, this.onRefresh});

  @override
  State<OnsiteServices> createState() => _OnsiteServicesState();
}

class _OnsiteServicesState extends State<OnsiteServices> {
  final WalkinService _walkinService = WalkinService();
  Timer? _refreshTimer;
  int _refreshKey = 0; // Key to force stream rebuild

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  /// Triggers a refresh after delay to show updated bookings
  void _startAutoRefresh({int delaySeconds = 30}) {
    _refreshTimer?.cancel();
    _refreshTimer = Timer(Duration(seconds: delaySeconds), () {
      // Force stream rebuild by changing key
      if (mounted) {
        debugPrint(
          'Auto-refreshing after $delaySeconds seconds to show updated bookings',
        );
        setState(() {
          _refreshKey++;
        });
      }
    });
  }

  /// Manual refresh triggered by user
  Future<void> _manualRefresh() async {
    debugPrint('Manual refresh triggered');
    if (mounted) {
      setState(() {
        _refreshKey++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title Text with Debug Button and Refresh Button
        Padding(
          padding: const EdgeInsets.only(left: 20, top: 20, bottom: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ongoing Onsite Services',
                style: AppTextStyle.withColor(
                  AppTextStyle.bodyMedium,
                  isDark ? Colors.white : Colors.black,
                ),
              ),
              // Refresh and Debug buttons
              Row(
                children: [
                  // Refresh button
                  GestureDetector(
                    onTap: _manualRefresh,
                    child: Tooltip(
                      message: 'Refresh bookings',
                      child: Icon(
                        Icons.refresh,
                        size: 18,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Debug button to add test data
                  GestureDetector(
                    onLongPress: () async {
                      // Log all walkins first
                      await _walkinService.debugLogAllWalkins();

                      // Fix any missing data
                      await _walkinService.fixWalkinsData();

                      // Add new test data
                      await _walkinService.addTestWalkinData();

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Test data added! Check console logs.',
                            ),
                          ),
                        );
                      }
                    },
                    onDoubleTap: () async {
                      // Double tap to just check data
                      await _walkinService.debugLogAllWalkins();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Logged walkins to console'),
                          ),
                        );
                      }
                    },
                    child: Tooltip(
                      message:
                          'Long press: add test data, Double tap: debug log',
                      child: Icon(
                        Icons.info_outline,
                        size: 18,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Services Grid with Real Data from Firestore
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: StreamBuilder<List<Walkin>>(
            key: ValueKey(_refreshKey),
            stream: _walkinService.getWalkinBookingsStream(limit: 4),
            builder: (context, snapshot) {
              // Loading state
              if (snapshot.connectionState == ConnectionState.waiting) {
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 4,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                    childAspectRatio: 1.5,
                  ),
                  itemBuilder: (context, index) {
                    return Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    );
                  },
                );
              }

              // Error state - show default cards and log error
              if (snapshot.hasError) {
                debugPrint('OnsiteServices Error: ${snapshot.error}');
                debugPrint('Stack Trace: ${snapshot.stackTrace}');
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 4,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                    childAspectRatio: 1.5,
                  ),
                  itemBuilder: (context, index) {
                    return _buildDefaultServiceCard(isDark, index + 1);
                  },
                );
              }

              // Get data or empty list
              final bookings = snapshot.data ?? [];

              // Always display 4 containers
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 4,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                  childAspectRatio: 1.5,
                ),
                itemBuilder: (context, index) {
                  if (index < bookings.length) {
                    // Display booking data
                    return _buildServiceCard(
                      context,
                      bookings[index],
                      isDark,
                      index + 1,
                    );
                  } else {
                    // Display default empty container with Service #X label
                    return _buildDefaultServiceCard(isDark, index + 1);
                  }
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildServiceCard(
    BuildContext context,
    Walkin walkin,
    bool isDark,
    int serviceNumber,
  ) {
    // Determine service name from first service in list
    String serviceName = walkin.serviceNames.isNotEmpty
        ? walkin.serviceNames[0]
        : 'Service';

    // Determine status color
    Color statusColor;
    if (walkin.status == 'Pending') {
      statusColor = Colors.orange;
    } else if (walkin.status == 'In Progress') {
      statusColor = Colors.blue;
    } else {
      statusColor = Colors.green;
    }

    return InkWell(
      onTap: () {
        _showWalkinDetailsDialog(context, walkin);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: statusColor, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Service Title
            Text(
              'Service #$serviceNumber',
              style: AppTextStyle.withColor(
                AppTextStyle.bodySmall,
                Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              serviceName,
              style: AppTextStyle.withColor(AppTextStyle.small, Colors.white),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultServiceCard(bool isDark, int serviceNumber) {
    final primaryColor = Theme.of(context).primaryColor;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Service #$serviceNumber',
            style: AppTextStyle.withColor(AppTextStyle.bodySmall, Colors.grey),
          ),
          const SizedBox(height: 4),
          Text(
            'No Walk-In\nCustomers',
            style: AppTextStyle.withColor(AppTextStyle.small, Colors.grey),
          ),
        ],
      ),
    );
  }

  void _showWalkinDetailsDialog(BuildContext context, Walkin walkin) {
    // Debug logging
    debugPrint('Walkin Data:');
    debugPrint('ID: ${walkin.id}');
    debugPrint('Service Names: ${walkin.serviceNames}');
    debugPrint('Status: ${walkin.status}');
    debugPrint('Date: ${walkin.bookingDate}');
    debugPrint('Time: ${walkin.bookingTime}');
    debugPrint('Price: ${walkin.price}');

    String serviceDisplay = walkin.serviceNames.isNotEmpty
        ? walkin.serviceNames.join(', ')
        : 'No service data';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Walk-In Customers'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                _buildDetailRow('Service', serviceDisplay),
                const SizedBox(height: 8),
                _buildDetailRow('Status', walkin.status),
                const SizedBox(height: 8),
                _buildDetailRow('Date', walkin.bookingDate),
                const SizedBox(height: 8),
                _buildDetailRow('Time', walkin.bookingTime),
                const SizedBox(height: 8),
                _buildDetailRow('Price', '${walkin.price.toStringAsFixed(2)}'),
              ],
            ),
          ),
          actions: [
            if (walkin.status == 'Pending' || walkin.status == 'In Progress')
              ElevatedButton(
                onPressed: () async {
                  // Mark as completed
                  await _walkinService.updateBookingStatus(
                    walkin.id!,
                    'Completed',
                  );

                  if (context.mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Marked as Completed. Refreshing in 10 seconds...',
                        ),
                        duration: Duration(seconds: 2),
                      ),
                    );

                    // Start auto-refresh after 10 seconds to show updated bookings
                    _startAutoRefresh(delaySeconds: 10);
                  }
                },
                child: const Text('Mark Completed'),
              ),
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
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
