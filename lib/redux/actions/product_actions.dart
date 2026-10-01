import 'dart:typed_data';

import '../../models/product.dart';

// Get
class FetchProductsAction {}

class FetchProductsSuccessAction {
  final List<Product> products;
  FetchProductsSuccessAction(this.products);
}

class FetchProductsFailureAction {
  final String error;
  FetchProductsFailureAction(this.error);
}

// Post
class AddProductAction {
  final Product product;

  /// Gambar baru dari galeri (opsional). Middleware mengunggahnya lebih dulu,
  /// lalu menyimpan UUID file ke field `image_url` produk.
  final Uint8List? imageBytes;
  final String? imageName;
  AddProductAction(this.product, {this.imageBytes, this.imageName});
}

class AddProductSuccessAction {
  final Product product;
  AddProductSuccessAction(this.product);
}

class AddProductFailureAction {
  final String error;
  AddProductFailureAction(this.error);
}

// Patch
class UpdateProductAction {
  final Product product; // id harus terisi
  final Uint8List? imageBytes;
  final String? imageName;
  UpdateProductAction(this.product, {this.imageBytes, this.imageName});
}

class UpdateProductSuccessAction {
  final Product product;
  UpdateProductSuccessAction(this.product);
}

class UpdateProductFailureAction {
  final String error;
  UpdateProductFailureAction(this.error);
}

// Delete
class DeleteProductAction {
  final String id;
  DeleteProductAction(this.id);
}

class DeleteProductSuccessAction {
  final String id;
  DeleteProductSuccessAction(this.id);
}

class DeleteProductFailureAction {
  final String error;
  DeleteProductFailureAction(this.error);
}

// Reset status (dipakai form setelah menampilkan pesan error)
class ResetStatusAction {}
