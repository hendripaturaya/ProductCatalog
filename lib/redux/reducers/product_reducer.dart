import '../actions/product_actions.dart';
import '../app_state.dart';

AppState productReducer(AppState state, dynamic action) {
  if (action is FetchProductsAction) {
    return AppState(
      products: state.products,
      isLoading: true,
      error: null,
      crudStatus: CrudStatus.loading,
    );
  }

  if (action is FetchProductsSuccessAction) {
    return AppState(
      products: action.products,
      isLoading: false,
      error: null,
      crudStatus: CrudStatus.success,
    );
  }

  if (action is FetchProductsFailureAction) {
    return AppState(
      products: state.products,
      isLoading: false,
      error: action.error,
      crudStatus: CrudStatus.failure,
    );
  }

  if (action is DeleteProductAction) {
    return AppState(
      products: state.products,
      isLoading: state.isLoading,
      error: null,
      crudStatus: CrudStatus.loading,
    );
  }

  if (action is DeleteProductSuccessAction) {
    return AppState(
      products: state.products
          .where((product) => product.id != action.id)
          .toList(growable: false),
      isLoading: state.isLoading,
      error: null,
      crudStatus: CrudStatus.success,
    );
  }

  if (action is DeleteProductFailureAction) {
    return AppState(
      products: state.products,
      isLoading: state.isLoading,
      error: action.error,
      crudStatus: CrudStatus.failure,
    );
  }

  return state;
}
