import 'package:capstone/models/product.dart';
import 'package:capstone/controllers/product_controller.dart';
import 'package:capstone/utils/app_textstyles.dart';
import 'package:capstone/controllers/custom_bottom_navbar.dart';
import 'package:capstone/controllers/cart_controller.dart';
import 'package:capstone/view/widgets/book_now_screen.dart';
import 'package:flutter/material.dart';
import 'package:capstone/view/product/size_selector.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:capstone/screens/signin_screen.dart';
import 'package:share_plus/share_plus.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;
  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  String? _selectedSize;
  double? _selectedPrice;
  final CartController cartController = Get.find<CartController>();
  final ProductController productController = Get.find<ProductController>();

  @override
  void initState() {
    super.initState();
    // Set initial size and price
    if (widget.product.prices.isNotEmpty) {
      _selectedSize = widget.product.prices.keys.first;
      _selectedPrice = widget.product.prices.values.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenHeight = screenSize.height;
    final screenWidth = screenSize.width;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios),
        ),
        title: Text(
          'Details',
          style: AppTextStyle.withColor(
            AppTextStyle.bodyMedium,
            isDark ? Colors.white : Colors.black,
          ),
        ),
        actions: [
          // share button
          IconButton(
            onPressed: () => _shareProduct(
              context,
              widget.product.name,
              widget.product.category,
            ),
            icon: Icon(
              Icons.share,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                // image
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.asset(
                    widget.product.imageUrl,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                // favorite button
                Positioned(
                  child: Obx(
                    () => IconButton(
                      onPressed: () =>
                          productController.toggleFavorite(widget.product),
                      icon: Icon(
                        widget.product.isFavorite.value
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: widget.product.isFavorite.value
                            ? Theme.of(context).primaryColor
                            : const Color(0xFF7F1618),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            //product details
            Padding(
              padding: EdgeInsets.all(screenWidth * 0.04),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.product.name,
                              style: AppTextStyle.bodyMedium.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(
                                  context,
                                ).textTheme.headlineMedium!.color!,
                              ),
                            ),
                            if (widget.product.subTitle.isNotEmpty)
                              Text(
                                widget.product.subTitle,
                                style: AppTextStyle.bodySmall.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(
                                    context,
                                  ).textTheme.bodySmall!.color!,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Price Display
                  if (_selectedPrice != null)
                    Text(
                      _selectedPrice!.toStringAsFixed(2),
                      style: AppTextStyle.withColor(
                        AppTextStyle.h2,
                        Theme.of(context).primaryColor,
                      ),
                    ),
                  const SizedBox(height: 10),
                  Text(
                    widget.product.category,
                    style: AppTextStyle.withColor(
                      AppTextStyle.bodyMedium,
                      isDark ? Colors.grey[400]! : Colors.grey[600]!,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.05),
                  if (widget.product.prices.isNotEmpty) ...[
                    Text(
                      widget.product.name.contains('Motorcycle')
                          ? 'Select the Motorcycle Engine Size:'
                          : 'Select Car Engine Size:',
                      style: AppTextStyle.withColor(
                        AppTextStyle.bodyMedium,
                        isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 10),
                    //size selector
                    SizeSelector(
                      sizes: _getSizesForProduct(widget.product),
                      selectedSize: _selectedSize,
                      onSizeSelected: (size) {
                        setState(() {
                          _selectedSize = size;
                          _selectedPrice = widget.product.prices[size];
                        });
                      },
                    ),
                    SizedBox(height: screenWidth * 0.05),
                  ],
                  Text(
                    widget.product.description,
                    style: AppTextStyle.withColor(
                      AppTextStyle.bodyMedium,
                      isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      // button
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.all(screenWidth * 0.04),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _handleAddToCart(context),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        vertical: screenHeight * 0.02,
                      ),
                      backgroundColor: Theme.of(context).primaryColor,
                    ),
                    child: Text(
                      'Add to BookCart',
                      style: AppTextStyle.withColor(
                        AppTextStyle.buttonMedium,
                        Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _handleBookNow(context),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        vertical: screenHeight * 0.02,
                      ),
                      backgroundColor: Theme.of(context).primaryColor,
                    ),
                    child: Text(
                      'Book Now',
                      style: AppTextStyle.withColor(
                        AppTextStyle.buttonMedium,
                        Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const CustomBottomNavbar(),
        ],
      ),
    );
  }

  void _showGuestDialog(BuildContext context) {
    Get.dialog(
      AlertDialog(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Guest Mode',
          style: AppTextStyle.bodyMedium.copyWith(
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        content: Text(
          'Please sign in to book services.',
          style: AppTextStyle.bodySmall.copyWith(
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancel',
              style: AppTextStyle.buttonMedium.copyWith(
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Get.to(() => const SigninScreen()),

            child: Text(
              'Sign In',
              style: AppTextStyle.buttonMedium.copyWith(
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleAddToCart(BuildContext context) {
    if (FirebaseAuth.instance.currentUser == null) {
      _showGuestDialog(context);
    } else {
      if (_selectedSize != null && _selectedPrice != null) {
        final bool added = cartController.addToCart(
          widget.product,
          _selectedSize!,
          _selectedPrice!,
        );
        // You can optionally use the 'added' boolean for further UI logic here,
        // for example, triggering an animation.
      }
    }
  }

  void _handleBookNow(BuildContext context) {
    if (FirebaseAuth.instance.currentUser == null) {
      _showGuestDialog(context);
    } else {
      if (_selectedSize != null && _selectedPrice != null) {
        Get.to(
          () => BookNowScreen(
            product: widget.product,
            selectedSize: _selectedSize!,
            selectedPrice: _selectedPrice!,
          ),
        );
      }
    }
  }

  List<String> _getSizesForProduct(Product product) {
    return product.prices.keys.toList();
  }

  // share product
  Future<void> _shareProduct(
    BuildContext context,
    String productName,
    String name,
  ) async {
    // get the render box for share position origin (required for ipad)
    final box = context.findRenderObject() as RenderBox?;

    const String shopLink = 'https:// kingsleycarwash.com';
    final String shareMessage = '$name\n\nShop now at $shopLink';

    try {
      final ShareResult result = await Share.share(
        shareMessage,
        subject: productName,
        sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
      );

      if (result.status == ShareResultStatus.success) {
        debugPrint('Thank You for sharing!');
      }
    } catch (e) {
      debugPrint('Error Sharing: $e');
    }
  }
}
