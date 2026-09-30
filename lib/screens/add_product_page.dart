import 'package:flutter/material.dart';

import '../models/product.dart';
import '../services/api_service.dart';

class AddProductPage extends StatefulWidget {
  final Product? product;

  const AddProductPage({super.key, this.product});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();
  final nameController = TextEditingController();
  final priceController = TextEditingController();
  final quantityController = TextEditingController();
  final descriptionController = TextEditingController();
  final imageController = TextEditingController();

  final List<String> categories = [
    'Laptop',
    'Handphone',
    'Aksesoris',
    'Elektronik',
    'Lainnya',
  ];

  String? selectedCategory;
  bool isLoading = false;

  bool get isEditMode => widget.product != null;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    if (product == null) return;

    nameController.text = product.name;
    priceController.text = product.price.toStringAsFixed(0);
    quantityController.text = product.quantity.toString();
    descriptionController.text = product.description;
    imageController.text = product.imageUrl ?? '';
    selectedCategory = product.category;
    if (!categories.contains(selectedCategory)) {
      categories.add(selectedCategory!);
    }
  }

  double? _parsePrice(String value) {
    final normalized = value.trim().replaceAll('Rp', '').replaceAll('.', '');
    return double.tryParse(normalized.replaceAll(',', '.'));
  }

  Future<void> saveProduct() async {
    if (isLoading || !_formKey.currentState!.validate()) return;

    final price = _parsePrice(priceController.text);
    final quantity = int.tryParse(quantityController.text.trim());
    if (price == null || quantity == null || selectedCategory == null) return;

    setState(() => isLoading = true);
    final imageUrl = imageController.text.trim();
    final productData = Product(
      id: widget.product?.id ?? '',
      name: nameController.text.trim(),
      price: price,
      imageUrl: imageUrl.isEmpty ? null : imageUrl,
      category: selectedCategory!,
      description: descriptionController.text.trim(),
      quantity: quantity,
    );

    try {
      if (isEditMode) {
        await _apiService.updateProduct(productData);
      } else {
        await _apiService.createProduct(productData);
      }

      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEditMode
                ? 'Produk berhasil diperbarui.'
                : 'Produk berhasil ditambahkan.',
          ),
        ),
      );
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ApiService.errorMessage(error)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isEditMode ? 'Edit Product' : 'Add Product')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nama Produk',
                hintText: 'Masukkan nama produk',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.shopping_bag),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Nama produk wajib diisi'
                  : null,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Harga',
                hintText: 'Contoh: 150000',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.money),
              ),
              validator: (value) {
                final price = _parsePrice(value ?? '');
                if (price == null) return 'Harga harus berupa angka';
                return price <= 0 ? 'Harga harus lebih dari 0' : null;
              },
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Jumlah / Stok',
                hintText: 'Contoh: 10',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.inventory_2),
              ),
              validator: (value) {
                final quantity = int.tryParse(value?.trim() ?? '');
                if (quantity == null) return 'Jumlah/stok harus berupa angka';
                return quantity < 0 ? 'Jumlah/stok tidak boleh negatif' : null;
              },
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              initialValue: selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Kategori',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              items: categories
                  .map(
                    (category) => DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    ),
                  )
                  .toList(),
              onChanged: isLoading
                  ? null
                  : (value) => setState(() => selectedCategory = value),
              validator: (value) => value == null || value.isEmpty
                  ? 'Kategori wajib dipilih'
                  : null,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: imageController,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'URL/UUID Gambar (opsional)',
                hintText: 'https://... atau UUID aset',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.image),
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Deskripsi',
                hintText: 'Masukkan deskripsi produk',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Deskripsi wajib diisi'
                  : null,
            ),
            const SizedBox(height: 30),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: isLoading ? null : saveProduct,
                child: isLoading
                    ? const SizedBox(
                        width: 25,
                        height: 25,
                        child: CircularProgressIndicator(strokeWidth: 3),
                      )
                    : Text(
                        isEditMode ? 'Simpan Perubahan' : 'Simpan Produk',
                        style: const TextStyle(fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    priceController.dispose();
    quantityController.dispose();
    descriptionController.dispose();
    imageController.dispose();
    super.dispose();
  }
}
