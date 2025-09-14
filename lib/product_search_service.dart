import 'dart:convert';
import 'package:http/http.dart' as http;

class ProductResult {
  final String title;
  final String? price;
  final String? link;
  final String? thumbnail;

  ProductResult({
    required this.title,
    this.price,
    this.link,
    this.thumbnail,
  });
}

class ProductSearchService {
  final String _apiKey = '873f2e911f15214aa5083a2d271f71a92f35e717fd68d1e929a3999927d1fb8b';

  Future<List<ProductResult>> searchProducts(String query) async {
    final uri = Uri.parse(
        'https://serpapi.com/search.json?engine=google_shopping&q=${Uri.encodeComponent(query)}&gl=in&api_key=$_apiKey');

    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List results = data['shopping_results'] ?? [];
       
        return results.map((item) {
          // --- THIS IS THE FINAL FIX ---
          // We look for 'product_id' instead of 'link'.
          final String? productId = item['product_id'];
          String? fullLink;
         
          // If a product_id exists, we build the URL ourselves.
          if (productId != null && productId.isNotEmpty) {
            fullLink = 'https://www.google.com/shopping/product/$productId';
          }

          return ProductResult(
            title: item['title'] ?? 'No Title',
            price: item['price'],
            link: fullLink, // Use the newly constructed link (will be null if no id)
            thumbnail: item['thumbnail'],
          );
        }).toList();
      }
    } catch (e) {
      print('SerpApi Error: $e');
    }
    return [];
  }
}