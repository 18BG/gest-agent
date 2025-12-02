import 'dart:async';
import 'dart:io';
import 'package:pocketbase/pocketbase.dart';
import '../models/client.dart';
import '../models/operation.dart';
import '../models/payment.dart';

/// Types d'erreurs possibles
enum DatabaseErrorType {
  network,      // Pas de connexion internet
  timeout,      // Requête trop longue
  serverDown,   // Serveur inaccessible
  unauthorized, // Non autorisé (token expiré)
  notFound,     // Ressource non trouvée
  validation,   // Erreur de validation
  unknown,      // Erreur inconnue
}

/// Exception personnalisée pour les erreurs de base de données
class DatabaseException implements Exception {
  final DatabaseErrorType type;
  final String message;
  final dynamic originalError;

  DatabaseException({
    required this.type,
    required this.message,
    this.originalError,
  });

  @override
  String toString() => message;

  /// Message utilisateur friendly
  String get userMessage {
    switch (type) {
      case DatabaseErrorType.network:
        return 'Pas de connexion internet. Vérifiez votre connexion.';
      case DatabaseErrorType.timeout:
        return 'Le serveur met trop de temps à répondre. Réessayez.';
      case DatabaseErrorType.serverDown:
        return 'Serveur inaccessible. Réessayez plus tard.';
      case DatabaseErrorType.unauthorized:
        return 'Session expirée. Veuillez vous reconnecter.';
      case DatabaseErrorType.notFound:
        return 'Ressource non trouvée.';
      case DatabaseErrorType.validation:
        return 'Données invalides.';
      case DatabaseErrorType.unknown:
        return 'Une erreur est survenue. Réessayez.';
    }
  }
}

/// Service de base de données avec singleton pattern
/// Gère toutes les opérations CRUD avec PocketBase
class DatabaseService {
  // Singleton instance
  static final DatabaseService _instance = DatabaseService._internal();
  static DatabaseService get instance => _instance;

  DatabaseService._internal();

  late PocketBase _pb;
  String? _currentUserId;
  
  /// Timeout par défaut pour les requêtes (en secondes)
  static const int defaultTimeout = 15;

  /// Initialise la connexion PocketBase
  Future<void> init(String url) async {
    _pb = PocketBase(url);
  }
  
  /// Gère les erreurs et les convertit en DatabaseException
  DatabaseException _handleError(dynamic error) {
    // Erreur réseau / pas d'internet
    if (error is SocketException) {
      return DatabaseException(
        type: DatabaseErrorType.network,
        message: 'Erreur réseau',
        originalError: error,
      );
    }
    
    // Timeout
    if (error is TimeoutException) {
      return DatabaseException(
        type: DatabaseErrorType.timeout,
        message: 'Timeout',
        originalError: error,
      );
    }
    
    // Erreur PocketBase
    if (error is ClientException) {
      // Serveur inaccessible
      if (error.statusCode == 0 || error.originalError is SocketException) {
        return DatabaseException(
          type: DatabaseErrorType.serverDown,
          message: 'Serveur inaccessible',
          originalError: error,
        );
      }
      
      // Non autorisé
      if (error.statusCode == 401 || error.statusCode == 403) {
        return DatabaseException(
          type: DatabaseErrorType.unauthorized,
          message: 'Non autorisé',
          originalError: error,
        );
      }
      
      // Non trouvé
      if (error.statusCode == 404) {
        return DatabaseException(
          type: DatabaseErrorType.notFound,
          message: 'Non trouvé',
          originalError: error,
        );
      }
      
      // Erreur de validation
      if (error.statusCode == 400) {
        return DatabaseException(
          type: DatabaseErrorType.validation,
          message: 'Données invalides',
          originalError: error,
        );
      }
    }
    
    // Erreur inconnue
    return DatabaseException(
      type: DatabaseErrorType.unknown,
      message: 'Erreur inconnue',
      originalError: error,
    );
  }
  
