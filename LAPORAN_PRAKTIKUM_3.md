# LAPORAN PRAKTIKUM 3 PEMROGRAMAN MOBILE 2

## Integrasi REST API dengan Flutter Menggunakan Dio

| Keterangan | Isi |
| --- | --- |
| Nama | **[Isi nama mahasiswa]** |
| NIM | **[Isi NIM]** |
| Kelas | **[Isi kelas]** |
| Mata Kuliah | Pemrograman Mobile 2 |
| Praktikum | Praktikum 3 — REST API dengan Dio |
| Aplikasi | Inventory API App / Product Catalog |
| Tanggal | **[Isi tanggal pengumpulan]** |

---

## 1. Pendahuluan

Pada Praktikum 3, aplikasi Product Catalog dari Praktikum 2 dikembangkan menjadi aplikasi inventaris yang mengambil dan mengelola data produk melalui REST API. Sebelumnya data produk disimpan secara lokal, sedangkan pada praktikum ini seluruh data produk berasal dari server dan diakses dengan package **Dio**.

Alamat dasar API yang digunakan adalah:

```text
https://pos.cicd.web.id
```

Endpoint produk:

| Method | Endpoint | Kegunaan |
| --- | --- | --- |
| GET | `/items/products` | Mengambil daftar produk |
| POST | `/items/products` | Menambah produk baru |
| PATCH | `/items/products/{id}` | Memperbarui produk berdasarkan UUID |
| DELETE | `/items/products/{id}` | Menghapus produk berdasarkan UUID |

## 2. Tujuan Praktikum

1. Mengintegrasikan aplikasi Flutter dengan REST API menggunakan Dio.
2. Menerapkan model `Product` dengan proses `fromJson` dan `toJson`.
3. Menampilkan data JSON dari API ke antarmuka Flutter.
4. Menerapkan operasi CRUD produk (Create, Read, Update, Delete).
5. Menangani loading, error, pencarian, dan pull-to-refresh.

## 3. Teknologi dan Dependensi

| Teknologi | Fungsi |
| --- | --- |
| Flutter dan Dart | Pengembangan antarmuka serta logika aplikasi mobile |
| Dio `^5.11.1` | Komunikasi HTTP dengan REST API |
| Material 3 | Komponen antarmuka aplikasi |
| REST API `pos.cicd.web.id` | Sumber dan penyimpanan data produk |

Untuk Android, izin internet ditambahkan pada `AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET" />
```

## 4. Struktur Program

```text
lib/
├── main.dart
├── models/
│   └── product.dart
├── services/
│   └── api_service.dart
├── screens/
│   ├── login_page.dart
│   ├── home_page.dart
│   ├── product_list_page.dart
│   ├── add_product_page.dart
│   └── product_detail_page.dart
└── widgets/
    └── product_card.dart
```

Alur penggunaan aplikasi:

```text
Dummy Login → Home/Dashboard → Product List
                                      ├── Search
                                      ├── Add Product (POST)
                                      ├── Edit Product (PATCH)
                                      ├── Delete Product (DELETE)
                                      └── Pull-to-refresh (GET)
```

## 5. Fitur Aplikasi

| Fitur | Implementasi |
| --- | --- |
| Dummy Login | Login lokal tanpa autentikasi API. Username dan password harus diisi. |
| Dashboard | Halaman utama dengan navigasi ke daftar dan form produk. |
| Read Product | Daftar produk diambil dengan GET dari REST API. |
| Create Product | Form produk mengirim POST ke server. |
| Update Product | Data lama diisikan ke form lalu dikirim dengan PATCH memakai UUID produk. |
| Delete Product | Penghapusan memakai dialog konfirmasi sebelum DELETE dijalankan. |
| Search | Pencarian nama produk pada data yang sudah diterima dari API. |
| Pull-to-refresh | Tarik daftar ke bawah untuk mengambil data terbaru dari API. |
| Loading state | `CircularProgressIndicator` ditampilkan ketika daftar atau form sedang diproses. |
| Error handling | `DioException` diterjemahkan menjadi pesan yang mudah dipahami pengguna. |
| Gambar produk | Menampilkan URL/UUID aset bila tersedia dan placeholder ketika gambar kosong/gagal dimuat. |

## 6. Perancangan Model Data

Response API dapat berbentuk seperti berikut:

