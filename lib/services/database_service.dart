import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ImgBB API Anahtarın
  final String _imgBBKey = "be54a9ba10ecfbc4d3221ec650fe73ec";

  String get currentUid => FirebaseAuth.instance.currentUser?.uid ?? "";

  // 1. RESİM YÜKLEME (ImgBB API)
  Future<List<String>> uploadImages(
      List<File> images, String folderName) async {
    List<String> imageUrls = [];
    for (var image in images) {
      try {
        var request = http.MultipartRequest(
            'POST', Uri.parse('https://api.imgbb.com/1/upload?key=$_imgBBKey'));
        request.files
            .add(await http.MultipartFile.fromPath('image', image.path));
        var response = await request.send();
        if (response.statusCode == 200) {
          var responseData = await response.stream.bytesToString();
          var jsonResponse = jsonDecode(responseData);
          imageUrls.add(jsonResponse['data']['url']);
        }
      } catch (e) {
        print("RESİM YÜKLEME HATASI (ImgBB): $e");
      }
    }
    return imageUrls;
  }

  // 2. SETUP PAYLAŞMA
  Future<void> uploadSetup(
      String title, Map<String, String> specs, List<String> imageUrls) async {
    if (currentUid.isEmpty) return;
    try {
      await _db.collection('setuplar').add({
        'title': title,
        'specs': specs,
        'images': imageUrls,
        'uid': currentUid,
        'userName': FirebaseAuth.instance.currentUser?.displayName ?? "Anonim",
        'likes': [],
        'favs': [],
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("FİRESTORE KAYIT HATASI: $e");
    }
  }

  // 3. PROFİL FOTOSU VE BİLGİ GÜNCELLEME
  Future<void> updateProfilePhoto(File imageFile) async {
    if (currentUid.isEmpty) return;
    try {
      List<String> urls = await uploadImages([imageFile], "profile");
      if (urls.isNotEmpty) {
        String newPhotoUrl = urls[0];
        await FirebaseAuth.instance.currentUser?.updatePhotoURL(newPhotoUrl);

        await _db.collection('users').doc(currentUid).set({
          'photoURL': newPhotoUrl,
          'userName':
              FirebaseAuth.instance.currentUser?.displayName ?? "Anonim",
          'uid': currentUid,
        }, SetOptions(merge: true));
      }
    } catch (e) {
      print("PROFIL GÜNCELLEME HATASI: $e");
    }
  }

  // 4. Yorum Silme Fonksiyonu
  Future<void> deleteComment(String setupId, String commentId,
      {bool isCommunity = false}) async {
    String collectionName = isCommunity ? 'community_posts' : 'setuplar';
    await _db
        .collection(collectionName)
        .doc(setupId)
        .collection('comments')
        .doc(commentId)
        .delete();
  }

  // 5. Bildirimleri okundu işaretleme
  Future<void> markAllNotificationsAsRead() async {
    if (currentUid.isEmpty) return;

    var unreadNotifications = await _db
        .collection('users')
        .doc(currentUid)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .get();

    WriteBatch batch = _db.batch();
    for (var doc in unreadNotifications.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  // 6. VERİ ÇEKME FONKSİYONLARI
  Stream<QuerySnapshot> getSetups() => _db
      .collection('setuplar')
      .orderBy('createdAt', descending: true)
      .snapshots();

  // 7. ETKİLEŞİM SİSTEMLERİ (Like, Fav) - GÜNCELLENDİ (isCommunity eklendi)
  Future<void> toggleLike(String setupId, List likes, String ownerUid,
      {bool isCommunity = false}) async {
    if (currentUid.isEmpty) return;
    String collectionName = isCommunity ? 'community_posts' : 'setuplar';
    DocumentReference docRef = _db.collection(collectionName).doc(setupId);

    if (likes.contains(currentUid)) {
      await docRef.update({
        'likes': FieldValue.arrayRemove([currentUid])
      });
    } else {
      await docRef.update({
        'likes': FieldValue.arrayUnion([currentUid])
      });
      await _sendNotification(
          ownerUid,
          isCommunity ? "gönderini beğendi!" : "setupunu beğendi!",
          setupId,
          'like',
          isCommunity: isCommunity);
    }
  }

  Future<void> toggleFavorite(String setupId, List favs, String ownerUid,
      {bool isCommunity = false}) async {
    if (currentUid.isEmpty) return;
    String collectionName = isCommunity ? 'community_posts' : 'setuplar';
    DocumentReference docRef = _db.collection(collectionName).doc(setupId);

    if (favs.contains(currentUid)) {
      await docRef.update({
        'favs': FieldValue.arrayRemove([currentUid])
      });
    } else {
      await docRef.update({
        'favs': FieldValue.arrayUnion([currentUid])
      });
      await _sendNotification(
          ownerUid,
          isCommunity
              ? "gönderini favorilerine ekledi!"
              : "setupunu favorilerine ekledi!",
          setupId,
          'fav',
          isCommunity: isCommunity);
    }
  }

  // 8. YORUM EKLEME - GÜNCELLENDİ (parentCommentId eklendi)
  Future<void> addComment(String setupId, String commentText, String ownerUid,
      {String? replyToId,
      String? replyToUser,
      String? parentCommentId, // YENİ PARAMETRE
      bool isCommunity = false}) async {
    if (currentUid.isEmpty) return;

    String collectionName = isCommunity ? 'community_posts' : 'setuplar';
    String finalComment =
        replyToUser != null ? "@$replyToUser $commentText" : commentText;

    await _db
        .collection(collectionName)
        .doc(setupId)
        .collection('comments')
        .add({
      'text': finalComment,
      'userName': FirebaseAuth.instance.currentUser?.displayName ?? "Anonim",
      'uid': currentUid,
      'replyTo': replyToId,
      'parentCommentId': parentCommentId, // FIRESTORE KAYIT
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _sendNotification(
        ownerUid,
        isCommunity
            ? "gönderine yorum yaptı: $finalComment"
            : "setupuna yorum yaptı: $finalComment",
        setupId,
        'comment',
        isCommunity: isCommunity);
  }

  // 9. BİLDİRİM GÖNDERME
  Future<void> _sendNotification(
      String receiverUid, String message, String setupId, String type,
      {bool isCommunity = false}) async {
    if (currentUid.isEmpty || receiverUid == currentUid) return;
    await _db
        .collection('users')
        .doc(receiverUid)
        .collection('notifications')
        .add({
      'senderUid': currentUid,
      'senderName':
          FirebaseAuth.instance.currentUser?.displayName ?? "Bir Kullanıcı",
      'message': message,
      'setupId': setupId,
      'type': type,
      'isRead': false,
      'isCommunity': isCommunity,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // 10. SETUP SİLME
  Future<void> deleteSetup(String setupId) async =>
      await _db.collection('setuplar').doc(setupId).delete();
}
