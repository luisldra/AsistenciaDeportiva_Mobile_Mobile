import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import '../config.dart';

class GoogleAuthService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
  serverClientId: '995938077388-i0leunddlfjprmdbrmdsuv8in68v10k2.apps.googleusercontent.com',
  );

  static Future<Map<String, dynamic>?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account == null) return null;

      final GoogleSignInAuthentication auth = await account.authentication;
      final String? idToken = auth.idToken;
      if (idToken == null) return null;

      final response = await http.post(
        Uri.parse('$baseUrl/auth/google'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'idToken': idToken}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('Error Google Sign In: $e');
      return null;
    }
  }

  static Future<void> signOut() async {
    await _googleSignIn.signOut();
  }
}