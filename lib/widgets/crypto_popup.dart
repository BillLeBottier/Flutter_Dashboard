import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/binance_service.dart';
import '../models/crypto_model.dart';

class CryptoPopup extends StatefulWidget {
  final CryptoModel crypto;

  const CryptoPopup({super.key, required this.crypto});

  @override
  _CryptoPopupState createState() => _CryptoPopupState();
}

class _CryptoPopupState extends State<CryptoPopup> {
  final BinanceService _binanceService = BinanceService();
  List<FlSpot> dataPoints = [];
  double? lastPointPrice; // Dernier point du graphe
  FlSpot? minSpot;
  FlSpot? maxSpot;
  String selectedPeriod = '1d'; // Période par défaut
  bool isLoading = true;
  bool hasError = false;
  double? hoveredPriceChange; // Variation sur le point touché

  final Map<String, String> periodOptions = {
    '1h': '24h',
    '1d': '30 jours',
    '7d': '7 jours',
    '1w': '1 an',
  };

  @override
  void initState() {
    super.initState();
    _loadBinanceChartData();
  }

  Future<void> _loadBinanceChartData() async {
    setState(() {
      isLoading = true;
      hasError = false;
      hoveredPriceChange = null; // Réinitialiser la variation affichée
    });

    try {
      String interval = '1d';
      int limit = 30;

      switch (selectedPeriod) {
        case '1h':
          interval = '1h';
          limit = 24;
          break;
        case '7d':
          interval = '1d';
          limit = 7;
          break;
        case '1w':
          interval = '1w';
          limit = 52;
          break;
      }

      final klines = await _binanceService.fetchKlines(
        "${widget.crypto.symbol.toUpperCase()}USDT",
        interval: interval,
        limit: limit,
      );

      setState(() {
        dataPoints = klines
            .asMap()
            .entries
            .map((entry) => FlSpot(entry.key.toDouble(), double.parse(entry.value[4]))) // Prix de clôture
            .toList();

        if (dataPoints.isNotEmpty) {
          lastPointPrice = dataPoints.last.y;

          // Calcul des points min et max
          minSpot = dataPoints.reduce((a, b) => a.y < b.y ? a : b);
          maxSpot = dataPoints.reduce((a, b) => a.y > b.y ? a : b);
        }

        isLoading = false;
      });
    } catch (e) {
      print("Erreur lors du chargement des données Binance : $e");
      setState(() {
        hasError = true;
        isLoading = false;
      });
    }
  }

  void _onPeriodChange(String? newPeriod) {
    if (newPeriod != null) {
      setState(() {
        selectedPeriod = newPeriod;
      });
      _loadBinanceChartData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.grey[900],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Titre de la crypto
              Text(
                widget.crypto.name,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 10),

              // Prix actuel
              Text(
                "\$${widget.crypto.price.toStringAsFixed(2)}",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              // Variation (mise à jour sur le graphe)
              SizedBox(height: 10),
              hoveredPriceChange != null && lastPointPrice != null
                  ? Text(
                "${hoveredPriceChange! >= 0 ? '+' : ''}${hoveredPriceChange!.toStringAsFixed(2)}% (${(hoveredPriceChange! * lastPointPrice! / 100).toStringAsFixed(2)}\$)",
                style: TextStyle(
                  fontSize: 16,
                  color: hoveredPriceChange! >= 0 ? Colors.green : Colors.red,
                ),
              )
                  : SizedBox.shrink(),

              SizedBox(height: 20),

              // Sélecteur de période
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Période :",
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  DropdownButton<String>(
                    value: selectedPeriod,
                    dropdownColor: Colors.grey[900],
                    items: periodOptions.entries
                        .map((entry) => DropdownMenuItem(
                      value: entry.key,
                      child: Text(
                        entry.value,
                        style: TextStyle(color: Colors.white),
                      ),
                    ))
                        .toList(),
                    onChanged: _onPeriodChange,
                  ),
                ],
              ),

              SizedBox(height: 20),

              // Graphique ou messages d'erreur
              isLoading
                  ? Center(child: CircularProgressIndicator())
                  : hasError
                  ? Center(
                child: Text(
                  "Impossible de charger les données du graphique.",
                  style: TextStyle(color: Colors.redAccent),
                ),
              )
                  : dataPoints.isNotEmpty
                  ? _buildChart()
                  : Center(
                child: Text(
                  "Aucune donnée disponible pour la période sélectionnée.",
                  style: TextStyle(color: Colors.white70),
                ),
              ),

              SizedBox(height: 20),

              // Bouton de fermeture
              Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text("Fermer"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChart() {
    return SizedBox(
      height: 300,
      child: LineChart(
        LineChartData(
          lineBarsData: [
            LineChartBarData(
              spots: dataPoints,
              isCurved: true,
              barWidth: 2.5,
              color: Colors.blueAccent,
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    Colors.blueAccent.withOpacity(0.2),
                    Colors.transparent,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, _) => Text(
                  value.toStringAsFixed(0),
                  style: TextStyle(color: Colors.white70, fontSize: 10),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineTouchData: LineTouchData(
            touchCallback: (FlTouchEvent event, LineTouchResponse? touchResponse) {
              if (event.isInterestedForInteractions &&
                  touchResponse != null &&
                  touchResponse.lineBarSpots != null &&
                  touchResponse.lineBarSpots!.isNotEmpty) {
                final touchedSpot = touchResponse.lineBarSpots!.first;
                final double touchedPrice = touchedSpot.y;

                setState(() {
                  hoveredPriceChange = ((touchedPrice - lastPointPrice!) / lastPointPrice!) * 100;
                });
              }
            },
            handleBuiltInTouches: true,
          ),
          extraLinesData: ExtraLinesData(horizontalLines: []),
        ),
      ),
    );
  }
}
