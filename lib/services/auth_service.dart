import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String _formatEmail(String username) =>
      "${username.trim().toLowerCase()}@setuply.com";

  // KAYIT OL
  Future<String?> signUp(String username, String password) async {
    try {
      String email = _formatEmail(username);
      UserCredential res = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);

      // Auth Profilini Güncelle
      await res.user!.updateDisplayName(username);

      // FIRESTORE'A YAZ
      await _db.collection('users').doc(res.user!.uid).set({
        'uid': res.user!.uid,
        'userName': username,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
        'photoURL': "",
      });

      return null; // Başarılı
    } on FirebaseAuthException catch (e) {
      // Anlaşılır hata mesajları dönelim
      if (e.code == 'email-already-in-use') {
        return "Bu kullanıcı adı zaten alınmış.";
      }
      if (e.code == 'weak-password') return "Şifre çok zayıf.";
      return e.message ?? e.code;
    } catch (e) {
      return e.toString();
    }
  }

  // GİRİŞ YAP
  Future<String?> signIn(String username, String password) async {
    try {
      String email = _formatEmail(username);
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null; // Başarılı
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') return "Kullanıcı bulunamadı.";
      if (e.code == 'wrong-password') return "Hatalı şifre.";
      if (e.code == 'invalid-credential') return "Giriş bilgileri hatalı.";
      return e.message ?? e.code;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> signOut() async => await _auth.signOut();
}
