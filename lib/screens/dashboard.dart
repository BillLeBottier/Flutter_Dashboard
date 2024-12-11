import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/crypto_model.dart';
import '../widgets/crypto_search_bar.dart';
import '../widgets/crypto_popup.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  List<CryptoModel> _cryptoList = [];
  List<CryptoModel> _filteredCryptoList = [];
  List<CryptoModel> _favorites = [];
  CryptoModel? _highestIncrease;
  CryptoModel? _highestDecrease;
  CryptoModel? _cryptoToCompare1;
  CryptoModel? _cryptoToCompare2;
  Timer? _timer;

  String _selectedSortOption = 'market_cap';

  @override
  void initState() {
    super.initState();
    _loadCryptoData();
    _loadTopMovers();

    _timer = Timer.periodic(Duration(seconds: 30), (timer) {
      _loadCryptoData();
      _loadTopMovers();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadCryptoData() async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    _cryptoList = await apiService.fetchCryptoPrices();
    _applySort();
    setState(() {
      _filteredCryptoList = _cryptoList;
    });
  }

  Future<void> _loadTopMovers() async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    final topMovers = await apiService.fetchTopMovers();
    setState(() {
      _highestIncrease = topMovers["highestIncrease"];
      _highestDecrease = topMovers["highestDecrease"];
    });
  }

  void _applySort() {
    if (_selectedSortOption == 'market_cap') {
      _cryptoList.sort((a, b) => b.marketCap.compareTo(a.marketCap));
    } else if (_selectedSortOption == 'volume') {
      _cryptoList.sort((a, b) => b.volume.compareTo(a.volume));
    } else if (_selectedSortOption == 'daily_change') {
      _cryptoList.sort((a, b) => b.dailyChange.compareTo(a.dailyChange));
    }
    setState(() {
      _filteredCryptoList = _cryptoList;
    });
  }

  void _toggleFavorite(CryptoModel crypto) {
    setState(() {
      if (_favorites.contains(crypto)) {
        _favorites.remove(crypto);
      } else {
        _favorites.add(crypto);
      }
    });
  }

  void _showAlertDialog(CryptoModel crypto) {
    final TextEditingController _priceController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: Text(
            'Définir une alerte',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Prix actuel : \$${crypto.price.toStringAsFixed(2)}",
                style: TextStyle(color: Colors.white70),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _priceController,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Prix seuil",
                  hintStyle: TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: Colors.grey[800],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                final priceThreshold = double.tryParse(_priceController.text);
                if (priceThreshold != null) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Alerte définie pour ${crypto.name} à \$${priceThreshold.toStringAsFixed(2)}')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Veuillez entrer un prix valide.')),
                  );
                }
              },
              child: Text('Valider'),
            ),
          ],
        );
      },
    );
  }

  void _compareCryptos() {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: Text(
            'Comparer deux cryptos',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildCryptoDropdown(
                hint: 'Sélectionner la 1ère crypto',
                value: _cryptoToCompare1,
                onChanged: (value) {
                  setState(() {
                    _cryptoToCompare1 = value;
                  });
                },
              ),
              SizedBox(height: 16),
              _buildCryptoDropdown(
                hint: 'Sélectionner la 2ème crypto',
                value: _cryptoToCompare2,
                exclude: _cryptoToCompare1,
                onChanged: (value) {
                  setState(() {
                    _cryptoToCompare2 = value;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_cryptoToCompare1 != null && _cryptoToCompare2 != null) {
                  Navigator.of(context).pop();
                  _showComparisonPopup();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Veuillez sélectionner deux cryptos.'),
                    ),
                  );
                }
              },
              child: Text('Comparer'),
            ),
          ],
        );
      },
    );
  }

  void _showComparisonPopup() {
    showDialog(
      context: context,
      builder: (_) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: CryptoPopup(crypto: _cryptoToCompare1!),
              ),
              SizedBox(width: 16),
              Expanded(
                child: CryptoPopup(crypto: _cryptoToCompare2!),
              ),
            ],
          ),
        );
      },
    );
  }


  Widget _buildCryptoDropdown({
    required String hint,
    required CryptoModel? value,
    CryptoModel? exclude,
    required ValueChanged<CryptoModel?> onChanged,
  }) {
    return DropdownButton<CryptoModel>(
      hint: Text(hint, style: TextStyle(color: Colors.white70)),
      value: value,
      dropdownColor: Colors.grey[900],
      items: _cryptoList
          .where((crypto) => crypto != exclude)
          .map((crypto) {
        return DropdownMenuItem(
          value: crypto,
          child: Text(
            crypto.name,
            style: TextStyle(color: Colors.white),
          ),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Crypto Dashboard'),
        actions: [
          IconButton(
            icon: Icon(Icons.compare_arrows),
            onPressed: _compareCryptos,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CryptoSearchBar(onSearch: _filterCrypto),
            if (_highestIncrease != null && _highestDecrease != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildTopMoverCard(
                      title: "Highest Increase",
                      crypto: _highestIncrease!,
                      color: Colors.greenAccent,
                      icon: Icons.arrow_upward,
                    ),
                    _buildTopMoverCard(
                      title: "Highest Decrease",
                      crypto: _highestDecrease!,
                      color: Colors.redAccent,
                      icon: Icons.arrow_downward,
                    ),
                  ],
                ),
              ),
            _buildSortAndFilterOptions(),
            ListView.builder(
              physics: NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: _filteredCryptoList.length,
              itemBuilder: (context, index) {
                final crypto = _filteredCryptoList[index];
                return ListTile(
                  leading: Image.network(crypto.imageUrl, width: 40, height: 40),
                  title: Text(
                    crypto.name,
                    style: TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    "Prix : \$${crypto.price.toStringAsFixed(2)}",
                    style: TextStyle(color: Colors.white70),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          _favorites.contains(crypto) ? Icons.favorite : Icons.favorite_border,
                          color: _favorites.contains(crypto) ? Colors.red : Colors.white,
                        ),
                        onPressed: () => _toggleFavorite(crypto),
                      ),
                      IconButton(
                        icon: Icon(Icons.notifications, color: Colors.white),
                        onPressed: () => _showAlertDialog(crypto),
                      ),
                    ],
                  ),
                  onTap: () => _showCryptoPopup(context, crypto),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _filterCrypto(String query) {
    setState(() {
      _filteredCryptoList = _cryptoList
          .where((crypto) => crypto.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  Widget _buildSortAndFilterOptions() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          DropdownButton<String>(
            value: _selectedSortOption,
            dropdownColor: Colors.grey[900],
            items: [
              DropdownMenuItem(value: 'market_cap', child: Text('Tri par capitalisation', style: TextStyle(color: Colors.white))),
              DropdownMenuItem(value: 'volume', child: Text('Tri par volume', style: TextStyle(color: Colors.white))),
              DropdownMenuItem(value: 'daily_change', child: Text('Tri par variation', style: TextStyle(color: Colors.white))),
            ],
            onChanged: (value) {
              setState(() {
                _selectedSortOption = value!;
                _applySort();
              });
            },
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _filteredCryptoList = _favorites.isNotEmpty ? _favorites : _cryptoList;
              });
            },
            child: Text(
              'Voir favoris',
              style: TextStyle(color: Colors.blueAccent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopMoverCard({
    required String title,
    required CryptoModel crypto,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.4,
      padding: EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          Divider(color: Colors.white24),
          Row(
            children: [
              Image.network(crypto.imageUrl, width: 32, height: 32),
              SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      crypto.name,
                      style: TextStyle(fontSize: 14, color: Colors.white),
                    ),
                    Text(
                      "${crypto.dailyChange.toStringAsFixed(2)}%",
                      style: TextStyle(
                        fontSize: 12,
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showCryptoPopup(BuildContext context, CryptoModel crypto) {
    showDialog(
      context: context,
      builder: (_) => CryptoPopup(crypto: crypto),
    );
  }
}