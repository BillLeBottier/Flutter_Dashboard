import 'dart:convert';
import 'package:http/http.dart' as http;

class BinanceService {
  final String baseUrl = 'https://api.binance.com/api/v3';

  /// Récupère les données de chandeliers avec intervalle configurable
  Future<List<List<dynamic>>> fetchKlines(String symbol, {String interval = '1d', int limit = 30}) async {
    try {
      final response = await http.get(Uri.parse(
          '$baseUrl/klines?symbol=$symbol&interval=$interval&limit=$limit'));
      if (response.statusCode == 200) {
        return List<List<dynamic>>.from(json.decode(response.body));
      } else {
        throw Exception("Erreur lors du chargement des données de chandeliers");
      }
    } catch (e) {
      print("Erreur BinanceService.fetchKlines : $e");
      throw Exception("Erreur lors du chargement des données de chandeliers");
    }
  }
}
