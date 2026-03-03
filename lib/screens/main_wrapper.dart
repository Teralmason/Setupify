import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'upload_screen.dart';
import 'ai_chat_screen.dart';
import 'profile_screen.dart';
import 'community_screen.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});
  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _selectedIndex =
      2; // Home sekmesi (indeks 2) varsayılan olarak açık başlasın

  // YENİ SIRALAMA: AI > Topluluk > Home > Upload > Profil
  final List<Widget> _pages = [
    const AIChatScreen(), // 0
    const CommunityScreen(), // 1
    const HomeScreen(), // 2 (Merkez)
    const UploadScreen(), // 3
    const ProfileScreen(), // 4
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      // Sayfa durumlarını (scroll pozisyonu vb.) korumak için IndexedStack
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(15, 0, 15, 25),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(35),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              height: 75,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(35),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(5, (index) => _navItem(index)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index) {
    // İkon sıralaması listeye göre güncellendi
    final icons = [
      Icons.auto_awesome, // AI
      Icons.forum_rounded, // Community
      Icons.grid_view_rounded, // Home
      Icons.add_box_rounded, // Upload
      Icons.person_rounded // Profile
    ];

    bool isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutBack,
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Seçili ikonu yukarı kaydıran ve rengini değiştiren animasyon
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              transform: Matrix4.translationValues(0, isSelected ? -5 : 0, 0),
              child: Icon(
                icons[index],
                color: isSelected ? SetuplyTheme.accentPurple : Colors.white24,
                size: isSelected ? 30 : 24,
              ),
            ),
            // Seçili ikonun altına küçük bir parlama noktası
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.only(top: 4),
              height: 4,
              width: isSelected ? 4 : 0,
              decoration: BoxDecoration(
                color: SetuplyTheme.accentPurple,
                shape: BoxShape.circle,
                boxShadow: [
                  if (isSelected)
                    BoxShadow(
                      color: SetuplyTheme.accentPurple.withValues(alpha: 0.8),
                      blurRadius: 10,
                      spreadRadius: 2,
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
