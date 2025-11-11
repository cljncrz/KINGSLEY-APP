import 'package:capstone/controllers/product_controller.dart';
import 'package:capstone/models/product.dart';
import 'package:capstone/utils/app_textstyles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final ProductController productController = Get.find<ProductController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      constraints: BoxConstraints(maxWidth: screenWidth * 0.9),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2F2F2F) : const Color(0xFF7F1618),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Stack(
            children: [
              //image
              AspectRatio(
                aspectRatio: 11 / 9,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: Image.asset(
                    product.imageUrl,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              // favorite button
              Positioned(
                right: 8,
                top: 8,
                child: Obx(
                  () => IconButton(
                    icon: Icon(
                      product.isFavorite.value
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: product.isFavorite.value
                          ? Theme.of(context).primaryColor
                          : const Color(0xFF7F1618),
                    ),
                    onPressed: () => productController.toggleFavorite(product),
                  ),
                ),
              ),
            ],
          ),
          // product details
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  product.name,
                  textAlign: TextAlign.center,
                  style: AppTextStyle.withColor(
                    AppTextStyle.withWeight(AppTextStyle.h3, FontWeight.bold),
                    isDark ? Colors.white : Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  product.subTitle,
                  textAlign: TextAlign.center,
                  style: AppTextStyle.withColor(
                    AppTextStyle.small,
                    isDark ? Colors.white : Colors.white,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
