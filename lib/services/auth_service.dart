import 'dart:async';
import 'dart:io';
import 'package:pocketbase/pocketbase.dart';
import '../models/user.dart';
import 'database_service.dart';

/// Types d'erreurs d'authentification
enum AuthErrorType {
  invalidCredentials, // Téléphone ou PIN incorrect
  network,            // Pas de connexion internet
  serverDown,         // Serveur inaccessible
  timeout,            // Requête trop longue
  phoneAlreadyExists, // Numéro déjà utilisé
  unknown,            // Erreur inconnue
}

/// Résultat d'une tentative de connexion
class LoginResult {
  final bool success;
  final AuthErrorType? errorType;
  final String? errorMessage;

  LoginResult.success() : success = true, errorType = null, errorMessage = null;
  
  LoginResult.failure(this.errorType, [this.errorMessage]) : success = false;

  /// Message utilisateur friendly
  String get userMessage {
    if (success) return '';
    switch (errorType) {
      case AuthErrorType.invalidCredentials:
        return 'Numéro ou code PIN incorrect';
      case AuthErrorType.network:
        return 'Pas de connexion internet. Vérifiez votre connexion.';
      case AuthErrorType.serverDown:
        return 'Serveur inaccessible. Réessayez plus tard.';
      case AuthErrorType.timeout:
        return 'Le serveur met trop de temps à répondre. Réessayez.';
      case AuthErrorType.phoneAlreadyExists:
        return 'Ce numéro de téléphone est déjà utilisé';
      case AuthErrorType.unknown:
      case null:
        return 'Une erreur est survenue. Réessayez.';
    }
  }
}

/// Résultat d'une tentative d'inscription
class RegisterResult {
  final bool success;
  final AuthErrorType? errorType;
  final String? errorMessage;

  RegisterResult.success() : success = true, errorType = null, errorMessage = null;
  
  RegisterResult.failure(this.errorType, [this.errorMessage]) : success = false;

  String get userMessage {
    if (success) return '';
    switch (errorType) {
      case AuthErrorType.phoneAlreadyExists:
        return 'Ce numéro de téléphone est déjà utilisé';
      case AuthErrorType.network:
        return 'Pas de connexion internet. Vérifiez votre connexion.';
      case AuthErrorType.serverDown:
        return 'Serveur inaccessible. Réessayez plus tard.';
      case AuthErrorType.timeout:
        return 'Le serveur met trop de temps à répondre. Réessayez.';
      case AuthErrorType.invalidCredentials:
      case AuthErrorType.unknown:
      case null:
        return 'Une erreur est survenue. Réessayez.';
    }
  }
}

/// Service d'authentification avec singleton pattern
/// Gère la connexion, déconnexion et session de l'agent
class AuthService {
  // Singleton instance
  static final AuthService _instance = AuthService._internal();
  static AuthService get instance => _instance;

  AuthService._internal();

  User? _currentUser;
  
  /// Timeout pour les requêtes auth (en secondes)
  static const int authTimeout = 15;

  /// Utilisateur actuellement connecté
  User? get currentUser => _currentUser;

  /// Vérifie si un utilisateur est connecté
  bool get isLoggedIn => _currentUser != null;

  /// Accès au client PocketBase via DatabaseService
  PocketBase get _pb => DatabaseService.instance.pb;

  /// Connecte un utilisateur avec numéro de téléphone et PIN
  /// Le téléphone est utilisé comme username dans PocketBase
  /// 
  /// Requirements: 1.2, 1.3
  Future<LoginResult> login(String phone, String pin) async {
    try {
      // Normaliser le numéro (enlever espaces)
      final normalizedPhone = phone.replaceAll(' ', '');
      
      final authData = await _pb.collection('users').authWithPassword(
        '$normalizedPhone@gestagent.com', // username = téléphone
        pin,
      ).timeout(const Duration(seconds: authTimeout));

      _currentUser = User.fromJson(authData.record.toJson());
      DatabaseService.instance.setCurrentUser(_currentUser!.id);
      return LoginResult.success();
      
    } on TimeoutException {
      _currentUser = null;
      return LoginResult.failure(AuthErrorType.timeout);
      
    } on SocketException {
      _currentUser = null;
      return LoginResult.failure(AuthErrorType.network);
      
    } on ClientException catch (e) {
      _currentUser = null;
      
      // Serveur inaccessible (statusCode 0 ou erreur socket)
      if (e.statusCode == 0 || e.originalError is SocketException) {
        return LoginResult.failure(AuthErrorType.serverDown);
      }
      
      // Identifiants invalides (400 ou 401)
      if (e.statusCode == 400 || e.statusCode == 401) {
        return LoginResult.failure(AuthErrorType.invalidCredentials);
      }
      
      return LoginResult.failure(AuthErrorType.unknown, e.toString());
      
    } catch (e) {
      _currentUser = null;
      return LoginResult.failure(AuthErrorType.unknown, e.toString());
    }
  }

  /// Inscrit un nouvel utilisateur
  /// Le téléphone devient le username, le PIN devient le password
  Future<RegisterResult> register({
    required String firstName,
    required String lastName,
    required String phone,
    required String pin,
  }) async {
    try {
      final normalizedPhone = phone.replaceAll(' ', '');
      final fullName = '$firstName $lastName';
      
      // Créer le compte utilisateur
      await _pb.collection('users').create(body: {
        'username': normalizedPhone,
        'password': pin,
        'passwordConfirm': pin,
        'name': fullName,
        'email': '$normalizedPhone@gestagent.com', // Email fictif requis par PocketBase
      }).timeout(const Duration(seconds: authTimeout));

      return RegisterResult.success();
      
    } on TimeoutException {
      return RegisterResult.failure(AuthErrorType.timeout);
      
    } on SocketException {
      return RegisterResult.failure(AuthErrorType.network);
      
    } on ClientException catch (e) {
      if (e.statusCode == 0 || e.originalError is SocketException) {
        return RegisterResult.failure(AuthErrorType.serverDown);
      }
      
      // Vérifier si c'est une erreur de doublon (username/phone déjà utilisé)
      final responseData = e.response;
      if (responseData['data'] != null) {
        final data = responseData['data'] as Map<String, dynamic>;
        if (data.containsKey('username')) {
          return RegisterResult.failure(AuthErrorType.phoneAlreadyExists);
        }
      }
      
      return RegisterResult.failure(AuthErrorType.unknown, e.toString());
      
    } catch (e) {
      return RegisterResult.failure(AuthErrorType.unknown, e.toString());
    }
  }

  /// Déconnecte l'utilisateur courant
  /// 
  /// Requirements: 1.4
  Future<void> logout() async {
    _pb.authStore.clear();
    _currentUser = null;
  }

  /// Vérifie et restaure la session existante
  /// Retourne true si une session valide existe
  /// 
  /// Requirements: 1.4
  Future<bool> checkSession() async {
    if (_pb.authStore.isValid && _pb.authStore.record != null) {
      try {
        // Rafraîchir le token pour vérifier qu'il est toujours valide
        await _pb.collection('users').authRefresh()
            .timeout(const Duration(seconds: authTimeout));
        
        if (_pb.authStore.record != null) {
          _currentUser = User.fromJson(_pb.authStore.record!.toJson());
          DatabaseService.instance.setCurrentUser(_currentUser!.id);
          return true;
        }
      } catch (e) {
        // Session expirée, invalide, ou erreur réseau
        _pb.authStore.clear();
        _currentUser = null;
      }
    }
    return false;
  }
}
