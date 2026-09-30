/// Representasi produk yang dikirim dan diterima dari REST API.
class Product {
  static const _assetBaseUrl = 'https://pos.cicd.web.id/assets/';

  final String id;
  final String name;
  final double price;
  final String? imageUrl;
  final String category;
  final String description;
  final int quantity;

  const Product({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.category,
    required this.description,
    required this.quantity,
  });

  /// URL yang siap digunakan oleh [Image.network]. API dapat mengirim URL
  /// penuh atau UUID dari aset Directus.
  String? get displayImageUrl {
    final value = imageUrl?.trim();
    if (value == null || value.isEmpty) return null;
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }
    return '$_assetBaseUrl$value';
  }

  /// Payload untuk POST dan PATCH. ID tidak dikirim karena dibuat oleh API.
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'price': price % 1 == 0 ? price.toStringAsFixed(0) : price.toString(),
      'image_url': imageUrl?.trim().isEmpty ?? true ? null : imageUrl?.trim(),
      'category': category,
      'description': description,
      'quantity': quantity,
    };
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: _stringValue(json['id']),
      name: _stringValue(json['name'], fallback: 'Produk tanpa nama'),
      price: _doubleValue(json['price']),
      imageUrl: _nullableStringValue(json['image_url']),
      category: _stringValue(json['category'], fallback: 'Tanpa kategori'),
      description: _stringValue(
        json['description'],
        fallback: 'Tidak ada deskripsi',
      ),
      // Sebagian data lama API menyimpan stok pada field `stock`.
      quantity: _intValue(json['quantity'] ?? json['stock']),
    );
  }

  static String _stringValue(dynamic value, {String fallback = ''}) {
    final result = value?.toString().trim() ?? '';
    return result.isEmpty ? fallback : result;
  }

  static String? _nullableStringValue(dynamic value) {
    final result = value?.toString().trim();
    return result == null || result.isEmpty ? null : result;
  }

  static double _doubleValue(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(
          value?.toString().replaceAll(',', '').trim() ?? '',
        ) ??
        0;
  }

  static int _intValue(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString().trim() ?? '') ?? 0;
  }
}
