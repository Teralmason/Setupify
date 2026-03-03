import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../theme/app_theme.dart';
import '../services/database_service.dart';
import 'profile_screen.dart';

class PostDetailScreen extends StatefulWidget {
  final Map<String, dynamic> postData;
  final String postId;

  const PostDetailScreen(
      {super.key, required this.postData, required this.postId});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  final DatabaseService _dbService = DatabaseService();

  int _currentImageIndex = 0;
  String? _replyingToUser;
  String? _selectedParentId;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _goToProfile(String uid, String name) {
    if (uid.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileScreen(targetUid: uid, targetName: name),
      ),
    );
  }

  // --- GÖNDERİ SİLME ---
  void _deletePost() async {
    bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title:
            const Text("Gönderiyi Sil", style: TextStyle(color: Colors.white)),
        content: const Text("Bu işlemi geri alamazsınız.",
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("İptal")),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text("Sil", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection('community_posts')
          .doc(widget.postId)
          .delete();
      if (mounted) Navigator.pop(context);
    }
  }

  // --- TAM EKRAN RESİM GÖRÜNTÜLEYİCİ ---
  void _openFullScreenImage(List images, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context)),
          ),
          body: Center(
            child: InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 5.0,
              child: Image.network(images[initialIndex], fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('community_posts')
          .doc(widget.postId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Scaffold(
              backgroundColor: Color(0xFF0F0F0F),
              body: Center(child: CircularProgressIndicator()));
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final List images = data['images'] ?? [];
        final String ownerUid = data['uid'] ?? "";
        final String ownerName = data['userName'] ?? "Anonim";

        return Scaffold(
          backgroundColor: const Color(0xFF0F0F0F),
          body: Column(
            children: [
              Expanded(
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    _buildAppBar(images, ownerUid),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildUserHeaderWithStream(ownerUid, ownerName),
                            const SizedBox(height: 20),
                            Text(data['title'] ?? "",
                                style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white)),
                            const SizedBox(height: 12),
                            Text(data['description'] ?? "",
                                style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 15,
                                    height: 1.5)),
                            const Divider(height: 40, color: Colors.white10),
                            const Text("YORUMLAR",
                                style: TextStyle(
                                    color: Colors.white38,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2)),
                            const SizedBox(height: 20),
                            _buildCommentList(ownerUid),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _buildCommentInputArea(ownerUid),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUserHeaderWithStream(String uid, String name) {
    return StreamBuilder<DocumentSnapshot>(
      stream:
          FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, userSnap) {
        String? photoUrl =
            (userSnap.data?.data() as Map<String, dynamic>?)?['photoURL'];

        return GestureDetector(
          onTap: () => _goToProfile(uid, name),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: SetuplyTheme.accentPurple.withOpacity(0.1),
                backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                    ? NetworkImage(photoUrl)
                    : null,
                child: (photoUrl == null || photoUrl.isEmpty)
                    ? const Icon(Icons.person, color: SetuplyTheme.accentPurple)
                    : null,
              ),
              const SizedBox(width: 10),
              Text("@$name",
                  style: const TextStyle(
                      color: SetuplyTheme.accentPurple,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCommentList(String postOwnerUid) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('community_posts')
          .doc(widget.postId)
          .collection('comments')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        final allComments = snapshot.data!.docs;
        final mainComments = allComments
            .where((doc) =>
                (doc.data() as Map<String, dynamic>)['parentCommentId'] == null)
            .toList();

        return ListView.builder(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: mainComments.length,
          itemBuilder: (context, index) {
            final mainDoc = mainComments[index];
            final mainData = mainDoc.data() as Map<String, dynamic>;
            final String mainId = mainDoc.id;
            final replies = allComments
                .where((doc) =>
                    (doc.data() as Map<String, dynamic>)['parentCommentId'] ==
                    mainId)
                .toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSingleCommentRow(mainId, mainData, postOwnerUid, false),
                if (replies.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 35, top: 8),
                    child: Column(
                        children: replies
                            .map((r) => _buildSingleCommentRow(
                                r.id,
                                r.data() as Map<String, dynamic>,
                                postOwnerUid,
                                true))
                            .toList()),
                  ),
                const SizedBox(height: 16),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSingleCommentRow(String commentId, Map<String, dynamic> cData,
      String postOwnerUid, bool isReply) {
    String cUid = cData['uid'] ?? "";
    String cName = cData['userName'] ?? "Anonim";

    return StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(cUid)
            .snapshots(),
        builder: (context, userSnap) {
          String? cPhotoUrl =
              (userSnap.data?.data() as Map<String, dynamic>?)?['photoURL'];
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => _goToProfile(cUid, cName),
                child: CircleAvatar(
                  radius: isReply ? 11 : 14,
                  backgroundColor: Colors.white10,
                  backgroundImage: (cPhotoUrl != null && cPhotoUrl.isNotEmpty)
                      ? NetworkImage(cPhotoUrl)
                      : null,
                  child: (cPhotoUrl == null || cPhotoUrl.isEmpty)
                      ? Icon(Icons.person,
                          size: isReply ? 12 : 14, color: Colors.white38)
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(cName,
                        style: const TextStyle(
                            color: SetuplyTheme.accentPurple,
                            fontWeight: FontWeight.bold,
                            fontSize: 13)),
                    const SizedBox(height: 2),
                    Text(cData['text'] ?? "",
                        style: TextStyle(
                            color: Colors.white70,
                            fontSize: isReply ? 12 : 13)),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: () => setState(() {
                        _replyingToUser = cName;
                        _selectedParentId = commentId;
                      }),
                      child: const Text("Yanıtla",
                          style: TextStyle(
                              color: Colors.white24,
                              fontSize: 11,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              if (cUid == _dbService.currentUid ||
                  postOwnerUid == _dbService.currentUid)
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      size: 16, color: Colors.white24),
                  onPressed: () => FirebaseFirestore.instance
                      .collection('community_posts')
                      .doc(widget.postId)
                      .collection('comments')
                      .doc(commentId)
                      .delete(),
                ),
            ],
          );
        });
  }

  // --- APPBAR GÜNCELLEMESİ (HATA GİDERİLDİ) ---
  Widget _buildAppBar(List images, String ownerUid) {
    bool isOwner = ownerUid == _dbService.currentUid;

    return SliverAppBar(
      expandedHeight: images.isNotEmpty ? 350 : 0,
      pinned: true,
      backgroundColor: const Color(0xFF0F0F0F),
      actions: [
        if (isOwner)
          Theme(
            data: Theme.of(context).copyWith(
                cardColor: const Color(
                    0xFF1A1A1A)), // Menü arka planı için en güvenli yol
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onSelected: (val) {
                if (val == 'delete') _deletePost();
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(
                    value: 'edit',
                    child:
                        Text("Düzenle", style: TextStyle(color: Colors.white))),
                const PopupMenuItem(
                    value: 'delete',
                    child: Text("Sil", style: TextStyle(color: Colors.red))),
              ],
            ),
          ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: images.isNotEmpty
            ? Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CarouselSlider(
                    options: CarouselOptions(
                      height: 400,
                      viewportFraction: 1.0,
                      enableInfiniteScroll: images.length > 1,
                      onPageChanged: (index, reason) =>
                          setState(() => _currentImageIndex = index),
                    ),
                    items: images.asMap().entries.map((entry) {
                      return GestureDetector(
                        onTap: () => _openFullScreenImage(images, entry.key),
                        child: Image.network(entry.value,
                            fit: BoxFit.cover, width: double.infinity),
                      );
                    }).toList(),
                  ),
                  if (images.length > 1)
                    Container(
                      margin: const EdgeInsets.all(15),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20)),
                      child: Text(
                          "${_currentImageIndex + 1} / ${images.length}",
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold)),
                    ),
                ],
              )
            : null,
      ),
    );
  }

  Widget _buildCommentInputArea(String ownerUid) {
    return Container(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 10,
          left: 15,
          right: 15,
          top: 10),
      decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          border:
              Border(top: BorderSide(color: Colors.white.withOpacity(0.05)))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_replyingToUser != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Text("$_replyingToUser kullanıcısına yanıt veriliyor",
                      style:
                          const TextStyle(color: Colors.white38, fontSize: 12)),
                  const Spacer(),
                  GestureDetector(
                      onTap: () => setState(() {
                            _replyingToUser = null;
                            _selectedParentId = null;
                          }),
                      child: const Icon(Icons.close,
                          size: 14, color: Colors.white38)),
                ],
              ),
            ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: "Bir yorum ekle...",
                    hintStyle: const TextStyle(color: Colors.white24),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () async {
                  if (_commentController.text.trim().isEmpty) return;
                  await _dbService.addComment(
                      widget.postId, _commentController.text.trim(), ownerUid,
                      isCommunity: true, parentCommentId: _selectedParentId);
                  _commentController.clear();
                  setState(() {
                    _replyingToUser = null;
                    _selectedParentId = null;
                  });
                  if (mounted) FocusScope.of(context).unfocus();
                },
                child: const CircleAvatar(
                    backgroundColor: SetuplyTheme.accentPurple,
                    child: Icon(Icons.send, color: Colors.white, size: 20)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
