import 'package:capstone/models/product.dart';
import 'package:capstone/view/product/product_card.dart';
import 'package:flutter/material.dart';

class ProductGridDetailing extends StatelessWidget {
  const ProductGridDetailing({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return GestureDetector(
          onTap: () {},
          child: ProductCard(product: product),
        );
      },
    );
  }
}