  /// Exécute une requête avec timeout
  Future<T> _withTimeout<T>(Future<T> Function() request) async {
    try {
      return await request().timeout(
        const Duration(seconds: defaultTimeout),
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Définit l'utilisateur courant (après login)
  void setCurrentUser(String userId) {
    _currentUserId = userId;
  }

  /// Récupère l'ID de l'utilisateur courant
  String? get currentUserId => _currentUserId;

  /// Accès au client PocketBase (pour auth_service)
  PocketBase get pb => _pb;

  // ============================================
  // OPERATIONS CRUD
  // ============================================

  /// Récupère les opérations de l'utilisateur courant (paginées pour l'affichage)
  /// Triées par date décroissante (plus récente en premier)
  /// [limit] : nombre d'opérations à récupérer (défaut: 50)
  Future<List<Operation>> getOperations({int limit = 50}) async {
    if (_currentUserId == null) return [];

    return _withTimeout(() async {
      final records = await _pb.collection('operations').getList(
        page: 1,
        perPage: limit,
        filter: 'userId = "$_currentUserId"',
        sort: '-created',
      );
      return records.items.map((r) => Operation.fromJson(r.toJson())).toList();
    });
  }
  
  /// Crée une nouvelle opération
  Future<Operation> createOperation(Operation operation) async {
    return _withTimeout(() async {
      final record = await _pb.collection('operations').create(
        body: operation.toJson(),
      );
      return Operation.fromJson(record.toJson());
    });
  }

  /// Met à jour une opération existante
  Future<Operation> updateOperation(Operation operation) async {
    return _withTimeout(() async {
      final record = await _pb.collection('operations').update(
        operation.id,
        body: operation.toJson(),
      );
      return Operation.fromJson(record.toJson());
    });
  }

  /// Supprime une opération
  Future<void> deleteOperation(String id) async {
    return _withTimeout(() async {
      await _pb.collection('operations').delete(id);
    });
  }

  // ============================================
  // CLIENTS CRUD
  // ============================================

  /// Récupère tous les clients de l'utilisateur courant
  /// Triés par dette décroissante (plus grande dette en premier)
  Future<List<Client>> getClients() async {
    if (_currentUserId == null) return [];

    return _withTimeout(() async {
      final records = await _pb.collection('clients').getFullList(
        filter: 'userId = "$_currentUserId"',
        sort: '-totalDebt',
      );
      return records.map((r) => Client.fromJson(r.toJson())).toList();
    });
  }

  /// Récupère un client par son ID
  Future<Client?> getClient(String id) async {
    try {
      return await _withTimeout(() async {
        final record = await _pb.collection('clients').getOne(id);
        return Client.fromJson(record.toJson());
      });
    } on DatabaseException catch (e) {
      if (e.type == DatabaseErrorType.notFound) {
        return null;
      }
      rethrow;
    }
  }

  /// Crée un nouveau client
  Future<Client> createClient(Client client) async {
    return _withTimeout(() async {
      final record = await _pb.collection('clients').create(
        body: client.toJson(),
      );
      return Client.fromJson(record.toJson());
    });
  }

  /// Met à jour un client existant
  Future<Client> updateClient(Client client) async {
    return _withTimeout(() async {
      final record = await _pb.collection('clients').update(
        client.id,
        body: client.toJson(),
      );
      return Client.fromJson(record.toJson());
    });
  }

  /// Met à jour la dette d'un client
  Future<void> updateClientDebt(String clientId, double newDebt) async {
    return _withTimeout(() async {
      await _pb.collection('clients').update(
        clientId,
        body: {'totalDebt': newDebt},
      );
    });
  }

  /// Supprime un client
  Future<void> deleteClient(String id) async {
    return _withTimeout(() async {
      await _pb.collection('clients').delete(id);
    });
  }

  // ============================================
  // PAYMENTS CRUD
  // ============================================

  /// Récupère tous les paiements d'un client
  Future<List<Payment>> getPaymentsForClient(String clientId) async {
    return _withTimeout(() async {
      final records = await _pb.collection('payments').getFullList(
        filter: 'clientId = "$clientId"',
        sort: '-created',
      );
      return records.map((r) => Payment.fromJson(r.toJson())).toList();
    });
  }

  /// Crée un nouveau paiement et met à jour la dette du client
  Future<Payment> createPayment(Payment payment) async {
    return _withTimeout(() async {
      // Créer le paiement
      final record = await _pb.collection('payments').create(
        body: payment.toJson(),
      );

      // Récupérer le client et mettre à jour sa dette
      final client = await getClient(payment.clientId);
      if (client != null) {
        final newDebt = (client.totalDebt - payment.amount).clamp(0.0, double.infinity);
        await updateClientDebt(payment.clientId, newDebt);
      }

      return Payment.fromJson(record.toJson());
    });
  }

  /// Supprime un paiement
  Future<void> deletePayment(String id) async {
    return _withTimeout(() async {
      await _pb.collection('payments').delete(id);
    });
  }

  // ============================================
  // BALANCES (UV et Espèces) - Calculés côté serveur
  // ============================================

  /// Récupère les soldes depuis la view PocketBase (calcul côté serveur)
  /// 
  /// La view `user_balances` calcule automatiquement:
  /// - uvBalance: solde UV de l'agent
  /// - cashBalance: solde espèces de l'agent  
  /// - totalDebts: total des dettes clients
  /// 
  /// Logique des soldes (du point de vue de l'agent):
  /// - Dépôt/Transfert/Vente Crédit: UV -montant, Espèces +montant (si payé)
  /// - Retrait UV: UV +montant, Espèces -montant
  Future<Map<String, double>> getBalances() async {
    if (_currentUserId == null) {
      return {'uv': 0, 'cash': 0};
    }

    return _withTimeout(() async {
      final record = await _pb.collection('user_balances').getOne(_currentUserId!);
      final data = record.toJson();
      
      return {
        'uv': (data['uvBalance'] as num?)?.toDouble() ?? 0,
        'cash': (data['cashBalance'] as num?)?.toDouble() ?? 0,
      };
    });
  }

  /// Récupère le total des dettes depuis la view PocketBase (calcul côté serveur)
  Future<double> getTotalDebts() async {
    if (_currentUserId == null) return 0;

    return _withTimeout(() async {
      final record = await _pb.collection('user_balances').getOne(_currentUserId!);
      final data = record.toJson();
      return (data['totalDebts'] as num?)?.toDouble() ?? 0;
    });
  }
  
  /// Récupère tous les soldes en une seule requête (optimisé)
  Future<({double uv, double cash, double debts})> getAllBalances() async {
    if (_currentUserId == null) {
      return (uv: 0.0, cash: 0.0, debts: 0.0);
    }

    return _withTimeout(() async {
      final record = await _pb.collection('user_balances').getOne(_currentUserId!);
      final data = record.toJson();
      
      return (
        uv: (data['uvBalance'] as num?)?.toDouble() ?? 0.0,
        cash: (data['cashBalance'] as num?)?.toDouble() ?? 0.0,
        debts: (data['totalDebts'] as num?)?.toDouble() ?? 0.0,
      );
    });
  }
  
  /// Vérifie si le serveur est accessible
  Future<bool> checkServerHealth() async {
    try {
      await _withTimeout(() async {
        await _pb.health.check();
      });
      return true;
    } catch (e) {
      return false;
    }
  }
}
