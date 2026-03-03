import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../screens/search_screen.dart';
import '../screens/notification_screen.dart';
import '../services/database_service.dart';
import 'setup_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<void> _handleRefresh() async {
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // HATA BURADAYDI: FontWeight.black düzeltildi, const kaldırıldı
        title: const Text(
          "SETUPIFY",
          style: TextStyle(
            letterSpacing: 2,
            fontWeight: FontWeight.w900, // En kalın font (Black yerine)
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded, color: Colors.white),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (context) => const SearchScreen())),
          ),
          _buildNotificationIcon(),
          const SizedBox(width: 10),
        ],
      ),
      body: RefreshIndicator(
        color: SetuplyTheme.accentPurple,
        backgroundColor: SetuplyTheme.deepPurple,
        onRefresh: _handleRefresh,
        child: StreamBuilder<QuerySnapshot>(
          stream: DatabaseService().getSetups(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator(
                      color: SetuplyTheme.accentPurple));
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return _buildEmptyState();
            }

            var setups = snapshot.data!.docs;

            return GridView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                  16, 16, 16, 110), // Nav bar boşluğu artırıldı
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.75,
              ),
              itemCount: setups.length,
              itemBuilder: (context, index) {
                var doc = setups[index];
                var data = doc.data() as Map<String, dynamic>;
                return _buildSetupCard(data, doc.id);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildSetupCard(Map<String, dynamic> data, String docId) {
    List images = data['images'] ?? [];
    List likes = data['likes'] ?? [];

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) =>
                SetupDetailScreen(setupData: data, setupId: docId)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: SetuplyTheme.glassColor,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: Stack(
            children: [
              Positioned.fill(
                child: images.isNotEmpty
                    ? Image.network(images[0], fit: BoxFit.cover)
                    : Container(color: Colors.white10),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.8),
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        data['title'] ?? "Başlıksız",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.white),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.favorite_rounded,
                              color: Colors.redAccent, size: 14),
                          const SizedBox(width: 4),
                          Text("${likes.length}",
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.white70)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationIcon() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(DatabaseService().currentUid)
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .snapshots(),
      builder: (context, snapshot) {
        bool hasNotification =
            snapshot.hasData && snapshot.data!.docs.isNotEmpty;
        return IconButton(
          icon: Icon(
            hasNotification
                ? Icons.notifications_active_rounded
                : Icons.notifications_none_rounded,
            color: hasNotification ? SetuplyTheme.accentPurple : Colors.white,
          ),
          onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const NotificationScreen())),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: const [
        SizedBox(height: 200),
        Center(
            child: Text("Henüz setup yok...",
                style: TextStyle(color: Colors.white38))),
      ],
    );
  }
}
