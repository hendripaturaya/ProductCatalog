import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';

import '../models/product.dart';
import '../redux/actions/product_actions.dart';
import '../redux/app_state.dart';
import '../widgets/product_card.dart';
import 'add_product_page.dart';
import 'product_detail_page.dart';

class ProductListPage extends StatefulWidget {
  const ProductListPage({super.key});

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  final TextEditingController _searchController = TextEditingController();
  String? _deletingProductId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openProductForm(
    _ProductListViewModel viewModel, [
    Product? product,
  ]) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => AddProductPage(product: product)),
    );

    if (result == true && mounted) {
      await viewModel.loadProducts();
    }
  }

  Future<void> _deleteProduct(
    Product product,
    _ProductListViewModel viewModel,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text('Hapus produk "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _deletingProductId = product.id);
    try {
      final error = await viewModel.deleteProduct(product.id);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Produk berhasil dihapus.'),
          backgroundColor: error == null ? null : Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _deletingProductId = null);
      }
    }
  }

  List<Product> _filterProducts(List<Product> products) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return products;

    return products
        .where((product) => product.name.toLowerCase().contains(query))
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, _ProductListViewModel>(
      onInit: (store) {
        if (store.state.crudStatus == CrudStatus.initial) {
          store.dispatch(FetchProductsAction());
        }
      },
      converter: (store) => _ProductListViewModel(
        products: store.state.products,
        isLoading: store.state.isLoading,
        isInitial: store.state.crudStatus == CrudStatus.initial,
        error: store.state.error,
        loadProducts: () async {
          await store.dispatch(FetchProductsAction());
        },
        deleteProduct: (id) async {
          await store.dispatch(DeleteProductAction(id));
          return store.state.crudStatus == CrudStatus.failure
              ? store.state.error ?? 'Produk gagal dihapus. Silakan coba lagi.'
              : null;
        },
      ),
      builder: (context, viewModel) => _buildScaffold(context, viewModel),
    );
  }

  Widget _buildScaffold(BuildContext context, _ProductListViewModel viewModel) {
    final isRequestActive = viewModel.isLoading || viewModel.isInitial;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product List'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: isRequestActive
                ? null
                : () async => viewModel.loadProducts(),
            tooltip: 'Muat ulang data',
          ),
        ],
      ),
      body: _buildBody(viewModel),
      floatingActionButton: FloatingActionButton(
        onPressed: isRequestActive
            ? null
            : () async => _openProductForm(viewModel),
        tooltip: 'Tambah produk',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody(_ProductListViewModel viewModel) {
    if ((viewModel.isLoading || viewModel.isInitial) &&
        viewModel.products.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (viewModel.error != null && viewModel.products.isEmpty) {
      return _buildErrorState(viewModel.error!, viewModel.loadProducts);
    }

    final visibleProducts = _filterProducts(viewModel.products);
    final isSearching = _searchController.text.trim().isNotEmpty;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Cari produk...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      tooltip: 'Hapus pencarian',
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
        if (viewModel.error != null)
          _buildInlineError(viewModel.error!, viewModel.loadProducts),
        Expanded(
          child: RefreshIndicator(
            onRefresh: viewModel.loadProducts,
            child: visibleProducts.isEmpty
                ? _buildEmptyList(isSearching: isSearching)
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(12),
                    itemCount: visibleProducts.length,
                    itemBuilder: (context, index) {
                      final product = visibleProducts[index];
                      return ProductCard(
                        product: product,
                        isDeleting: _deletingProductId == product.id,
                        onDetail: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ProductDetailPage(product: product),
                            ),
                          );
                        },
                        onEdit: () => _openProductForm(viewModel, product),
                        onDelete: () => _deleteProduct(product, viewModel),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(String error, Future<void> Function() retry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.red),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async => retry(),
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInlineError(String error, Future<void> Function() retry) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 8),
          Expanded(
            child: Text(error, style: const TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () async => retry(),
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyList({required bool isSearching}) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: 360,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isSearching ? Icons.search_off : Icons.inventory_2_outlined,
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: 12),
                Text(
                  isSearching ? 'Produk tidak ditemukan.' : 'Belum ada produk.',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                const Text('Tarik ke bawah untuk memuat ulang.'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ProductListViewModel {
  const _ProductListViewModel({
    required this.products,
    required this.isLoading,
    required this.isInitial,
    required this.error,
    required this.loadProducts,
    required this.deleteProduct,
  });

  final List<Product> products;
  final bool isLoading;
  final bool isInitial;
  final String? error;
  final Future<void> Function() loadProducts;
  final Future<String?> Function(String id) deleteProduct;
}
