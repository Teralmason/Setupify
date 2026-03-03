import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/database_service.dart';
import '../widgets/setup_card.dart'; // Eğer setup kartını widget yapmıştık ya hani

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final DatabaseService _dbService = DatabaseService();
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "Setup veya donanım ara...",
            hintStyle: TextStyle(color: Colors.white38),
            border: InputBorder.none,
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _dbService
            .getSetups(), // Şimdilik tümünü çekip kod tarafında filtreleyelim (Daha esnek olur)
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          // Kod tarafında detaylı filtreleme (Hem başlık hem specs)
          var filteredDocs = snapshot.data!.docs.where((doc) {
            var data = doc.data() as Map<String, dynamic>;
            String title = (data['title'] ?? "").toString().toLowerCase();
            Map specs = data['specs'] ?? {};

            // Başlıkta ara
            bool titleMatch = title.contains(_searchQuery.toLowerCase());

            // Donanımlarda ara (RAM, Ekran Kartı vs.)
            bool specMatch = specs.values.any((value) => value
                .toString()
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()));

            return titleMatch || specMatch;
          }).toList();

          if (filteredDocs.isEmpty) {
            return const Center(
                child: Text("Hocam böyle bir canavar bulunamadı. 🔍"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: filteredDocs.length,
            itemBuilder: (context, index) {
              var data = filteredDocs[index].data() as Map<String, dynamic>;
              return SetupCard(
                data: data,
                setupId: filteredDocs[index].id,
              );
            },
          );
        },
      ),
    );
  }
}
