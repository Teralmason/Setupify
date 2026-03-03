import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../services/database_service.dart';
import 'setup_detail_screen.dart';
import 'post_detail_screen.dart'; // Eğer screens klasörü altındaysa '../screens/post_detail_screen.dart'

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    // Ekran açıldığında bildirimleri okundu olarak işaretle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      DatabaseService().markAllNotificationsAsRead();
    });
  }

  // --- TÜM BİLDİRİMLERİ SİLME FONKSİYONU ---
  Future<void> _clearAllNotifications() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final batch = FirebaseFirestore.instance.batch();
    final snapshots = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .get();

    for (var doc in snapshots.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tüm bildirimler temizlendi.")),
      );
    }
  }

  String _getTimeAgo(Timestamp? timestamp) {
    if (timestamp == null) return "Az önce";
    final diff = DateTime.now().difference(timestamp.toDate());
    if (diff.inMinutes < 1) return "Az önce";
    if (diff.inMinutes < 60) return "${diff.inMinutes} dk önce";
    if (diff.inHours < 24) return "${diff.inHours} sa önce";
    return "${diff.inDays} gün önce";
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text("Giriş yapın")));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("BİLDİRİMLER"),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep, color: Colors.redAccent),
            tooltip: "Tümünü Temizle",
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Bildirimleri Sil"),
                  content:
                      const Text("Tüm bildirimler silinecek. Emin misiniz?"),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("İptal")),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _clearAllNotifications();
                      },
                      child: const Text("Sil",
                          style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('notifications')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Hata oluştu."));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text("Henüz bildirim yok. 📭"));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var data = docs[index].data() as Map<String, dynamic>;
              bool isRead = data['isRead'] ?? false;
              bool isCommunity =
                  data['isCommunity'] ?? false; // Topluluk kontrolü

              return ListTile(
                tileColor: isRead
                    ? Colors.transparent
                    : Colors.white.withOpacity(0.05),
                leading: CircleAvatar(
                  backgroundColor:
                      isRead ? Colors.grey[800] : SetuplyTheme.accentPurple,
                  child: const Icon(Icons.notifications_active,
                      color: Colors.white, size: 20),
                ),
                title: RichText(
                  text: TextSpan(
                    style: TextStyle(
                        color: isRead ? Colors.white70 : Colors.white),
                    children: [
                      TextSpan(
                        text: "${data['senderName'] ?? 'Sistem'} ",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(text: data['message'] ?? ""),
                    ],
                  ),
                ),
                subtitle: Text(_getTimeAgo(data['createdAt'] as Timestamp?),
                    style:
                        const TextStyle(fontSize: 11, color: Colors.white38)),
                onTap: () async {
                  // 1. Bildirimden gelen verileri güvenli bir şekilde alıyoruz
                  String targetId = (data['setupId'] ?? "").toString();
                  bool isCommunity = data['isCommunity'] ?? false;

                  if (targetId.isNotEmpty) {
                    if (isCommunity) {
                      // --- TOPLULUK POSTU İSE BURAYA ---
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PostDetailScreen(
                            // Senin topluluk detay sayfan
                            postData: data,
                            postId: targetId,
                          ),
                        ),
                      );
                    } else {
                      // --- NORMAL SETUP İSE BURAYA ---
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SetupDetailScreen(
                            setupData: data,
                            setupId: targetId,
                          ),
                        ),
                      );
                    }
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}