```json
{
  "id": "d924e9e8-1752-4800-aa7a-afc1b75012c0",
  "name": "pc cortis",
  "price": "100000000",
  "image_url": null,
  "category": "Elektronik",
  "description": "martin my suami",
  "quantity": 1
}
```

Model `Product` menggunakan `String` untuk UUID, `double` untuk harga, `int` untuk jumlah, dan menangani nilai `null` dari server agar aplikasi tidak berhenti saat parsing JSON.

```dart
class Product {
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
}
```

Method `fromJson()` pada program memproses `price` yang bisa dikirim sebagai angka ataupun string, serta memberikan nilai fallback untuk field yang kosong.

## 7. Implementasi API Service dengan Dio

Seluruh komunikasi API dipusatkan pada `ApiService`. Pendekatan ini menghindari duplikasi request HTTP di halaman antarmuka.

```dart
class ApiService {
  ApiService({Dio? dio})
      : _dio = dio ?? Dio(
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
    final response = await _dio.get<dynamic>(_productsPath);
    final data = _unwrapData(response.data);
    if (data is! List) {
      throw const FormatException('Daftar produk dari server tidak valid.');
    }
    return data
        .whereType<Map>()
        .map((item) => Product.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<Product> createProduct(Product product) async {
    final response = await _dio.post<dynamic>(
      _productsPath,
      data: product.toJson(),
    );
    return _productFromResponse(response.data, fallback: product);
  }
}
```

Operasi PATCH dan DELETE menggunakan UUID asli dari objek produk:

```dart
await _dio.patch<dynamic>(
  '$_productsPath/${product.id}',
  data: product.toJson(),
);

await _dio.delete<dynamic>('$_productsPath/$id');
```

Status sukses HTTP 200 dan 201 diterima oleh Dio sebagai request berhasil. Status error 400, 401, 403, 404, dan 500 ditangani dengan pesan khusus di antarmuka. Timeout, koneksi internet, pembatalan request, serta respons tidak valid juga ditangani melalui `DioException`.

## 8. Implementasi Tampilan dan Interaksi

### 8.1 Halaman Login

Halaman awal merupakan Dummy Login. Login ini hanya memvalidasi bahwa username dan password terisi, kemudian pengguna diarahkan ke halaman Home. Tidak ada kredensial yang dikirim ke API.

> **Screenshot 1 — Login Page**
>
> Jalankan aplikasi, isi username dan password apa saja, lalu ambil screenshot halaman ini dan sisipkan di sini.

### 8.2 Halaman Home / Dashboard

Halaman Home mempertahankan tampilan Product Catalog sebelumnya. Pengguna dapat memilih menu **Product List** untuk melihat data server atau **Add Product** untuk membuka form tambah produk.

> **Screenshot 2 — Home/Dashboard Page**
>
> Sisipkan screenshot setelah berhasil login.

### 8.3 Halaman Daftar Produk

Saat halaman dibuka, fungsi `_loadProducts()` memanggil `getProducts()`. Data ditampilkan menggunakan `ListView.builder` dan widget `ProductCard`. Setiap kartu memperlihatkan gambar, nama, kategori, stok, harga, serta tombol detail, edit, dan hapus.

```dart
Future<void> _loadProducts({bool showLoading = true}) async {
  if (showLoading && mounted) {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
  }

  try {
    final loadedProducts = await _apiService.getProducts();
    if (!mounted) return;
    setState(() {
      _allProducts = loadedProducts;
      _applySearch();
      _isLoading = false;
      _errorMessage = null;
    });
  } catch (error) {
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _errorMessage = ApiService.errorMessage(error);
    });
  }
}
```

> **Screenshot 3 — Product List, Search, dan Pull-to-refresh**
>
> Sisipkan screenshot daftar produk serta screenshot saat kolom pencarian digunakan.

### 8.4 Form Tambah dan Edit Produk

Form menyediakan input nama, harga, jumlah/stok, kategori, URL/UUID gambar opsional, dan deskripsi. Ketika tombol simpan dipilih, validasi form dijalankan. Tombol berubah menjadi loading indicator agar request tidak terkirim berulang kali.

```dart
if (isEditMode) {
  await _apiService.updateProduct(productData);
} else {
  await _apiService.createProduct(productData);
}
```

