import 'package:capstone/models/product.dart';
import 'package:capstone/utils/app_textstyles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CartItem {
  final Product product;
  final String selectedSize;
  final double price;

  CartItem({
    required this.product,
    required this.selectedSize,
    required this.price,
  });
}

class CartController extends GetxController {
  final RxList<CartItem> cartItems = <CartItem>[].obs;

  double get total => cartItems.fold(0, (sum, item) => sum + item.price);

  bool addToCart(Product product, String size, double price) {
    final context = Get.context!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (cartItems.length >= 2) {
      Get.snackbar(
        'Cart Limit Reached',
        'You can only add a maximum of 2 services.',
        titleText: Text(
          'Cart Limit Reached',
          style: AppTextStyle.withColor(
            AppTextStyle.h3,
            isDark ? const Color(0xFF7F1618) : Colors.white,
          ),
        ),
        messageText: Text(
          'You can only add a maximum of 2 services.',
          style: AppTextStyle.withColor(
            AppTextStyle.bodySmall,
            isDark ? const Color(0xFF7F1618) : Colors.white,
          ),
        ),
        snackPosition: SnackPosition.TOP,
        backgroundColor: isDark ? Colors.white : const Color(0xFF7F1618),
        colorText: isDark ? Colors.white : const Color(0xFF7F1618),
      );
      return false;
    } else {
      cartItems.add(
        CartItem(product: product, selectedSize: size, price: price),
      );
      Get.snackbar(
        'Book Cart added',
        '${product.name} ($size)',
        titleText: Text(
          'Book Cart added',
          style: AppTextStyle.withColor(
            AppTextStyle.bodySmall,
            isDark ? const Color(0xFF7F1618) : Colors.white,
          ),
        ),
        messageText: Text(
          '${product.name} ($size)',
          style: AppTextStyle.withColor(
            AppTextStyle.bodySmall,
            isDark ? const Color(0xFF7F1618) : Colors.white,
          ),
        ),
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 2),
        backgroundColor: isDark ? Colors.white : const Color(0xFF7F1618),
        colorText: isDark ? const Color(0xFF7F1618) : Colors.white,
        margin: const EdgeInsets.all(10),
        borderRadius: 5,
      );
      return true;
    }
  }

  void addToCartSilently(Product product, String size, double price) {
    cartItems.add(CartItem(product: product, selectedSize: size, price: price));
  }

  void removeFromCart(CartItem cartItem) {
    cartItems.remove(cartItem);
  }
}
