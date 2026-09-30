import 'package:dio/dio.dart';

import '../models/product.dart';

/// Satu pintu komunikasi REST API untuk data produk.
class ApiService {
  ApiService({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: 'https://pos.cicd.web.id',
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 20),
              headers: const {'Accept': 'application/json'},
            ),
          );

  final Dio _dio;
  static const _productsPath = '/items/products';

  Future<List<Product>> getProducts() async {
    try {
      final response = await _dio.get<dynamic>(_productsPath);
      final data = _unwrapData(response.data);

      if (data is! List) {
        throw const FormatException('Daftar produk dari server tidak valid.');
      }

      return data
          .whereType<Map>()
          .map((item) => Product.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } on DioException {
      rethrow;
    }
  }

  Future<Product> createProduct(Product product) async {
    try {
      final response = await _dio.post<dynamic>(
        _productsPath,
        data: product.toJson(),
      );
      return _productFromResponse(response.data, fallback: product);
    } on DioException {
      rethrow;
    }
  }

  Future<Product> updateProduct(Product product) async {
    if (product.id.isEmpty) {
      throw const FormatException('ID produk tidak tersedia untuk diperbarui.');
    }

    try {
      final response = await _dio.patch<dynamic>(
        '$_productsPath/${product.id}',
        data: product.toJson(),
      );
      return _productFromResponse(response.data, fallback: product);
    } on DioException {
      rethrow;
    }
  }

  Future<void> deleteProduct(String id) async {
    if (id.isEmpty) {
      throw const FormatException('ID produk tidak tersedia untuk dihapus.');
    }

    try {
      await _dio.delete<dynamic>('$_productsPath/$id');
    } on DioException {
      rethrow;
    }
  }

  Product _productFromResponse(
    dynamic responseData, {
    required Product fallback,
  }) {
    final data = _unwrapData(responseData);
    if (data is Map) {
      return Product.fromJson(Map<String, dynamic>.from(data));
    }
    // Sebagian API hanya mengirim status sukses; daftar akan dimuat ulang
    // setelah operasi selesai, jadi data form tetap menjadi fallback aman.
    return fallback;
  }

  dynamic _unwrapData(dynamic body) {
    if (body is Map && body.containsKey('data')) return body['data'];
    return body;
  }

  /// Pesan error yang dapat langsung ditampilkan di UI.
  static String errorMessage(Object error) {
    if (error is! DioException) {
      return error is FormatException
          ? error.message.toString()
          : 'Terjadi kesalahan yang tidak terduga. Silakan coba lagi.';
    }

    switch (error.response?.statusCode) {
      case 400:
        return 'Data produk tidak valid. Periksa kembali isian Anda.';
      case 401:
        return 'Akses ditolak. Silakan masuk kembali.';
      case 403:
        return 'Anda tidak memiliki izin untuk melakukan tindakan ini.';
      case 404:
        return 'Produk atau endpoint tidak ditemukan.';
      case 500:
        return 'Server sedang bermasalah. Silakan coba beberapa saat lagi.';
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.transformTimeout:
        return 'Koneksi ke server terlalu lama. Periksa internet Anda.';
      case DioExceptionType.connectionError:
        return 'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.';
      case DioExceptionType.cancel:
        return 'Permintaan dibatalkan.';
      case DioExceptionType.badCertificate:
        return 'Sertifikat koneksi server tidak valid.';
      case DioExceptionType.badResponse:
      case DioExceptionType.unknown:
        return 'Permintaan gagal. Silakan coba lagi.';
    }
  }
}
