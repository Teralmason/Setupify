import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import '../theme/app_theme.dart';
import '../services/database_service.dart';
import 'profile_screen.dart';

class SetupDetailScreen extends StatefulWidget {
  final Map<String, dynamic> setupData;
  final String setupId;
  const SetupDetailScreen(
      {super.key, required this.setupData, required this.setupId});

  @override
  State<SetupDetailScreen> createState() => _SetupDetailScreenState();
}

class _SetupDetailScreenState extends State<SetupDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  final DatabaseService _dbService = DatabaseService();
  final CarouselSliderController _carouselController =
      CarouselSliderController();
  int _currentImageIndex = 0;
  String? _selectedParentId; // DEĞİŞTİ: replyToId yerine parentId kullanıyoruz
  String? _replyingToUser;

  // --- FOTOĞRAFLARI TAM EKRAN AÇMA ---
  void _openFullScreenGallery(List images, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
            title: Text("${initialIndex + 1} / ${images.length}",
                style: const TextStyle(color: Colors.white, fontSize: 16)),
          ),
          body: PhotoViewGallery.builder(
            itemCount: images.length,
            pageController: PageController(initialPage: initialIndex),
            builder: (context, index) {
              return PhotoViewGalleryPageOptions(
                imageProvider: NetworkImage(images[index]),
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 2,
              );
            },
            scrollPhysics: const BouncingScrollPhysics(),
            backgroundDecoration: const BoxDecoration(color: Colors.black),
          ),
        ),
      ),
    );
  }

  // --- SADECE DOMAİN İÇERENLERİ AÇAN URL KONTROLÜ ---
  Future<void> _handleLink(String value) async {
    String val = value.toLowerCase().trim();
    if (val.contains(".com") ||
        val.contains(".net") ||
        val.contains(".org") ||
        val.contains(".edu") ||
        val.contains("www.")) {
      String formattedUrl = val.contains("http") ? val : "https://$val";
      final Uri url = Uri.parse(formattedUrl);
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text("Link açılamadı!")));
        }
      }
    }
  }

  // --- İKON BELİRLEYİCİ ---
  IconData _getIconForSpec(String label) {
    label = label.toLowerCase();
    if (label.contains("ekran kartı") || label.contains("gpu")) {
      return Icons.developer_board;
    }
    if (label.contains("işlemci") || label.contains("cpu")) return Icons.memory;
    if (label.contains("ram")) return Icons.storage;
    if (label.contains("monitör") || label.contains("ekran")) {
      return Icons.monitor;
    }
    return Icons.settings_suggest;
  }

  // --- KÜÇÜK, YAN YANA DİZİLEN MOR ÇİPLER ---
  Widget _buildSpecChip(String label, dynamic value) {
    if (value == null || value.toString().isEmpty) return const SizedBox();
    String valStr = value.toString();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: SetuplyTheme.accentPurple.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: SetuplyTheme.accentPurple.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_getIconForSpec(label),
                  size: 12, color: SetuplyTheme.accentPurple),
              const SizedBox(width: 4),
              Text(label.toUpperCase(),
                  style: const TextStyle(
                      color: SetuplyTheme.accentPurple,
                      fontSize: 9,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 4,
            children: _buildSmartText(valStr),
          ),
        ],
      ),
    );
  }

  // --- SMART TEXT ---
  List<Widget> _buildSmartText(String content) {
    List<String> parts = content.split(RegExp(r'[,\s]+'));
    List<Widget> widgets = [];

    for (var part in parts) {
      if (part.isEmpty) continue;
      bool isRealLink =
          part.contains(RegExp(r'\.(com|net|org|edu|gov|io|www\.)'));

      widgets.add(
        GestureDetector(
          onTap: isRealLink ? () => _handleLink(part) : null,
          child: Text(
            part,
            style: TextStyle(
              color: isRealLink ? Colors.blueAccent : Colors.white,
              fontSize: 12,
              fontWeight: isRealLink ? FontWeight.bold : FontWeight.normal,
              decoration:
                  isRealLink ? TextDecoration.underline : TextDecoration.none,
            ),
          ),
        ),
      );
    }
    return widgets;
  }

  // --- YENİ: TEKİL YORUM TASARIMI (İÇ İÇE ÇAĞRILABİLİR) ---
  Widget _buildCommentItem(DocumentSnapshot comment, String ownerUid,
      {bool isReply = false}) {
    String commenterUid = comment['uid'];
    String commentId = comment.id;
    bool canDelete = (ownerUid == _dbService.currentUid ||
        commenterUid == _dbService.currentUid);

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(commenterUid)
          .snapshots(),
      builder: (context, userSnap) {
        String? userImg =
            (userSnap.data?.data() as Map<String, dynamic>?)?['photoURL'];

        return Container(
          margin: EdgeInsets.only(left: isReply ? 40 : 0, bottom: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: GestureDetector(
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => ProfileScreen(
                              targetUid: commenterUid,
                              targetName: comment['userName']))),
                  child: CircleAvatar(
                    backgroundColor: Colors.white10,
                    radius: isReply ? 12 : 16,
                    backgroundImage:
                        userImg != null ? NetworkImage(userImg) : null,
                    child: userImg == null
                        ? Icon(Icons.person,
                            size: isReply ? 10 : 14, color: Colors.white54)
                        : null,
                  ),
                ),
                title: Text(comment['userName'],
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: SetuplyTheme.accentPurple)),
                subtitle: Text(comment['text'],
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 12)),
                trailing: Wrap(
                  spacing: 8,
                  children: [
                    if (!isReply)
                      TextButton(
                        onPressed: () => setState(() {
                          _selectedParentId = commentId;
                          _replyingToUser = comment['userName'];
                        }),
                        child: const Text("Yanıtla",
                            style:
                                TextStyle(fontSize: 10, color: Colors.white38)),
                      ),
                    if (canDelete)
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            size: 18, color: Colors.redAccent),
                        onPressed: () =>
                            _dbService.deleteComment(widget.setupId, commentId),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('setuplar')
          .doc(widget.setupId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        var currentData = snapshot.data!.data() as Map<String, dynamic>;
        List images = currentData['images'] ?? [];
        Map specs = currentData['specs'] ?? {};
        String ownerUid = currentData['uid'] ?? "";
        List likes = currentData['likes'] ?? [];
        List favs = currentData['favs'] ?? [];
        bool isLiked = likes.contains(_dbService.currentUid);
        bool isFaved = favs.contains(_dbService.currentUid);

        return Scaffold(
          backgroundColor: const Color(0xFF0F0F0F),
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 450,
                pinned: true,
                backgroundColor: Colors.black,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    children: [
                      GestureDetector(
                        onTap: () =>
                            _openFullScreenGallery(images, _currentImageIndex),
                        child: CarouselSlider(
                          carouselController: _carouselController,
                          options: CarouselOptions(
                            height: 500,
                            viewportFraction: 1.0,
                            enableInfiniteScroll: false,
                            onPageChanged: (index, _) =>
                                setState(() => _currentImageIndex = index),
                          ),
                          items: images
                              .map((url) => Hero(
                                  tag: url,
                                  child: Image.network(url,
                                      fit: BoxFit.cover,
                                      width: double.infinity)))
                              .toList(),
                        ),
                      ),
                      Positioned(
                        bottom: 30,
                        right: 20,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(20)),
                          child: Text(
                              "${_currentImageIndex + 1} / ${images.length}",
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 12)),
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  if (ownerUid == _dbService.currentUid)
                    IconButton(
                      icon: const Icon(Icons.delete_sweep,
                          color: Colors.redAccent),
                      onPressed: () async {
                        await _dbService.deleteSetup(widget.setupId);
                        if (mounted) Navigator.pop(context);
                      },
                    ),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(currentData['title'] ?? "",
                                    style: const TextStyle(
                                        fontSize: 26,
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                GestureDetector(
                                  onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => ProfileScreen(
                                              targetUid: ownerUid,
                                              targetName:
                                                  currentData['userName']))),
                                  child: Text("@${currentData['userName']}",
                                      style: const TextStyle(
                                          color: SetuplyTheme.accentPurple,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16)),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              Column(
                                children: [
                                  IconButton(
                                    icon: Icon(
                                        isLiked
                                            ? Icons.favorite
                                            : Icons.favorite_border,
                                        color: isLiked
                                            ? Colors.redAccent
                                            : Colors.white),
                                    onPressed: () => _dbService.toggleLike(
                                        widget.setupId, likes, ownerUid),
                                  ),
                                  Text("${likes.length}",
                                      style: const TextStyle(
                                          fontSize: 12, color: Colors.white70)),
                                ],
                              ),
                              const SizedBox(width: 15),
                              Column(
                                children: [
                                  IconButton(
                                    icon: Icon(
                                        isFaved
                                            ? Icons.bookmark
                                            : Icons.bookmark_border,
                                        color: isFaved
                                            ? SetuplyTheme.accentPurple
                                            : Colors.white),
                                    onPressed: () => _dbService.toggleFavorite(
                                        widget.setupId, favs, ownerUid),
                                  ),
                                  const Text("Favori",
                                      style: TextStyle(
                                          fontSize: 12, color: Colors.white70)),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Divider(height: 50, color: Colors.white10),
                      const Text("BİLEŞENLER",
                          style: TextStyle(
                              letterSpacing: 2,
                              fontSize: 11,
                              color: Colors.white38,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 15),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: specs.entries
                            .map<Widget>((entry) =>
                                _buildSpecChip(entry.key, entry.value))
                            .toList(),
                      ),
                      const SizedBox(height: 40),
                      const Text("YORUMLAR",
                          style: TextStyle(
                              letterSpacing: 1.5,
                              fontSize: 11,
                              color: Colors.white38,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 15),

                      // --- YORUM YAPMA ---
                      if (_selectedParentId != null)
                        Container(
                          padding: const EdgeInsets.all(10),
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                              color: SetuplyTheme.accentPurple.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10)),
                          child: Row(
                            children: [
                              Text(
                                  "$_replyingToUser kullanıcısına yanıt veriliyor",
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: SetuplyTheme.accentPurple)),
                              const Spacer(),
                              IconButton(
                                  icon: const Icon(Icons.close, size: 16),
                                  onPressed: () =>
                                      setState(() => _selectedParentId = null)),
                            ],
                          ),
                        ),

                      TextField(
                        controller: _commentController,
                        style: const TextStyle(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: "Yorum yap...",
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 15, vertical: 10),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.send,
                                color: SetuplyTheme.accentPurple, size: 20),
                            onPressed: () {
                              if (_commentController.text.isNotEmpty) {
                                _dbService.addComment(
                                  widget.setupId,
                                  _commentController.text,
                                  ownerUid,
                                  parentCommentId:
                                      _selectedParentId, // Burayı güncelledik
                                );
                                _commentController.clear();
                                setState(() => _selectedParentId = null);
                                FocusScope.of(context).unfocus();
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // --- GÜNCELLENMİŞ İÇ İÇE YORUM LİSTESİ ---
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('setuplar')
                            .doc(widget.setupId)
                            .collection('comments')
                            .orderBy('createdAt', descending: true)
                            .snapshots(),
                        builder: (context, commentSnap) {
                          if (!commentSnap.hasData) return const SizedBox();

                          // Ana yorumları (parentCommentId'si olmayanlar) filtrele
                          var mainComments =
                              commentSnap.data!.docs.where((doc) {
                            var data = doc.data() as Map<String, dynamic>;
                            return data['parentCommentId'] == null;
                          }).toList();

                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: mainComments.length,
                            itemBuilder: (context, index) {
                              var mainComment = mainComments[index];

                              // Bu ana yoruma ait alt yanıtları bul
                              var replies = commentSnap.data!.docs.where((doc) {
                                var data = doc.data() as Map<String, dynamic>;
                                return data['parentCommentId'] ==
                                    mainComment.id;
                              }).toList();

                              return Column(
                                children: [
                                  _buildCommentItem(mainComment, ownerUid),
                                  ...replies.map((reply) => _buildCommentItem(
                                      reply, ownerUid,
                                      isReply: true)),
                                ],
                              );
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              )
            ],
          ),
        );
      },
    );
  }
}
