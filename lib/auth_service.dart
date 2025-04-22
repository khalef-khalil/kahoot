import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database_helper.dart';
import 'models.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  User? _currentUser;
  
  factory AuthService() => _instance;
  
  AuthService._internal();
  
  User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  
  // Load the logged-in user from shared preferences
  Future<bool> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    
    if (userId != null) {
      final userMap = await _dbHelper.getUserById(userId);
      if (userMap != null) {
        _currentUser = User.fromMap(userMap);
        await _dbHelper.updateUserLastLogin(userId);
        return true;
      }
    }
    
    return false;
  }
  
  // Register a new user
  Future<User?> register(String username, String email, String password) async {
    // Check if username already exists
    final existingUsername = await _dbHelper.getUserByUsername(username);
    if (existingUsername != null) {
      throw Exception('Username already taken');
    }
    
    // Check if email already exists
    final existingEmail = await _dbHelper.getUserByEmail(email);
    if (existingEmail != null) {
      throw Exception('Email already registered');
    }
    
    // Hash the password
    final passwordHash = _hashPassword(password);
    
    // Create the user
    final now = DateTime.now();
    final userId = await _dbHelper.registerUser({
      'username': username,
      'email': email,
      'password_hash': passwordHash,
      'created_at': now.toIso8601String(),
      'last_login': now.toIso8601String(),
    });
    
    // Get the created user
    final userMap = await _dbHelper.getUserById(userId);
    if (userMap != null) {
      final user = User.fromMap(userMap);
      return user;
    }
    
    return null;
  }
  
  // Login a user
  Future<User?> login(String usernameOrEmail, String password) async {
    Map<String, dynamic>? userMap;
    
    // Check if input is email or username
    if (usernameOrEmail.contains('@')) {
      userMap = await _dbHelper.getUserByEmail(usernameOrEmail);
    } else {
      userMap = await _dbHelper.getUserByUsername(usernameOrEmail);
    }
    
    if (userMap == null) {
      throw Exception('User not found');
    }
    
    // Verify password
    final passwordHash = _hashPassword(password);
    if (passwordHash != userMap['password_hash']) {
      throw Exception('Invalid password');
    }
    
    // Update last login time
    await _dbHelper.updateUserLastLogin(userMap['id']);
    
    // Set the current user
    _currentUser = User.fromMap(userMap);
    
    // Save user ID to preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('user_id', _currentUser!.id!);
    
    return _currentUser;
  }
  
  // Logout the current user
  Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
  }
  
  // Hash a password
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
} 