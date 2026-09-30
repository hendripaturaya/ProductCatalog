import 'package:flutter/material.dart';
import 'product_list_page.dart';
import 'add_product_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Product Catalog')),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 30),

            // ICON
            const Icon(Icons.shopping_bag, size: 90, color: Colors.blue),

            const SizedBox(height: 20),

            // JUDUL
            const Text(
              'Product Catalog',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            const Text(
              'Temukan berbagai produk yang tersedia.',
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 40),

            // PRODUCT LIST
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProductListPage(),
                  ),
                );
              },
              icon: const Icon(Icons.list),
              label: const Text('Product List'),
            ),

            const SizedBox(height: 15),

            // ADD PRODUCT
            OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddProductPage(),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Product'),
            ),
          ],
        ),
      ),
    );
  }
}
