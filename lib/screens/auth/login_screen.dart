import 'package:flutter/material.dart';
import '../../../services/auth_service.dart';
import '../../../theme/app_theme.dart';
import '../main_wrapper.dart';
// BURAYA ANA SAYFANIN (NAVBAR/MAINSCREEN) IMPORTUNU EKLE
// Örn: import '../../main_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  final AuthService _authService = AuthService();

  bool isLogin = true;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.bolt_rounded,
                  size: 80, color: SetuplyTheme.accentPurple),
              const SizedBox(height: 20),
              Text(
                isLogin ? "HOŞ GELDİN" : "SETUPIFY'e KATIL",
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.white),
              ),
              const SizedBox(height: 10),
              const Text("Sadece kullanıcı adınla hızlıca bağlan.",
                  style: TextStyle(color: Colors.white38, fontSize: 13)),
              const SizedBox(height: 40),
              _authField(
                  _usernameController, "Kullanıcı Adı", Icons.person_outline),
              const SizedBox(height: 15),
              _authField(_passController, "Şifre", Icons.lock_outline,
                  obscure: true),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleAuth,
                style: ElevatedButton.styleFrom(
                  backgroundColor: SetuplyTheme.accentPurple,
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Text(isLogin ? "GİRİŞ YAP" : "KAYDOL VE BAŞLA",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => setState(() => isLogin = !isLogin),
                child: Text(
                  isLogin
                      ? "Hesabın yok mu? Kaydol"
                      : "Zaten üye misin? Giriş yap",
                  style: const TextStyle(color: Colors.white54),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  void _showDynamicIsland(String msg, {bool isError = true}) {
    OverlayState? overlayState = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 60,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: TweenAnimationBuilder(
            duration: const Duration(milliseconds: 600),
            curve: Curves.elasticOut,
            tween: Tween<double>(begin: 0.0, end: 1.0),
            builder: (context, double value, child) {
              return Transform.scale(
                scale: value,
                child: Opacity(
                  opacity: value.clamp(0.0, 1.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 15),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A).withOpacity(0.9),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color: isError
                            ? Colors.redAccent.withOpacity(0.5)
                            : SetuplyTheme.accentPurple.withOpacity(0.5),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (isError
                                  ? Colors.redAccent
                                  : SetuplyTheme.accentPurple)
                              .withOpacity(0.2),
                          blurRadius: 15,
                          spreadRadius: 2,
                        )
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isError ? Icons.error_outline : Icons.bolt_rounded,
                          color: isError
                              ? Colors.redAccent
                              : SetuplyTheme.accentPurple,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            msg,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );

    overlayState.insert(overlayEntry);
    Future.delayed(const Duration(seconds: 3), () => overlayEntry.remove());
  }

  // --- AUTH MANTIĞI DÜZELTİLDİ ---
  Future<void> _handleAuth() async {
    String username = _usernameController.text.trim();
    String password = _passController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      _showDynamicIsland("Alanları boş bırakma!");
      return;
    }

    setState(() => _isLoading = true);

    String? result;
    if (isLogin) {
      result = await _authService.signIn(username, password);
    } else {
      result = await _authService.signUp(username, password);
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result == null) {
      // 1. BAŞARI BİLDİRİMİNİ GÖSTER
      _showDynamicIsland(isLogin ? "Giriş başarılı!" : "Hesap oluşturuldu!",
          isError: false);

      // 2. NAVİGASYONU TEMİZLE VE ANA SAYFAYI EN ÜSTE GETİR
      // Yarım saniye bekle ki kullanıcı "Giriş Başarılı" yazısını görsün
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          // Bu kod Login ekranını ve diğer tüm geçmişi siler,
          // MainWrapper'ı (ana sayfanı) temiz bir şekilde en üste koyar.
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const MainWrapper()),
            (route) => false,
          );
        }
      });
    } else {
      // HATA VARSA GÖSTER
      _showDynamicIsland("Hata: $result", isError: true);
    }
  }

  Widget _authField(
      TextEditingController controller, String label, IconData icon,
      {bool obscure = false}) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: SetuplyTheme.accentPurple),
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white38),
        filled: true,
        fillColor: SetuplyTheme.deepPurple,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Colors.white10)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide:
                const BorderSide(color: SetuplyTheme.accentPurple, width: 1)),
      ),
    );
  }
}
