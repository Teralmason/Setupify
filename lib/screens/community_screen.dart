import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import 'create_post_screen.dart';
import 'post_detail_screen.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  // Sayfa yenileme fonksiyonu
  Future<void> _handleRefresh() async {
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("TOPLULUK",
            style: TextStyle(letterSpacing: 1.2, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        color: SetuplyTheme.accentPurple,
        backgroundColor: SetuplyTheme.deepPurple,
        onRefresh: _handleRefresh,
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('community_posts')
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child:
                    CircularProgressIndicator(color: SetuplyTheme.accentPurple),
              );
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return _buildEmptyState();
            }

            var posts = snapshot.data!.docs;

            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(15, 10, 15, 110),
              itemCount: posts.length,
              itemBuilder: (context, index) {
                var doc = posts[index];
                var data = doc.data() as Map<String, dynamic>;
                return _buildCompactPostCard(data, doc.id);
              },
            );
          },
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 90.0),
        child: FloatingActionButton(
          backgroundColor: SetuplyTheme.accentPurple,
          elevation: 8,
          onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const CreatePostScreen())),
          child: const Icon(Icons.add_comment_rounded,
              color: Colors.white, size: 28),
        ),
      ),
    );
  }

  // KOMPAKT KART TASARIMI (CANLI YORUM SAYILI)
  Widget _buildCompactPostCard(Map<String, dynamic> data, String docId) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PostDetailScreen(
            postData: data,
            postId: docId,
          ),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: SetuplyTheme.glassColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['title'] ?? "Başlıksız Konu",
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "@${data['userName'] ?? "anonim"}",
                    style: const TextStyle(
                      color: SetuplyTheme.accentPurple,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 15),
            // Yorum Sayısını Alt Koleksiyondan Çeken Kısım
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('community_posts')
                  .doc(docId)
                  .collection('comments')
                  .snapshots(),
              builder: (context, commentSnapshot) {
                // Eğer veri henüz gelmediyse 0 göster
                int realCommentCount = 0;
                if (commentSnapshot.hasData) {
                  realCommentCount = commentSnapshot.data!.docs.length;
                }

                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: SetuplyTheme.accentPurple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: SetuplyTheme.accentPurple.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.forum_outlined,
                          size: 16, color: SetuplyTheme.accentPurple),
                      const SizedBox(height: 2),
                      Text(
                        "$realCommentCount",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // BOŞ DURUM EKRANI
  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: const [
        SizedBox(height: 200),
        Center(
          child: Text(
            "Henüz bir tartışma açılmamış.",
            style: TextStyle(color: Colors.white38),
          ),
        ),
      ],
    );
  }
}
