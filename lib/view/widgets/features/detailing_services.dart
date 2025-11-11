import 'package:capstone/models/product.dart';
import 'package:capstone/view/product/product_grid.dart';
import 'package:flutter/material.dart';

class DetailingServices extends StatelessWidget {
  const DetailingServices({super.key});

  @override
  Widget build(BuildContext context) {
    return ProductGrid(products: detailingservices);
  }
}
