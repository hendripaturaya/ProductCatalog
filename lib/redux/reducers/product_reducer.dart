import '../actions/product_actions.dart';
import '../app_state.dart';

AppState productReducer(AppState state, dynamic action) {
  // GET
  if (action is FetchProductsAction) {
    return state.copyWith(
      isLoading: true,
      error: null,
      crudStatus: CrudStatus.loading,
    );
  }

  if (action is FetchProductsSuccessAction) {
    return state.copyWith(
      products: action.products,
      isLoading: false,
      error: null,
      crudStatus: CrudStatus.success,
    );
  }

  if (action is FetchProductsFailureAction) {
    return state.copyWith(
      isLoading: false,
      error: action.error,
      crudStatus: CrudStatus.failure,
    );
  }

  // POST
  if (action is AddProductAction) {
    return state.copyWith(
      isLoading: true,
      error: null,
      crudStatus: CrudStatus.loading,
    );
  }

  if (action is AddProductSuccessAction) {
    return state.copyWith(
      products: [...state.products, action.product],
      isLoading: false,
      error: null,
      crudStatus: CrudStatus.success,
    );
  }

  if (action is AddProductFailureAction) {
    return state.copyWith(
      isLoading: false,
      error: action.error,
      crudStatus: CrudStatus.failure,
    );
  }

  // PATCH
  if (action is UpdateProductAction) {
    return state.copyWith(
      isLoading: true,
      error: null,
      crudStatus: CrudStatus.loading,
    );
  }

  if (action is UpdateProductSuccessAction) {
    final updatedProducts = state.products.map((product) {
      if (product.id == action.product.id) {
        return action.product;
      }
      return product;
    }).toList();

    return state.copyWith(
      products: updatedProducts,
      isLoading: false,
      error: null,
      crudStatus: CrudStatus.success,
    );
  }

  if (action is UpdateProductFailureAction) {
    return state.copyWith(
      isLoading: false,
      error: action.error,
      crudStatus: CrudStatus.failure,
    );
  }

  // DELETE
  if (action is DeleteProductAction) {
    return state.copyWith(
      isLoading: true,
      error: null,
      crudStatus: CrudStatus.loading,
    );
  }

  if (action is DeleteProductSuccessAction) {
    return state.copyWith(
      products: state.products
          .where((product) => product.id != action.id)
          .toList(),
      isLoading: false,
      error: null,
      crudStatus: CrudStatus.success,
    );
  }

  if (action is DeleteProductFailureAction) {
    return state.copyWith(
      isLoading: false,
      error: action.error,
      crudStatus: CrudStatus.failure,
    );
  }

  return state;
}