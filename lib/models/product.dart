import 'package:get/get.dart';

class Product {
  final String name;
  final String category;
  final String imageUrl;
  late final RxBool isFavorite;
  final String subTitle;
  final String description;

  final Map<String, double> prices;
  Product({
    required this.name,
    required this.category,
    required this.imageUrl,
    required this.subTitle,
    required this.description,
    bool isFavorite = false,
    this.prices = const {},
  }) {
    this.isFavorite = isFavorite.obs;
  }
}

final List<Product> products = [
  Product(
    name: 'Motorcycle',
    category: 'Wash Services',
    imageUrl: 'assets/wash_services/motorcycle_wash_armor_all.png',
    subTitle: '(wash + armor all)',
    description: 'Production runs for all motor types averaged 45 minutes ',
    prices: {'399cc below': 120.00, '400cc above': 140.00},
    isFavorite: true,
  ),
  Product(
    name: 'Carwash',
    category: 'Wash Services',
    imageUrl: 'assets/wash_services/carwash_wash_armor_all.png',
    subTitle: '(wash + armor all)',
    description: 'Production runs for all car types averaged 45 minutes',
    prices: {'5-seater': 280.00, '7-seater': 390.00},
  ),
  Product(
    name: 'Hydrophobic Wax',
    category: 'Wash Services',
    imageUrl: 'assets/wash_services/hydrophobic_wax.png',
    subTitle: '(with free carwash)',
    description: 'Production runs for all car types averaged 45 minutes',
    prices: {'5-seater': 750.00, '7-seater': 850.00},
  ),
  Product(
    name: 'Labor Wax',
    category: 'Wash Services',
    imageUrl: 'assets/wash_services/labor_wax.png',
    subTitle: '',
    description: 'Production runs for all car types averaged 45 minutes',
    prices: {'5-seater': 600.00, '7-seater': 800.00},
  ),
  Product(
    name: 'Meguiars Carnauba Wash',
    category: 'Wash Services',
    imageUrl: 'assets/wash_services/meguiars_carnauba_wash.png',
    subTitle: '(with free carwash)',
    description: 'Production runs for all car types averaged 45 minutes',
    prices: {'5-seater': 650.00, '7-seater': 750.00},
  ),
  Product(
    name: 'Double Wax',
    category: 'Wash Services',
    imageUrl: 'assets/wash_services/double_wax.png',
    subTitle: '(with free carwash)',
    description: 'Production runs for all car types averaged 45 minutes',
    prices: {'5-seater': 1600.00, '7-seater': 2000.00},
  ),
  Product(
    name: 'Ceiling Cleaning',
    category: 'Wash Services',
    imageUrl: 'assets/wash_services/ceiling_cleaning.png',
    subTitle: '(ceiling only)',
    description: 'Production runs for all car types averaged 45 minutes',
    prices: {'5-seater': 1100.00, '7-seater': 1300.00},
  ),
  Product(
    name: 'Asphalt Removal',
    category: 'Wash Services',
    imageUrl: 'assets/wash_services/asphalt_removal.png',
    subTitle: '',
    description: 'Production runs for all car types averaged 45 minutes',
    prices: {'5-seater': 250.00, '7-seater': 350.00},
  ),
  Product(
    name: 'Seat Cover',
    category: 'Wash Services',
    imageUrl: 'assets/wash_services/seat_cover_install.png',
    subTitle: '(install)',
    description: 'Production runs for all car types averaged 45 minutes',
    prices: {'5-seater': 350.00, '7-seater': 500.00},
  ),
  Product(
    name: 'Seat Cover',
    category: 'Wash Services',
    imageUrl: 'assets/wash_services/seat_cover_remover.png',
    subTitle: '(removal)',
    description: 'Production runs for all car types averaged 45 minutes',
    prices: {'5-seater': 200.00, '7-seater': 300.00},
  ),
  Product(
    name: 'Underwash',
    category: 'Wash Services',
    imageUrl: 'assets/wash_services/underwash.png',
    subTitle: '(by assesment)',
    description: 'Production runs for all car types averaged 45 minutes',
    prices: {'5-seater': 700.00, '7-seater': 900.00},
  ),
  Product(
    name: 'Microtex  Bac to Zero',
    category: 'Wash Services',
    imageUrl: 'assets/wash_services/microtex_bac_to_zero.png',
    subTitle: '(anti-bacteria treatment)',
    description: 'Production runs for all car types averaged 45 minutes',
    prices: {'5-seater': 700.00, '7-seater': 900.00},
  ),
];
final List<Product> detailingservices = [
  Product(
    name: 'Hydrophobic Protection',
    category: 'Detailing Services',
    imageUrl:
        'assets/detailing_services/hydrophobic_protection.png', // Corrected image
    subTitle: '(with carwash)',
    description: '',
    prices: {'5-seater': 1200.00, '7-seater': 1600.00},
  ),
  Product(
    name: 'Ceramic Coating',
    category: 'Detailing Services',
    imageUrl:
        'assets/detailing_services/ceramic_coating.png', // Placeholder, update with correct image
    subTitle: '(exterior detailing included)',
    description: 'Production runs for all car types averaged 45 minutes',
    prices: {'5-seater': 18000.00, '7-seater': 26000.00},
  ),
  Product(
    name: 'Glass Detailing & Acid Rain',
    category: 'Detailing Services',
    imageUrl:
        'assets/detailing_services/glass_detailing&acid_rain.png', // Placeholder, update with correct image
    subTitle: '(anti-bacteria treatment)',
    description: 'Production runs for all car types averaged 45 minutes',
    prices: {'5-seater': 1500.00, '7-seater': 2000.00},
  ),
  Product(
    name: 'Exterior Detailing',
    category: 'Detailing Services',
    imageUrl:
        'assets/detailing_services/exterior_detailing.png', // Placeholder, update with correct image
    subTitle: '',
    description: 'Production runs for all car types averaged 45 minutes',
    prices: {'5-seater': 4500.00, '7-seater': 5500.00},
  ),
  Product(
    name: 'Per Panel Detailing ',
    category: 'Detailing Services',
    imageUrl:
        'assets/detailing_services/per_panel_detailing.png', // Placeholder, update with correct image
    subTitle: '',
    description: 'Production runs for all car types averaged 45 minutes',
    prices: {'5-seater': 700.00, '7-seater': 900.00},
  ),
  Product(
    name: 'Interior Detail',
    category: 'Detailing Services',
    imageUrl:
        'assets/detailing_services/interior_detailing.png', // Placeholder, update with correct image
    subTitle: '(standard)',
    description: 'Production runs for all car types averaged 45 minutes',
    prices: {'5-seater': 5000.00, '7-seater': 6000.00},
  ),
  Product(
    name: 'Deep Cleaning',
    category: 'Detailing Services',
    imageUrl: 'assets/detailing_services/deep_cleaning.png',
    subTitle: '',
    description: 'Production runs for all car types averaged 45 minutes',
    prices: {'5-seater': 3000.00, '7-seater': 4000.00},
  ),
  Product(
    name: 'Interior & Deep Cleaning ',
    category: 'Detailing Services',
    imageUrl: 'assets/detailing_services/interior_detail+deep_cleaning.png',
    subTitle: '(interior detailing included)',
    description: 'Production runs for all car types averaged 45 minutes',
    prices: {'5-seater': 7000.00, '7-seater': 9000.00},
  ),
  Product(
    name: 'Full Package Detailing',
    category: 'Detailing Services',
    imageUrl: 'assets/detailing_services/full_package_detailing.png',
    subTitle: '',
    description: 'Production runs for all car types averaged 45 minutes',
    prices: {'5-seater': 10500.00, '7-seater': 12500.00},
  ),
];
