import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';
import '../services/database_service.dart';
import 'setup_detail_screen.dart';
import '../screens/auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String? targetUid;
  final String? targetName;
  const ProfileScreen({super.key, this.targetUid, this.targetName});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final DatabaseService _dbService = DatabaseService();

  // Aktif UID'yi güvenli bir şekilde alıyoruz
  String get activeUid =>
      widget.targetUid ?? FirebaseAuth.instance.currentUser?.uid ?? "";

  bool get isOwnProfile => activeUid == FirebaseAuth.instance.currentUser?.uid;

  Future<void> _onRefresh() async {
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) setState(() {});
  }

  Future<void> _changeProfilePhoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
    );

    if (pickedFile != null) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
            child: CircularProgressIndicator(color: SetuplyTheme.accentPurple)),
      );

      await _dbService.updateProfilePhoto(File(pickedFile.path));

      if (mounted) {
        Navigator.pop(context);
        setState(() {});
      }
    }
  }

  void _logOut() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isOwnProfile ? "PROFİLİM" : "PROFİL"),
        actions: [
          if (isOwnProfile)
            IconButton(
              onPressed: _logOut,
              icon: const Icon(Icons.logout, color: Colors.redAccent),
            ),
        ],
      ),
      body: RefreshIndicator(
        color: SetuplyTheme.accentPurple,
        backgroundColor: SetuplyTheme.deepPurple,
        onRefresh: _onRefresh,
        child: activeUid.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : StreamBuilder<DocumentSnapshot>(
                // Çıkış yapıldıysa stream'i durdurmak için kontrol eklendi
                stream:
                    FirebaseAuth.instance.currentUser == null && isOwnProfile
                        ? const Stream.empty()
                        : FirebaseFirestore.instance
                            .collection('users')
                            .doc(activeUid)
                            .snapshots(),
                builder: (context, userSnap) {
                  // Hata kontrolü: Yetki hatası alınırsa boş dön
                  if (userSnap.hasError) return const SizedBox.shrink();

                  var userData = userSnap.data?.data() as Map<String, dynamic>?;

                  String displayName = userData?['userName'] ??
                      userData?['name'] ??
                      widget.targetName ??
                      (isOwnProfile
                          ? FirebaseAuth.instance.currentUser?.displayName
                          : null) ??
                      "Kullanıcı";

                  String? photoURL = userData?['photoURL'] ??
                      (isOwnProfile
                          ? FirebaseAuth.instance.currentUser?.photoURL
                          : null);

                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        GestureDetector(
                          onTap: isOwnProfile ? _changeProfilePhoto : null,
                          child: CircleAvatar(
                            radius: 50,
                            backgroundColor: SetuplyTheme.accentPurple,
                            backgroundImage: photoURL != null
                                ? NetworkImage(photoURL)
                                : null,
                            child: photoURL == null
                                ? const Icon(Icons.person,
                                    size: 50, color: Colors.white)
                                : null,
                          ),
                        ),
                        const SizedBox(height: 15),
                        Text(displayName,
                            style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                        const SizedBox(height: 5),
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseAuth.instance.currentUser == null &&
                                  isOwnProfile
                              ? const Stream.empty()
                              : FirebaseFirestore.instance
                                  .collection('setuplar')
                                  .where('uid', isEqualTo: activeUid)
                                  .snapshots(),
                          builder: (context, snapshot) {
                            int totalLikes = 0;
                            if (snapshot.hasData) {
                              for (var doc in snapshot.data!.docs) {
                                totalLikes +=
                                    (doc['likes'] as List? ?? []).length;
                              }
                            }
                            return Text("$totalLikes Toplam Beğeni",
                                style: const TextStyle(
                                    color: SetuplyTheme.accentPurple,
                                    fontWeight: FontWeight.w600));
                          },
                        ),
                        const SizedBox(height: 30),
                        DefaultTabController(
                          length: 2,
                          child: Column(
                            children: [
                              const TabBar(
                                indicatorColor: SetuplyTheme.accentPurple,
                                labelColor: SetuplyTheme.accentPurple,
                                unselectedLabelColor: Colors.white38,
                                tabs: [
                                  Tab(text: "Setuplar"),
                                  Tab(text: "Favoriler")
                                ],
                              ),
                              SizedBox(
                                height: 500,
                                child: TabBarView(
                                  children: [
                                    _buildSetupGrid(FirebaseFirestore.instance
                                        .collection('setuplar')
                                        .where('uid', isEqualTo: activeUid)
                                        .snapshots()),
                                    _buildSetupGrid(FirebaseFirestore.instance
                                        .collection('setuplar')
                                        .where('favs', arrayContains: activeUid)
                                        .snapshots()),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildSetupGrid(Stream<QuerySnapshot> stream) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseAuth.instance.currentUser == null && isOwnProfile
          ? const Stream.empty()
          : stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) return const SizedBox.shrink();

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
              child: Text("Henüz bir şey yok...",
                  style: TextStyle(color: Colors.white24)));
        }
        return GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          padding: const EdgeInsets.only(top: 20, bottom: 20),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1,
          ),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var doc = snapshot.data!.docs[index];
            var data = doc.data() as Map<String, dynamic>;
            List images = data['images'] ?? [];
            return GestureDetector(
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          SetupDetailScreen(setupData: data, setupId: doc.id))),
              child: Container(
                decoration: BoxDecoration(
                  color: SetuplyTheme.deepPurple,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.white10),
                  image: images.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(images[0]), fit: BoxFit.cover)
                      : null,
                ),
                child: Container(
                  alignment: Alignment.bottomCenter,
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7)
                        ]),
                  ),
                  child: Text(data['title'] ?? "",
                      style: const TextStyle(
                          fontSize: 10, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
