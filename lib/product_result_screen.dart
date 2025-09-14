import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'product_search_service.dart';

class ProductResultScreen extends StatefulWidget {
  final String productName;
  const ProductResultScreen({super.key, required this.productName});

  @override
  _ProductResultScreenState createState() => _ProductResultScreenState();
}

class _ProductResultScreenState extends State<ProductResultScreen> {
  late Future<List<ProductResult>> _searchResults;

  @override
  void initState() {
    super.initState();
    _searchResults = ProductSearchService().searchProducts(widget.productName);
  }

  Future<void> _launchURL(String url) async {
    final Uri? uri = Uri.tryParse(url);
    if (uri != null) {
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error launching link: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Results for "${widget.productName}"')),
      body: FutureBuilder<List<ProductResult>>(
        future: _searchResults,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No products found or an error occurred.'));
          }

          final products = snapshot.data!;
          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              // The check is now for null instead of empty
              final bool hasLink = product.link != null;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  leading: product.thumbnail != null
                      ? Image.network(product.thumbnail!,
                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.shopping_bag))
                      : const Icon(Icons.shopping_bag),
                  title: Text(product.title),
                  subtitle: Text(product.price ?? 'Price not available'),
                 
                  onTap: hasLink ? () {
                    _launchURL(product.link!); // Use the non-null link
                  } : null,
                 
                  trailing: hasLink ? const Icon(Icons.open_in_new) : null,
                ),
              );
            },
          );
        },
      ),
    );
  }
}