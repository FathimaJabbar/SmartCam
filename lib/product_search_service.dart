import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_keys.dart';

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
 final String _apiKey = ApiKeys.serpApi;

  Future<List<ProductResult>> searchProducts(String query) async {
    final uri = Uri.parse(
        'https://serpapi.com/search.json?engine=google_shopping&q=${Uri.encodeComponent(query)}&gl=in&api_key=$_apiKey');

    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List results = data['shopping_results'] ?? [];
       
        return results.map((item) {
          final String? productId = item['product_id'];
          String? fullLink;
         
          if (productId != null && productId.isNotEmpty) {
            fullLink = 'https://www.google.com/shopping/product/$productId';
          }

          return ProductResult(
            title: item['title'] ?? 'No Title',
            price: item['price'],
            link: fullLink, 
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