import '../models/product.dart';

enum CrudStatus {
  initial,
  loading,
  success,
  failure,
}

class AppState {
  final List<Product> products;
  final bool isLoading;
  final String? error;
  final CrudStatus crudStatus;

  AppState({
    this.products = const [],
    this.isLoading = false,
    this.error,
    this.crudStatus = CrudStatus.initial,
  });

  AppState copyWith({
    List<Product>? products,
    bool? isLoading,
    String? error,
    CrudStatus? crudStatus,
  }) {
    return AppState(
      products: products ?? this.products,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      crudStatus: crudStatus ?? this.crudStatus,
    );
  }
}