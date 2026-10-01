import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:image_picker/image_picker.dart';

import '../models/product.dart';
import '../redux/actions/product_actions.dart';
import '../redux/app_state.dart';
import '../services/api_service.dart';
import '../widgets/gradient_header.dart';

class AddProductPage extends StatefulWidget {
  final Product? product;

  const AddProductPage({super.key, this.product});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  static const _imageSize = 200.0;

  final _formKey = GlobalKey<FormState>();
  final _imagePicker = ImagePicker();
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

  // Gambar yang baru dipilih dari galeri (belum diunggah ke server).
  Uint8List? _pickedImageBytes;
  String? _pickedImageName;

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

  /// URL gambar dari field URL/UUID (UUID diubah menjadi URL aset penuh).
  String? get _currentImageUrl {
    final value = imageController.text.trim();
    if (value.isEmpty) return null;
    return Product(
      id: '',
      name: '',
      price: 0,
      imageUrl: value,
      category: '',
      description: '',
      quantity: 0,
    ).displayImageUrl;
  }

  bool get _hasImage => _pickedImageBytes != null || _currentImageUrl != null;

  double? _parsePrice(String value) {
    final normalized = value.trim().replaceAll('Rp', '').replaceAll('.', '');
    return double.tryParse(normalized.replaceAll(',', '.'));
  }

