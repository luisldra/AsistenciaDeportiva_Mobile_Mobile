import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  bool _isAuthenticated = false;
  String? _token;
  Map<String, dynamic>? _usuario;

  bool get isAuthenticated => _isAuthenticated;
  Map<String, dynamic>? get usuario => _usuario;

  Future<void> checkAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token != null) {
      _token = token;
      final usuarioNombre = prefs.getString('usuario_nombre');
      final usuarioEmail = prefs.getString('usuario_email');
      final usuarioId = prefs.getInt('usuario_id');
      _usuario = {'id': usuarioId, 'nombre': usuarioNombre, 'email': usuarioEmail};
      _isAuthenticated = true;
      notifyListeners();
    }
  }

  Future<void> login(String email, String password) async {
    final data = await ApiService.post('/login', {'email': email, 'password': password});
    _token = data['token'];
    _usuario = data['usuario'];
    _isAuthenticated = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', _token!);
    await prefs.setString('usuario_nombre', _usuario!['nombre']);
    await prefs.setString('usuario_email', _usuario!['email']);
    await prefs.setInt('usuario_id', _usuario!['id']);
    notifyListeners();
  }


  Future<void> setSession(String token, Map<String, dynamic> usuario) async {
    _token = token;
    _usuario = usuario;
    _isAuthenticated = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', _token!);
    await prefs.setString('usuario_nombre', _usuario!['nombre']);
    await prefs.setString('usuario_email', _usuario!['email']);
    await prefs.setInt('usuario_id', _usuario!['id']);
    notifyListeners();
  }

  Future<void> register(String nombre, String email, String password) async {
    await ApiService.post('/register', {'nombre': nombre, 'email': email, 'password': password});
  }

  Future<void> logout() async {
    _isAuthenticated = false;
    _token = null;
    _usuario = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    notifyListeners();
  }
}