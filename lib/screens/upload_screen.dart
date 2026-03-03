import 'dart:io';
import 'dart:ui'; // BackdropFilter (blur) için gerekli
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';
import '../services/database_service.dart';
import 'package:Setupify/screens/main_wrapper.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});
  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final DatabaseService _dbService = DatabaseService();
  final ImagePicker _picker = ImagePicker();
  List<File> _selectedImages = [];
  bool _isLoading = false;

  final Map<String, TextEditingController> _controllers = {
    'Başlık (Zorunlu)': TextEditingController(),
    'Ram': TextEditingController(),
    'İşletim Sistemi': TextEditingController(),
    'Ekran Kartı': TextEditingController(),
    'VRAM': TextEditingController(),
    'Depolama': TextEditingController(),
    'Ekran Hz': TextEditingController(),
    'Klavye (Opsiyonel)': TextEditingController(),
    'Mouse (Opsiyonel)': TextEditingController(),
    'Linkler (Opsiyonel)': TextEditingController(),
  };

  // --- DYNAMIC ISLAND NOTIFICATION ---
  void _showStatusTop(String msg, {bool isError = true}) {
    OverlayState? overlayState = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 10,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: TweenAnimationBuilder(
            duration: const Duration(milliseconds: 800),
            curve: Curves.elasticOut,
            tween: Tween<Offset>(
                begin: const Offset(0, -1.5), end: const Offset(0, 0)),
            builder: (context, Offset offset, child) {
              return FractionalTranslation(
                translation: offset,
                child: child,
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  decoration: BoxDecoration(
                    color: isError
                        ? Colors.redAccent.withOpacity(0.8)
                        : SetuplyTheme.accentPurple.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isError
                            ? Icons.error_outline
                            : Icons.rocket_launch_rounded,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          msg,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    overlayState.insert(overlayEntry);
    Future.delayed(const Duration(seconds: 3), () {
      overlayEntry.remove();
    });
  }

  // --- IMAGE PICKER ---
  Future<void> _pickImages() async {
    if (_isLoading) return;
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      if (images.length > 10) {
        _showStatusTop("Maksimum 10 fotoğraf seçebilirsin.");
      }
      setState(() {
        _selectedImages =
            images.take(10).map((xfile) => File(xfile.path)).toList();
      });
    }
  }

  // --- VALIDATE AND SHARE ---
  void _validateAndShare() async {
    if (_isLoading) return;

    String title = _controllers['Başlık (Zorunlu)']!.text.trim();
    Map<String, String> specs = {};
    _controllers.forEach((key, controller) {
      if (key != 'Başlık (Zorunlu)' && controller.text.isNotEmpty) {
        specs[key] = controller.text.trim();
      }
    });

    if (title.isEmpty) {
      _showStatusTop("Bir başlık yaz!");
      return;
    }
    if (_selectedImages.isEmpty) {
      _showStatusTop("En az 1 fotoğraf yüklemelisin!");
      return;
    }
    if (specs.length < 3) {
      _showStatusTop("En az 3 sistem özelliği girmelisin.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      String folderName =
          "${_dbService.currentUid}_${DateTime.now().millisecondsSinceEpoch}";
      List<String> imageUrls =
          await _dbService.uploadImages(_selectedImages, folderName);
      await _dbService.uploadSetup(title, specs, imageUrls);

      if (mounted) {
        _showStatusTop("Sistemin başarıyla paylaşıldı!", isError: false);
        Future.delayed(const Duration(milliseconds: 1000), () {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const MainWrapper()),
            (route) => false,
          );
        });
      }
    } catch (e) {
      _showStatusTop("Hata oluştu: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("YENİ SETUP")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Fotoğraf Seçim Alanı
            GestureDetector(
              onTap: _pickImages,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: SetuplyTheme.glassColor,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: _selectedImages.isEmpty
                        ? SetuplyTheme.accentPurple.withOpacity(0.3)
                        : SetuplyTheme.accentPurple,
                    width: 2,
                  ),
                ),
                child: _selectedImages.isEmpty
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_outlined,
                              size: 50, color: SetuplyTheme.accentPurple),
                          SizedBox(height: 10),
                          Text("Fotoğrafları Seç (Max 10)",
                              style: TextStyle(color: Colors.white54)),
                        ],
                      )
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.all(10),
                        itemCount: _selectedImages.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(15),
                                  child: Image.file(_selectedImages[index],
                                      width: 140,
                                      height: 140,
                                      fit: BoxFit.cover),
                                ),
                                if (!_isLoading)
                                  Positioned(
                                    top: 5,
                                    right: 5,
                                    child: GestureDetector(
                                      onTap: () => setState(() =>
                                          _selectedImages.removeAt(index)),
                                      child: Container(
                                        decoration: const BoxDecoration(
                                            color: Colors.black54,
                                            shape: BoxShape.circle),
                                        child: const Icon(Icons.close,
                                            color: Colors.white, size: 20),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ),
            const SizedBox(height: 25),

            // TextField'lar
            ..._controllers.entries.map((entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 15),
                  child: TextField(
                    controller: entry.value,
                    enabled: !_isLoading,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: entry.key,
                      labelStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: SetuplyTheme.glassColor,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(
                            color: SetuplyTheme.accentPurple, width: 1.5),
                      ),
                    ),
                  ),
                )),

            const SizedBox(height: 10),

            // Paylaş Butonu
            ElevatedButton(
              onPressed: _validateAndShare,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    _isLoading ? Colors.white10 : SetuplyTheme.accentPurple,
                minimumSize: const Size(double.infinity, 60),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                elevation: _isLoading ? 0 : 10,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 25,
                      width: 25,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Text("SİSTEMİ YAYINLA",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white)),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
}
