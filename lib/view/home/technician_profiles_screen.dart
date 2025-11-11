import 'package:capstone/utils/app_textstyles.dart';
import 'package:capstone/screens/signup/signup_screen.dart';
import 'package:capstone/models/technician.dart'; // Import the new Technician model
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart'; // For star ratings
import 'package:capstone/controllers/custom_bottom_navbar.dart';

class TechnicianProfilesScreen extends StatelessWidget {
  const TechnicianProfilesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock data for 10 technician profiles
    final List<Technician> technicians = [
      Technician(
        id: 'tech1',
        name: 'Bisu Go',
        imageUrl: 'assets/images/logo.png', // Placeholder image
        rating: 4.8,
        reviews: 120,
        servicesOffered: ['Full Detailing', 'Ceramic Coating'],
        description:
            'Experienced in high-end car detailing and paint correction.',
      ),
      Technician(
        id: 'tech2',
        name: 'Rey Ignacio',
        imageUrl: 'assets/images/logo.png',
        rating: 4.5,
        reviews: 95,
        servicesOffered: ['Interior Cleaning', 'Engine Wash'],
        description:
            'Specializes in meticulous interior care and engine bay cleaning.',
      ),
      Technician(
        id: 'tech3',
        name: 'Robert Guerrero',
        imageUrl: 'assets/images/logo.png',
        rating: 4.9,
        reviews: 150,
        servicesOffered: ['Hydrophobic Protection', 'Waxing'],
        description:
            'Master of hydrophobic treatments and long-lasting wax applications.',
      ),
      Technician(
        id: 'tech4',
        name: 'Mike Perez',
        imageUrl: 'assets/images/logo.png',
        rating: 4.7,
        reviews: 80,
        servicesOffered: ['Basic Wash', 'Tire Dressing'],
        description: 'Provides quick yet thorough basic washes and tire care.',
      ),
      Technician(
        id: 'tech5',
        name: 'Michael Domingo',
        imageUrl: 'assets/images/logo.png',
        rating: 4.6,
        reviews: 110,
        servicesOffered: ['Headlight Restoration', 'Scratch Removal'],
        description:
            'Expert in restoring faded headlights and minor scratch repair.',
      ),
      Technician(
        id: 'tech6',
        name: 'JP Gilbuena',
        imageUrl: 'assets/images/logo.png',
        rating: 4.4,
        reviews: 70,
        servicesOffered: ['Motorcycle Detailing', 'Chrome Polishing'],
        description:
            'Dedicated to bringing out the shine in motorcycles and chrome parts.',
      ),
      Technician(
        id: 'tech7',
        name: 'Yuan Castillo',
        imageUrl: 'assets/images/logo.png',
        rating: 4.8,
        reviews: 130,
        servicesOffered: ['Odor Removal', 'Upholstery Cleaning'],
        description:
            'Specializes in eliminating stubborn odors and deep cleaning upholstery.',
      ),
      Technician(
        id: 'tech8',
        name: 'Jay Ramirez',
        imageUrl: 'assets/images/logo.png',
        rating: 4.5,
        reviews: 90,
        servicesOffered: ['Window Tinting', 'Glass Treatment'],
        description:
            'Skilled in professional window tinting and advanced glass treatments.',
      ),
      Technician(
        id: 'tech9',
        name: 'Ernest Del Mundo',
        imageUrl: 'assets/images/logo.png',
        rating: 4.7,
        reviews: 105,
        servicesOffered: ['Fleet Washing', 'Commercial Vehicles'],
        description:
            'Manages large fleet washing and detailing for commercial clients.',
      ),
      Technician(
        id: 'tech10',
        name: 'James Mendoza',
        imageUrl: 'assets/images/logo.png',
        rating: 4.9,
        reviews: 160,
        servicesOffered: ['Paint Protection Film', 'Vinyl Wraps'],
        description:
            'Certified installer of paint protection films and custom vinyl wraps.',
      ),
    ];

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
          : _buildLoggedInView(technicians, isDark),
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
                  backgroundImage: AssetImage(technician.imageUrl),
                  backgroundColor: isDark ? Colors.grey[700] : Colors.grey[200],
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
                      Row(
                        children: [
                          RatingBarIndicator(
                            rating: technician.rating,
                            itemBuilder: (context, index) => Icon(
                              Icons.star,
                              color: Theme.of(context).primaryColor,
                            ),
                            itemCount: 5,
                            itemSize: 18.0,
                            direction: Axis.horizontal,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${technician.rating} (${technician.reviews} reviews)',
                            style: AppTextStyle.withColor(
                              AppTextStyle.bodySmall,
                              isDark ? Colors.grey[400]! : Colors.grey[600]!,
                            ),
                          ),
                        ],
                      ),
                    ],
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
            Text(technician.description, style: AppTextStyle.bodySmall),
          ],
        ),
      ),
    );
  }
}
