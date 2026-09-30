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
  AddProductAction(this.product);
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
  UpdateProductAction(this.product);
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
