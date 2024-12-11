import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/crypto_model.dart';
import '../models/event_model.dart';

class ApiService {
  final String baseUrl = "https://api.coingecko.com/api/v3";

  /// Récupère les prix actuels et autres données des cryptomonnaies
  Future<List<CryptoModel>> fetchCryptoPrices() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/coins/markets?vs_currency=usd&sparkline=true"));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print("fetchCryptoPrices: Data loaded successfully.");
        return data.map((json) => CryptoModel.fromJson(json)).toList();
      } else {
        print("fetchCryptoPrices: Failed to load data - Status code ${response.statusCode}");
        throw Exception("Erreur de chargement des données");
      }
    } catch (e) {
      print("fetchCryptoPrices: Exception - $e");
      throw Exception("Erreur de chargement des données");
    }
  }

  Future<List<EventModel>> fetchCryptoEvents() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/events"));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body)['data'];
        return data.map((json) => EventModel.fromJson(json)).toList();
      } else {
        throw Exception("Erreur de chargement des événements");
      }
    } catch (e) {
      print("fetchCryptoEvents: Exception - $e");
      throw Exception("Erreur de chargement des événements");
    }
  }



  /// Récupère les données historiques pour une cryptomonnaie donnée sur une période spécifique
  Future<List<double>> fetchHistoricalData(String id, String days) async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/coins/$id/market_chart?vs_currency=usd&days=$days"));

      if (response.statusCode == 200) {
        final List<dynamic> prices = json.decode(response.body)['prices'];
        print("fetchHistoricalData: Historical data for $id over $days days loaded successfully.");
        return prices.map((entry) => (entry[1] as num).toDouble()).toList();
      } else {
        print("fetchHistoricalData: Failed to load historical data - Status code ${response.statusCode}");
        throw Exception("Erreur de chargement des données historiques");
      }
    } catch (e) {
      print("fetchHistoricalData: Exception - $e");
      throw Exception("Erreur de chargement des données historiques");
    }
  }

  /// Récupère les données de cryptomonnaies sélectionnées par identifiants
  Future<List<CryptoModel>> fetchSelectedCryptos(List<String> ids) async {
    try {
      final idsParam = ids.join(',');
      final response = await http.get(Uri.parse("$baseUrl/coins/markets?vs_currency=usd&ids=$idsParam"));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print("fetchSelectedCryptos: Selected cryptos loaded successfully.");
        return data.map((json) => CryptoModel.fromJson(json)).toList();
      } else {
        print("fetchSelectedCryptos: Failed to load selected cryptos - Status code ${response.statusCode}");
        throw Exception("Erreur de chargement des données de comparaison");
      }
    } catch (e) {
      print("fetchSelectedCryptos: Exception - $e");
      throw Exception("Erreur de chargement des données de comparaison");
    }
  }

  Future<List<double>> fetchCryptoHistory(String symbol, {String days = '7'}) async {
    final url = "$baseUrl/coins/$symbol/market_chart?vs_currency=usd&days=$days";

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final prices = data['prices'] as List<dynamic>;
        return prices.map((price) => (price[1] as num).toDouble()).toList();
      } else {
        throw Exception('Failed to load historical data');
      }
    } catch (e) {
      print("Erreur lors du chargement des données historiques : $e");
      throw Exception("Erreur lors du chargement des données historiques");
    }
  }

  /// Récupère les cryptomonnaies avec la plus forte augmentation et la plus forte baisse
  Future<Map<String, CryptoModel>> fetchTopMovers() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/coins/markets?vs_currency=usd&order=market_cap_desc&per_page=100&page=1"));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        List<CryptoModel> cryptos = data.map((json) => CryptoModel.fromJson(json)).toList();

        // Sélectionne les cryptos avec la plus forte augmentation et la plus forte baisse
        final highestIncrease = cryptos.reduce((a, b) => a.dailyChange > b.dailyChange ? a : b);
        final highestDecrease = cryptos.reduce((a, b) => a.dailyChange < b.dailyChange ? a : b);

        // Debugging outputs
        print("fetchTopMovers: Highest Increase - ${highestIncrease.name} (${highestIncrease.dailyChange}%)");
        print("fetchTopMovers: Highest Decrease - ${highestDecrease.name} (${highestDecrease.dailyChange}%)");

        return {
          "highestIncrease": highestIncrease,
          "highestDecrease": highestDecrease,
        };
      } else {
        print("fetchTopMovers: Failed to load top movers - Status code ${response.statusCode}");
        throw Exception("Erreur de chargement des données des top movers");
      }
    } catch (e) {
      print("fetchTopMovers: Exception - $e");
      throw Exception("Erreur de chargement des données des top movers");
    }
  }
}