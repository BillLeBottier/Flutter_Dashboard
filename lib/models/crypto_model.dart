class CryptoModel {
  final String name;
  final String symbol; // Nouvelle propriété pour le symbole
  final double price;
  final String imageUrl;
  final double marketCap;
  final double volume;
  final double dailyChange;



  CryptoModel({
    required this.name,
    required this.symbol,
    required this.price,
    required this.imageUrl,
    required this.marketCap,
    required this.volume,
    required this.dailyChange,

  });



  factory CryptoModel.fromJson(Map<String, dynamic> json) {
    return CryptoModel(
      name: json['name'],
      symbol: json['symbol'], // Assurez-vous que le symbole est bien extrait du JSON
      price: json['current_price'].toDouble(),
      imageUrl: json['image'],
      marketCap: json['market_cap']?.toDouble() ?? 0.0,
      volume: json['total_volume']?.toDouble() ?? 0.0,
      dailyChange: json['price_change_percentage_24h']?.toDouble() ?? 0.0,
    );
  }
}

