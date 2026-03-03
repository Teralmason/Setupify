import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../theme/app_theme.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final List<File> _selectedImages = [];
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  // BURAYA KENDİ IMGBB API KEY'İNİ YAZ
  final String _imgBBKey = "be54a9ba10ecfbc4d3221ec650fe73ec";

  // ImgBB'ye Tekli Resim Yükleme Fonksiyonu
  Future<String?> _uploadToImgBB(File imageFile) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.imgbb.com/1/upload?key=$_imgBBKey'),
      );

      request.files
          .add(await http.MultipartFile.fromPath('image', imageFile.path));

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final jsonResponse = json.decode(responseData);

      if (response.statusCode == 200) {
        return jsonResponse['data']['url']; // Resmin direkt linkini döner
      } else {
        debugPrint("ImgBB Hatası: ${jsonResponse['error']['message']}");
        return null;
      }
    } catch (e) {
      debugPrint("Bağlantı Hatası: $e");
      return null;
    }
  }

  // Gönderiyi Paylaşma
  Future<void> _sharePost() async {
    if (_titleController.text.trim().isEmpty ||
        _descController.text.trim().isEmpty) {
      _showError("Başlık ve açıklama zorunludur!");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw "Giriş yapmalısın!";

      List<String> imageUrls = [];

      // 1. ADIM: RESİMLERİ IMGBB'YE PARALEL YÜKLE
      if (_selectedImages.isNotEmpty) {
        List<Future<String?>> uploadTasks =
            _selectedImages.map((file) => _uploadToImgBB(file)).toList();

        final results = await Future.wait(uploadTasks);

        // Sadece başarılı yüklenen URL'leri listeye ekle
        for (var url in results) {
          if (url != null) imageUrls.add(url);
        }
      }

      // 2. ADIM: FIRESTORE'A SADECE LİNKLERİ KAYDET
      await FirebaseFirestore.instance.collection('community_posts').add({
        'uid': user.uid,
        'userName': user.displayName ?? "Anonim",
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'images': imageUrls, // ImgBB'den gelen linkler
        'createdAt': FieldValue.serverTimestamp(),
        'likes': [],
        'commentCount': 0,
      });

      if (mounted) {
        Navigator.pop(context);
        _showSuccess("Paylaşıldı!");
      }
    } catch (e) {
      if (mounted) _showError("Hata: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- Yardımcı Widgetlar ve Fonksiyonlar ---

  Future<void> _pickImages() async {
    if (_selectedImages.length >= 10) return;
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images.map((e) => File(e.path)));
        if (_selectedImages.length > 10) {
          _selectedImages.removeRange(10, _selectedImages.length);
        }
      });
    }
  }

  void _showError(String m) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(m), backgroundColor: Colors.red));
  void _showSuccess(String m) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(m), backgroundColor: SetuplyTheme.accentPurple));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("YENİ TARTIŞMA"),
        actions: [
          if (!_isLoading)
            TextButton(
                onPressed: _sharePost,
                child: const Text("PAYLAŞ",
                    style: TextStyle(
                        color: SetuplyTheme.accentPurple,
                        fontWeight: FontWeight.bold)))
        ],
      ),
      body: _isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(color: SetuplyTheme.accentPurple))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(hintText: "Başlık"),
                      style: const TextStyle(color: Colors.white)),
                  const SizedBox(height: 20),
                  TextField(
                      controller: _descController,
                      maxLines: 5,
                      decoration: const InputDecoration(hintText: "Açıklama"),
                      style: const TextStyle(color: Colors.white)),
                  const SizedBox(height: 20),
                  _buildImageGrid(),
                ],
              ),
            ),
    );
  }

  Widget _buildImageGrid() {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _selectedImages.length + 1,
        itemBuilder: (ctx, i) {
          if (i == 0) {
            return GestureDetector(
                onTap: _pickImages,
                child: Container(
                    width: 80,
                    color: Colors.white10,
                    child:
                        const Icon(Icons.add_a_photo, color: Colors.white24)));
          }
          return Padding(
            padding: const EdgeInsets.only(left: 10),
            child: Image.file(_selectedImages[i - 1],
                width: 80, height: 80, fit: BoxFit.cover),
          );
        },
      ),
    );
  }
}
