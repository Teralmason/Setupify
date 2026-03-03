import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // Bu paket şart
import 'firebase_options.dart'; // flutterfire configure sonrası gelen dosya
import 'screens/main_wrapper.dart';
import 'screens/auth/login_screen.dart';
import 'theme/app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  // 1. Flutter'ın widget sistemini hazırla
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Firebase'i başlat (Hata aldığın yer burasıydı)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const SetuplyApp());
}

class SetuplyApp extends StatelessWidget {
  const SetuplyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: SetuplyTheme.darkTheme,
      // 3. Kullanıcı oturumunu dinle
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return const MainWrapper();
          } else {
            return const LoginScreen();
          }
        },
      ),
    );
  }
}
