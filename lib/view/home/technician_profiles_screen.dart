import 'package:capstone/utils/app_textstyles.dart';
import 'package:capstone/screens/signup/signup_screen.dart';
import 'package:capstone/models/technician.dart'; // Import the new Technician model
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
// For star ratings
import 'package:capstone/controllers/custom_bottom_navbar.dart';

class TechnicianProfilesScreen extends StatefulWidget {
  const TechnicianProfilesScreen({super.key});

  @override
  State<TechnicianProfilesScreen> createState() =>
      _TechnicianProfilesScreenState();
}

class _TechnicianProfilesScreenState extends State<TechnicianProfilesScreen> {
  late Future<List<Technician>> _techniciansFuture;

  @override
  void initState() {
    super.initState();
    _techniciansFuture = _fetchTechniciansFromFirestore();
  }

  Future<List<Technician>> _fetchTechniciansFromFirestore() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('technicians')
          .get();

      print('DEBUG: Found ${snapshot.docs.length} technicians');

      final technicians = snapshot.docs.map((doc) {
        final data = doc.data();
        print('DEBUG: Doc keys = ${data.keys.toList()}');
        print('DEBUG: Doc data = $data');
        final tech = Technician.fromFirestore(data, doc.id);
        print(
          'DEBUG: Technician loaded - Name: ${tech.name}, Photo: ${tech.imageUrl}, Role: ${tech.role}, Status: ${tech.status}',
        );
        return tech;
      }).toList();

      print(
        'DEBUG: Loaded technicians: ${technicians.map((t) => '${t.name} (${t.imageUrl})').toList()}',
      );
      return technicians;
    } catch (e) {
      print('ERROR fetching technicians: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: Icon(
            Icons.arrow_back_ios,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        title: Text(
          'Technician Profiles',
          style: AppTextStyle.withColor(
            AppTextStyle.h3,
            isDark ? Colors.white : Colors.black,
          ),
        ),
      ),
      body: user == null
          ? _buildGuestView(context)
          : FutureBuilder<List<Technician>>(
              future: _techniciansFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error loading technicians: ${snapshot.error}'),
                  );
                }

                final technicians = snapshot.data ?? [];

                if (technicians.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline_rounded,
                          size: 80,
                          color: isDark ? Colors.grey[600] : Colors.grey[400],
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'No technicians available',
                          style: AppTextStyle.withColor(
                            AppTextStyle.h2,
                            Theme.of(context).textTheme.bodyLarge!.color!,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return _buildLoggedInView(technicians, isDark);
              },
            ),
      bottomNavigationBar: const CustomBottomNavbar(),
    );
  }

  Widget _buildLoggedInView(List<Technician> technicians, bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: technicians.length,
      itemBuilder: (context, index) {
        return _TechnicianCard(technician: technicians[index], isDark: isDark);
      },
    );
  }

  Widget _buildGuestView(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline_rounded,
              size: 80,
              color: isDark ? Colors.grey[600] : Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'You are in Guest Mode',
              style: AppTextStyle.withColor(
                AppTextStyle.h2,
                Theme.of(context).textTheme.bodyLarge!.color!,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Sign up or log in to view technician profiles.',
              style: AppTextStyle.withColor(
                AppTextStyle.bodyMedium,
                isDark ? Colors.grey[500]! : Colors.grey[600]!,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Get.to(() => const SignupScreen()),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Sign Up',
                style: AppTextStyle.buttonMedium.copyWith(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TechnicianCard extends StatelessWidget {
  final Technician technician;
  final bool isDark;

  const _TechnicianCard({required this.technician, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shadowColor: isDark
          ? Colors.black.withOpacity(0.5)
          : Colors.grey.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: isDark ? Colors.grey[700] : Colors.grey[200],
                  child:
                      technician.imageUrl.isEmpty ||
                          technician.imageUrl == 'assets/images/logo.png'
                      ? Icon(
                          Icons.person,
                          size: 30,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        )
                      : technician.imageUrl.startsWith('http')
                      ? Image.network(
                          technician.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.person,
                              size: 30,
                              color: isDark
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                            );
                          },
                        )
                      : Image.asset(
                          technician.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.person,
                              size: 30,
                              color: isDark
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                            );
                          },
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        technician.name,
                        style: AppTextStyle.withColor(
                          AppTextStyle.h3,
                          Theme.of(context).textTheme.bodyLarge!.color!,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        technician.role,
                        style: AppTextStyle.withColor(
                          AppTextStyle.bodySmall,
                          isDark ? Colors.grey[400]! : Colors.grey[600]!,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: technician.status == 'active'
                        ? Colors.green.withOpacity(0.2)
                        : Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    technician.status,
                    style: AppTextStyle.withColor(
                      AppTextStyle.bodySmall,
                      technician.status == 'active' ? Colors.green : Colors.red,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            RichText(
              text: TextSpan(
                style: AppTextStyle.withColor(
                  AppTextStyle.bodySmall,
                  Theme.of(context).textTheme.bodySmall!.color!,
                ),
                children: [
                  const TextSpan(
                    text: 'Services: ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: technician.servicesOffered.join(', ')),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              technician.description,
              style: AppTextStyle.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
