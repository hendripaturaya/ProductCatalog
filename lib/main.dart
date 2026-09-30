import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';

import 'screens/login_page.dart';
import 'redux/app_state.dart';
import 'redux/middleware/product_middleware.dart';
import 'redux/reducers/product_reducer.dart';
import 'services/api_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final apiService = ApiService();
  final store = Store<AppState>(
    productReducer,
    initialState: AppState(),
    middleware: createProductMiddleware(apiService),
  );

  runApp(
    StoreProvider<AppState>(store: store, child: const ProductCatalogApp()),
  );
}

class ProductCatalogApp extends StatelessWidget {
  const ProductCatalogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Product Catalog',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const LoginPage(),
    );
  }
}
