import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:redux/redux.dart';

import '../../models/product.dart';
import '../../services/api_service.dart';
import '../actions/product_actions.dart';
import '../app_state.dart';

List<Middleware<AppState>> createProductMiddleware(ApiService api) => [
  TypedMiddleware<AppState, FetchProductsAction>(
    (store, action, next) => _fetchProducts(api, store, action, next),
  ).call,
  TypedMiddleware<AppState, AddProductAction>(
    (store, action, next) => _addProduct(api, store, action, next),
  ).call,
  TypedMiddleware<AppState, UpdateProductAction>(
    (store, action, next) => _updateProduct(api, store, action, next),
  ).call,
  TypedMiddleware<AppState, DeleteProductAction>(
    (store, action, next) => _deleteProduct(api, store, action, next),
  ).call,
];

Future<void> _fetchProducts(
  ApiService api,
  Store<AppState> store,
  FetchProductsAction action,
  NextDispatcher next,
) async {
  next(action);

  try {
    final products = await api.getProducts();

    store.dispatch(FetchProductsSuccessAction(products));
  } on DioException catch (e) {
    store.dispatch(FetchProductsFailureAction(ApiService.errorMessage(e)));
  } catch (e) {
    store.dispatch(FetchProductsFailureAction(ApiService.errorMessage(e)));
  }
}

Future<void> _addProduct(
  ApiService api,
  Store<AppState> store,
  AddProductAction action,
  NextDispatcher next,
) async {
  next(action);

  try {
    final product = await _withUploadedImage(
      api,
      action.product,
      action.imageBytes,
      action.imageName,
    );

    final created = await api.createProduct(product);

    store.dispatch(AddProductSuccessAction(created));
  } on DioException catch (e) {
    store.dispatch(AddProductFailureAction(ApiService.errorMessage(e)));
  } catch (e) {
    store.dispatch(AddProductFailureAction(ApiService.errorMessage(e)));
  }
}

Future<void> _updateProduct(
  ApiService api,
  Store<AppState> store,
  UpdateProductAction action,
  NextDispatcher next,
) async {
  next(action);

  try {
    final product = await _withUploadedImage(
      api,
      action.product,
      action.imageBytes,
      action.imageName,
    );

    final updated = await api.updateProduct(product);

    store.dispatch(UpdateProductSuccessAction(updated));
  } on DioException catch (e) {
    store.dispatch(UpdateProductFailureAction(ApiService.errorMessage(e)));
  } catch (e) {
    store.dispatch(UpdateProductFailureAction(ApiService.errorMessage(e)));
  }
}

Future<void> _deleteProduct(
  ApiService api,
  Store<AppState> store,
  DeleteProductAction action,
  NextDispatcher next,
) async {
  next(action);

  try {
    await api.deleteProduct(action.id);

    store.dispatch(DeleteProductSuccessAction(action.id));
  } on DioException catch (e) {
    store.dispatch(DeleteProductFailureAction(ApiService.errorMessage(e)));
  } catch (e) {
    store.dispatch(DeleteProductFailureAction(ApiService.errorMessage(e)));
  }
}

Future<Product> _withUploadedImage(
  ApiService api,
  Product product,
  Uint8List? bytes,
  String? filename,
) async {
  if (bytes == null) {
    return product;
  }

  final fileId = await api.uploadImage(bytes, filename ?? 'product.jpg');

  return Product(
    id: product.id,
    name: product.name,
    price: product.price,
    imageUrl: fileId,
    category: product.category,
    description: product.description,
    quantity: product.quantity,
  );
}
