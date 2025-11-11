import 'package:capstone/models/product.dart';
import 'package:get/get.dart';

class ProductController extends GetxController {
  // Make the list of all products reactive
  final RxList<Product> allProducts = <Product>[].obs;

  @override
  void onInit() {
    super.onInit();
    // Initialize with the static product lists
    allProducts.addAll(products);
    allProducts.addAll(detailingservices);
  }

  // Getter for favorite products
  List<Product> get favoriteProducts =>
      allProducts.where((p) => p.isFavorite.value).toList();

  // Method to toggle favorite status
  void toggleFavorite(Product product) {
    product.isFavorite.toggle();
  }

  // Method to remove a product from favorites
  void removeFromFavorites(Product product) {
    product.isFavorite.value = false;
  }
}
