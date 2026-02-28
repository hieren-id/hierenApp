import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'api_service.dart';

class AuthService {
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyUserId = 'user_id';
  static const String _keyUsername = 'username';
  static const String _keyEmail = 'email';
  static const String _keyFullName = 'full_name';

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  // Get current logged in user
  static Future<User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;

    if (!isLoggedIn) return null;

    final userId = prefs.getInt(_keyUserId);
    final username = prefs.getString(_keyUsername);
    final email = prefs.getString(_keyEmail);
    final fullName = prefs.getString(_keyFullName);

    if (userId == null || username == null || email == null) {
      return null;
    }

    return User(
      id: userId,
      username: username,
      email: email,
      fullName: fullName,
      createdAt: DateTime.now().toString(),
    );
  }

  // Login
  static Future<Map<String, dynamic>> login(
    String username,
    String password,
  ) async {
    try {
      final result = await ApiService.login(username, password);

      if (result['success'] == true) {
        // Save user data to SharedPreferences
        final userData = result['data'];
        final prefs = await SharedPreferences.getInstance();

        await prefs.setBool(_keyIsLoggedIn, true);
        await prefs.setInt(_keyUserId, int.parse(userData['id'].toString()));
        await prefs.setString(_keyUsername, userData['username']);
        await prefs.setString(_keyEmail, userData['email']);
        if (userData['full_name'] != null) {
          await prefs.setString(_keyFullName, userData['full_name']);
        }

        print('✅ User logged in: ${userData['username']}');
      }

      return result;
    } catch (e) {
      return {'success': false, 'message': 'Login failed: $e'};
    }
  }

  // Register
  static Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    String? fullName,
  }) async {
    try {
      final result = await ApiService.register(
        username: username,
        email: email,
        password: password,
        fullName: fullName,
      );

      return result;
    } catch (e) {
      return {'success': false, 'message': 'Registration failed: $e'};
    }
  }

  // Logout
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    print('✅ User logged out');
  }

  // Get user ID
  static Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyUserId);
  }

  // Get username
  static Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUsername);
  }
}
