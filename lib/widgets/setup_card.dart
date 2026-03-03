import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../screens/setup_detail_screen.dart';

class SetupCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String setupId;

  const SetupCard({super.key, required this.data, required this.setupId});

  @override
  Widget build(BuildContext context) {
    List images = data['images'] ?? [];

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                SetupDetailScreen(setupData: data, setupId: setupId),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: SetuplyTheme.glassColor,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
              color: SetuplyTheme.accentPurple.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // GÖRSEL KISMI (Boş ikon yerine gerçek resim)
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(25)),
              child: images.isNotEmpty
                  ? Image.network(
                      images[0],
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      height: 150,
                      width: double.infinity,
                      color: SetuplyTheme.deepPurple,
                      child: const Icon(Icons.desktop_windows,
                          size: 50, color: Colors.white10),
                    ),
            ),

            // BİLGİ KISMI
            Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['title'] ?? "Başlıksız Setup",
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "Paylaşan: ${data['userName'] ?? "Anonim"}",
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.favorite,
                          color: Colors.redAccent, size: 16),
                      const SizedBox(width: 5),
                      Text("${(data['likes'] as List?)?.length ?? 0}"),
                      const SizedBox(width: 15),
                      const Icon(Icons.comment,
                          color: SetuplyTheme.accentPurple, size: 16),
                      const SizedBox(width: 5),
                      const Text("Yorumlar"),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