> **Screenshot 4 — Add Product Page**
>
> Sisipkan screenshot form tambah produk yang terisi.
>
> **Screenshot 5 — Edit Product Page**
>
> Sisipkan screenshot form edit dengan data produk lama yang telah terisi otomatis.

### 8.5 Hapus Produk

Tombol hapus menampilkan `AlertDialog` terlebih dahulu. Jika pengguna memilih **Hapus**, aplikasi mengirim request DELETE memakai UUID produk, memuat ulang daftar dari API, dan menampilkan `SnackBar` berhasil.

```dart
await _apiService.deleteProduct(product.id);
await _loadProducts(showLoading: false);
```

> **Screenshot 6 — Dialog Konfirmasi Delete**
>
> Sisipkan screenshot dialog konfirmasi sebelum produk dihapus.

## 9. Skenario Pengujian

| No. | Fitur yang diuji | Langkah pengujian | Hasil yang diharapkan | Status implementasi |
| --- | --- | --- | --- | --- |
| 1 | Login | Isi username dan password, lalu tekan Masuk | Pengguna masuk ke halaman Home | Berhasil diimplementasikan |
| 2 | GET Product | Buka Product List | Loading tampil lalu daftar produk dari API muncul | Berhasil diimplementasikan; endpoint GET telah diverifikasi merespons data |
| 3 | Search | Ketik sebagian nama produk | Daftar hanya menampilkan nama yang sesuai | Berhasil diimplementasikan |
| 4 | Pull-to-refresh | Tarik daftar produk ke bawah | Aplikasi mengambil data terbaru dari server | Berhasil diimplementasikan |
| 5 | POST Product | Isi form tambah kemudian simpan | Produk dikirim ke API dan pesan berhasil tampil jika respons sukses | Berhasil diimplementasikan |
| 6 | PATCH Product | Tekan edit, ubah data, lalu simpan | Produk dengan UUID terkait diperbarui | Berhasil diimplementasikan |
| 7 | DELETE Product | Tekan hapus dan setujui dialog | Produk dihapus dari server, daftar dimuat ulang | Berhasil diimplementasikan |
| 8 | Error handling | Matikan internet atau gunakan respons error server | Pesan error yang mudah dipahami ditampilkan | Berhasil diimplementasikan |
| 9 | Gambar null | Buka produk yang tidak memiliki `image_url` | Placeholder gambar tampil tanpa error | Berhasil diimplementasikan |

> Catatan: POST, PATCH, dan DELETE sengaja tidak dieksekusi selama pembuatan laporan karena API digunakan bersama; ketiga operasi telah diimplementasikan dan dapat diuji dengan data produk milik mahasiswa.

## 10. Cara Menjalankan Program

1. Pastikan Flutter SDK dan emulator/perangkat Android sudah tersedia.
2. Buka folder proyek `product_catalog` pada terminal.
3. Jalankan perintah berikut:

   ```bash
   flutter pub get
   flutter run
   ```

4. Masukkan username dan password apa saja pada Dummy Login.
5. Buka menu **Product List** untuk mengambil data dari API.

## 11. Kesimpulan

Aplikasi Inventory API App berhasil dikembangkan dari Product Catalog Praktikum 2 menjadi aplikasi Flutter yang terhubung ke REST API menggunakan Dio. Aplikasi telah memiliki model produk dengan JSON parsing, operasi CRUD memakai UUID dari server, loading state, error handling, search produk, pull-to-refresh, gambar dengan placeholder, dan Dummy Login. Data produk tidak lagi menggunakan data dummy atau penyimpanan lokal, melainkan dikelola melalui endpoint `https://pos.cicd.web.id/items/products`.

## Lampiran: Lokasi Kode Program

Kode lengkap disertakan pada folder proyek. File inti yang dapat diperiksa adalah:

| File | Isi |
| --- | --- |
| `lib/models/product.dart` | Model `Product`, `fromJson`, `toJson`, dan parsing aman |
| `lib/services/api_service.dart` | Konfigurasi Dio, CRUD API, dan error handling |
| `lib/screens/login_page.dart` | Dummy Login |
| `lib/screens/product_list_page.dart` | GET, search, refresh, delete, loading, dan error UI |
| `lib/screens/add_product_page.dart` | Form POST dan PATCH |
| `lib/widgets/product_card.dart` | Kartu tampilan produk dan placeholder gambar |
| `android/app/src/main/AndroidManifest.xml` | Izin akses internet Android |
