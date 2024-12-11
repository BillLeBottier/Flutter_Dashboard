import 'package:flutter/material.dart';

class CryptoSearchBar extends StatelessWidget {
  final Function(String) onSearch;

  const CryptoSearchBar({super.key, required this.onSearch});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        style: TextStyle(color: Colors.white), // Couleur du texte claire
        decoration: InputDecoration(
          hintText: 'Search for a cryptocurrency...',
          hintStyle: TextStyle(color: Colors.white70), // Couleur du texte d'indice plus claire
          prefixIcon: Icon(Icons.search, color: Colors.white70), // Couleur de l'icône de recherche
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white70),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white),
          ),
        ),
        onChanged: onSearch,
      ),
    );
  }
}