  Future<void> _pickFromGallery() async {
    try {
      final file = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (file == null) return;

      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() {
        _pickedImageBytes = bytes;
        _pickedImageName = file.name;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak dapat membuka galeri. Periksa izin aplikasi.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _removeImage() {
    setState(() {
      _pickedImageBytes = null;
      _pickedImageName = null;
      imageController.clear();
    });
  }

  Future<void> _showImageOptions() async {
    if (isLoading) return;

    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Pilih dari Galeri'),
              onTap: () => Navigator.pop(sheetContext, 'gallery'),
            ),
            if (_hasImage)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text(
                  'Hapus Gambar',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () => Navigator.pop(sheetContext, 'remove'),
              ),
          ],
        ),
      ),
    );

    if (action == 'gallery') {
      await _pickFromGallery();
    } else if (action == 'remove') {
      _removeImage();
    }
  }

  Future<void> saveProduct() async {
    if (isLoading || !_formKey.currentState!.validate()) return;

    final price = _parsePrice(priceController.text);
    final quantity = int.tryParse(quantityController.text.trim());
    if (price == null || quantity == null || selectedCategory == null) return;

    final store = StoreProvider.of<AppState>(context, listen: false);
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

    setState(() => isLoading = true);

    try {
      // Kirim action ke Redux. Middleware mengunggah gambar (jika ada) lalu
      // memanggil API; hasilnya masuk ke state lewat reducer.
      await store.dispatch(
        isEditMode
            ? UpdateProductAction(
                productData,
                imageBytes: _pickedImageBytes,
                imageName: _pickedImageName,
              )
            : AddProductAction(
                productData,
                imageBytes: _pickedImageBytes,
                imageName: _pickedImageName,
              ),
      );

      if (!mounted) return;
      setState(() => isLoading = false);

      final state = store.state;
      if (state.crudStatus == CrudStatus.failure) {
        final message = state.error ?? 'Produk gagal disimpan. Coba lagi.';
        store.dispatch(ResetStatusAction());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
        return;
      }

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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView(
        child: Column(
          children: [
            GradientHeader(
              icon: isEditMode
                  ? Icons.edit_note_rounded
                  : Icons.add_box_rounded,
              title: isEditMode ? 'Edit Product' : 'Add Product',
              subtitle: isEditMode
                  ? 'Perbarui informasi produk.'
                  : 'Tambahkan produk baru ke katalog.',
            ),
            Transform.translate(
              offset: const Offset(0, -48),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildFormCard(context, colorScheme),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormCard(BuildContext context, ColorScheme colorScheme) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Data Produk',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Lengkapi informasi produk di bawah ini.',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 20),
              _buildImagePicker(context),
              const SizedBox(height: 20),
              TextFormField(
                controller: nameController,
                textInputAction: TextInputAction.next,
                decoration: _fieldDecoration(
                  label: 'Nama Produk',
                  hint: 'Masukkan nama produk',
                  icon: Icons.shopping_bag_outlined,
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Nama produk wajib diisi'
                    : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: priceController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                decoration: _fieldDecoration(
                  label: 'Harga',
                  hint: 'Contoh: 150000',
                  icon: Icons.payments_outlined,
                ),
                validator: (value) {
                  final price = _parsePrice(value ?? '');
                  if (price == null) return 'Harga harus berupa angka';
                  return price <= 0 ? 'Harga harus lebih dari 0' : null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                decoration: _fieldDecoration(
                  label: 'Jumlah / Stok',
                  hint: 'Contoh: 10',
                  icon: Icons.inventory_2_outlined,
                ),
                validator: (value) {
                  final quantity = int.tryParse(value?.trim() ?? '');
                  if (quantity == null) return 'Jumlah/stok harus berupa angka';
                  return quantity < 0
                      ? 'Jumlah/stok tidak boleh negatif'
                      : null;
                },
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: selectedCategory,
                decoration: _fieldDecoration(
                  label: 'Kategori',
                  icon: Icons.category_outlined,
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
              const SizedBox(height: 14),
              TextFormField(
                controller: imageController,
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.next,
                onChanged: (_) => setState(() {
                  // Mengetik URL manual membatalkan gambar dari galeri.
                  _pickedImageBytes = null;
                  _pickedImageName = null;
                }),
                decoration: _fieldDecoration(
                  label: 'URL/UUID Gambar (opsional)',
                  hint: 'https://... atau UUID aset',
                  icon: Icons.image_outlined,
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: descriptionController,
                maxLines: 4,
                decoration: _fieldDecoration(
                  label: 'Deskripsi',
                  hint: 'Masukkan deskripsi produk',
                  icon: Icons.description_outlined,
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Deskripsi wajib diisi'
                    : null,
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 50,
                child: FilledButton(
                  onPressed: isLoading ? null : saveProduct,
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 25,
                          height: 25,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          isEditMode ? 'SIMPAN PERUBAHAN' : 'SIMPAN PRODUK',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Gaya kolom input yang sama dengan halaman Login.
  InputDecoration _fieldDecoration({
    required String label,
    required IconData icon,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.grey[100],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
    );
  }

  /// Gambar persegi bersudut membulat dengan tombol pensil bulat dan
  /// tombol teks "Ganti Gambar" di bawahnya.
  Widget _buildImagePicker(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        GestureDetector(
          onTap: isLoading ? null : _showImageOptions,
          child: SizedBox(
            width: _imageSize,
            height: _imageSize,
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: _buildImagePreview(),
                  ),
                ),
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.edit,
                      size: 20,
                      color: colorScheme.onPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: isLoading ? null : _showImageOptions,
          icon: const Icon(Icons.image_outlined),
          label: Text(_hasImage ? 'Ganti Gambar' : 'Pilih Gambar'),
        ),
      ],
    );
  }

  Widget _buildImagePreview() {
    final placeholder = Container(
      color: Colors.grey[200],
      alignment: Alignment.center,
      child: const Icon(
        Icons.image_not_supported_outlined,
        size: 56,
        color: Colors.grey,
      ),
    );

    if (_pickedImageBytes != null) {
      return Image.memory(_pickedImageBytes!, fit: BoxFit.cover);
    }

    final url = _currentImageUrl;
    if (url == null) return placeholder;

    return Image.network(
      url,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) => progress == null
          ? child
          : const Center(child: CircularProgressIndicator()),
      errorBuilder: (_, _, _) => placeholder,
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
