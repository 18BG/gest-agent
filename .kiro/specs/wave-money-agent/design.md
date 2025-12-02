# Design Document - Wave Money Agent

## Overview

Wave Money Agent est une application Flutter utilisant une architecture Clean simplifiée (sans use cases) avec Riverpod pour la gestion d'état, PocketBase comme backend, et Hive pour le cache offline. L'application privilégie la simplicité et la maintenabilité avec un code manuel plutôt que des annotations complexes.

## Choix Techniques Fondamentaux

### Pourquoi SANS annotations (json_serializable, riverpod_annotation) ?

**Décision : Code manuel pour la sérialisation et les providers**

**Justifications :**
1. **Compréhension totale** : Tu vois exactement ce qui se passe, pas de magie cachée
2. **Debugging facile** : Pas de fichiers .g.dart à régénérer constamment
3. **Contrôle total** : Tu peux customiser chaque aspect de la sérialisation
4. **Moins de dépendances** : Pas besoin de build_runner, freezed, json_annotation
5. **Performance** : Pas de génération de code à chaque modification

**Conséquence :** Plus de code à écrire manuellement, mais code plus clair et maintenable.

### Stack Technique Finale

**Frontend :**
- Flutter 3.24+
- Riverpod 2.x (classique, sans codegen)
- GoRouter pour la navigation
- Hive pour cache local (simple, rapide, sans annotations)
- Dio pour HTTP
- pdf + printing pour exports PDF
- csv pour exports CSV
- flutter_local_notifications pour notifications

**Backend :**
- PocketBase (auto-hébergé ou cloud)

**Collections PocketBase :**
- users (auth intégrée)
- clients
- operations
- payments

## Architecture

### Structure des Dossiers

```
lib/
├── main.dart                    # Point d'entrée
├── app.dart                     # Configuration app + router
├── core/
│   ├── constants/
│   │   ├── app_constants.dart   # URLs, limites, etc.
│   │   └── operation_types.dart # Enum types opérations
│   ├── exceptions/
│   │   ├── app_exception.dart   # Exception de base
│   │   └── network_exception.dart
│   ├── theme/
│   │   └── app_theme.dart       # Theme Material
│   ├── router/
│   │   └── app_router.dart      # GoRouter config
│   └── utils/
│       ├── date_formatter.dart
│       ├── currency_formatter.dart
│       └── validators.dart
├── data/
│   ├── datasources/
│   │   ├── pocketbase/
│   │   │   ├── pb_client.dart           # Client PocketBase singleton
│   │   │   ├── pb_auth_datasource.dart
│   │   │   ├── pb_operations_datasource.dart
│   │   │   ├── pb_clients_datasource.dart
│   │   │   └── pb_payments_datasource.dart
│   │   └── local/
│   │       ├── hive_service.dart        # Init Hive
│   │       ├── local_operations_datasource.dart
│   │       ├── local_clients_datasource.dart
│   │       └── local_auth_datasource.dart
│   └── repositories_impl/
│       ├── operation_repository_impl.dart
│       ├── client_repository_impl.dart
│       ├── payment_repository_impl.dart
│       ├── stats_repository_impl.dart
│       └── auth_repository_impl.dart
├── domain/
│   ├── models/
│   │   ├── wave_operation.dart
│   │   ├── client.dart
│   │   ├── client_payment.dart
│   │   ├── wave_stats.dart
│   │   └── user.dart
│   └── repositories/
│       ├── operation_repository.dart
│       ├── client_repository.dart
│       ├── payment_repository.dart
│       ├── stats_repository.dart
│       └── auth_repository.dart
└── presentation/
    ├── pages/
    │   ├── auth/
    │   │   ├── login_page.dart
    │   │   └── splash_page.dart
    │   ├── home/
    │   │   └── home_page.dart           # Dashboard
    │   ├── operations/
    │   │   ├── operations_list_page.dart
    │   │   └── add_operation_page.dart
    │   ├── clients/
    │   │   ├── clients_list_page.dart
    │   │   ├── client_details_page.dart
    │   │   └── add_client_page.dart
    │   ├── payments/
    │   │   └── add_payment_page.dart
    │   └── settings/
    │       └── settings_page.dart
    ├── providers/
    │   ├── auth_provider.dart
    │   ├── operations_provider.dart
    │   ├── clients_provider.dart
    │   ├── payments_provider.dart
    │   ├── stats_provider.dart
    │   └── filters_provider.dart
    └── widgets/
        ├── stat_card.dart
        ├── operation_card.dart
        ├── client_card.dart
        └── custom_button.dart
```


## Modèles de Données (Domain Models)

### 1. WaveOperation

```dart
class WaveOperation {
  final String id;
  final String clientId;
  final WaveOperationType type;
  final double amount;
  final bool isPaid;
  final DateTime createdAt;
  final DateTime? updatedAt;

  WaveOperation({
    required this.id,
    required this.clientId,
    required this.type,
    required this.amount,
    required this.isPaid,
    required this.createdAt,
    this.updatedAt,
  });

  // Sérialisation manuelle
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clientId': clientId,
      'type': type.name,
      'amount': amount,
      'isPaid': isPaid,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory WaveOperation.fromJson(Map<String, dynamic> json) {
    return WaveOperation(
      id: json['id'] as String,
      clientId: json['clientId'] as String,
      type: WaveOperationType.values.byName(json['type'] as String),
      amount: (json['amount'] as num).toDouble(),
      isPaid: json['isPaid'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt'] as String) 
          : null,
    );
  }

  WaveOperation copyWith({
    String? id,
    String? clientId,
    WaveOperationType? type,
    double? amount,
    bool? isPaid,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WaveOperation(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      isPaid: isPaid ?? this.isPaid,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
```

### 2. WaveOperationType (Enum)

```dart
enum WaveOperationType {
  venteCredit,
  transfert,
  depotUv,
  retraitUv;

  String get displayName {
    switch (this) {
      case WaveOperationType.venteCredit:
        return 'Vente Crédit';
      case WaveOperationType.transfert:
        return 'Transfert';
      case WaveOperationType.depotUv:
        return 'Dépôt UV';
      case WaveOperationType.retraitUv:
        return 'Retrait UV';
    }
  }
}
```

### 3. Client

```dart
class Client {
  final String id;
  final String name;
  final String phone;
  final double totalDebt;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Client({
    required this.id,
    required this.name,
    required this.phone,
    required this.totalDebt,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'totalDebt': totalDebt,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      totalDebt: (json['totalDebt'] as num).toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt'] as String) 
          : null,
    );
  }

  Client copyWith({
    String? id,
    String? name,
    String? phone,
    double? totalDebt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Client(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      totalDebt: totalDebt ?? this.totalDebt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
```

### 4. ClientPayment

```dart
class ClientPayment {
  final String id;
  final String clientId;
  final double amount;
  final DateTime createdAt;

  ClientPayment({
    required this.id,
    required this.clientId,
    required this.amount,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clientId': clientId,
      'amount': amount,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ClientPayment.fromJson(Map<String, dynamic> json) {
    return ClientPayment(
      id: json['id'] as String,
      clientId: json['clientId'] as String,
      amount: (json['amount'] as num).toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
```

### 5. WaveStats

```dart
class WaveStats {
  final double totalUv;
  final double totalEspece;
  final double totalClientDebts;

  WaveStats({
    required this.totalUv,
    required this.totalEspece,
    required this.totalClientDebts,
  });

  WaveStats copyWith({
    double? totalUv,
    double? totalEspece,
    double? totalClientDebts,
  }) {
    return WaveStats(
      totalUv: totalUv ?? this.totalUv,
      totalEspece: totalEspece ?? this.totalEspece,
      totalClientDebts: totalClientDebts ?? this.totalClientDebts,
    );
  }
}
```


## Règles Métier Wave - Implémentation

### Calcul des Effets d'Opération

```dart
class OperationEffects {
  final double uvDelta;
  final double especeDelta;
  final double debtDelta;

  OperationEffects({
    required this.uvDelta,
    required this.especeDelta,
    required this.debtDelta,
  });

  static OperationEffects calculate(WaveOperationType type, double amount, bool isPaid) {
    switch (type) {
      
      case WaveOperationType.venteCredit:
        return OperationEffects(
          uvDelta: amount,
          especeDelta: -amount,
          debtDelta: 0,
        );
      
      case WaveOperationType.transfert:
        return OperationEffects(
          uvDelta: -amount,
          especeDelta: isPaid ? amount : 0,
          debtDelta: isPaid ? 0 : amount,
        );
      
      case WaveOperationType.depotUv:
        return OperationEffects(
          uvDelta: -amount,
          especeDelta: isPaid ? amount : 0,
          debtDelta: isPaid ? 0 : amount,
        );
      
      case WaveOperationType.retraitUv:
        return OperationEffects(
          uvDelta: amount,
          especeDelta: -amount,
          debtDelta: 0,
        );
    }
  }
}
```

### Calcul des Statistiques

Les statistiques sont calculées dynamiquement en parcourant toutes les opérations et paiements :

```dart
class StatsCalculator {
  static WaveStats calculate(
    List<WaveOperation> operations,
    List<ClientPayment> payments,
    List<Client> clients,
  ) {
    double totalUv = 0;
    double totalEspece = 0;

    // Calculer UV et Espèces depuis les opérations
    for (final op in operations) {
      final effects = OperationEffects.calculate(op.type, op.amount, op.isPaid);
      totalUv += effects.uvDelta;
      totalEspece += effects.especeDelta;
    }

    // Ajouter les paiements aux espèces
    for (final payment in payments) {
      totalEspece += payment.amount;
    }

    // Sommer les dettes clients
    final totalClientDebts = clients.fold<double>(
      0,
      (sum, client) => sum + client.totalDebt,
    );

    return WaveStats(
      totalUv: totalUv,
      totalEspece: totalEspece,
      totalClientDebts: totalClientDebts,
    );
  }
}
```


## Repositories (Interfaces)

### OperationRepository

```dart
abstract class OperationRepository {
  Future<List<WaveOperation>> getAllOperations();
  Future<List<WaveOperation>> getOperationsByClient(String clientId);
  Future<WaveOperation> addOperation(WaveOperation operation);
  Future<WaveOperation> updateOperation(WaveOperation operation);
  Future<void> deleteOperation(String id);
  Stream<List<WaveOperation>> watchOperations();
}
```

### ClientRepository

```dart
abstract class ClientRepository {
  Future<List<Client>> getAllClients();
  Future<Client?> getClientById(String id);
  Future<Client> addClient(Client client);
  Future<Client> updateClient(Client client);
  Future<void> deleteClient(String id);
  Stream<List<Client>> watchClients();
}
```

### PaymentRepository

```dart
abstract class PaymentRepository {
  Future<List<ClientPayment>> getPaymentsByClient(String clientId);
  Future<ClientPayment> addPayment(ClientPayment payment);
  Stream<List<ClientPayment>> watchPayments();
}
```

### StatsRepository

```dart
abstract class StatsRepository {
  Future<WaveStats> getStats();
  Stream<WaveStats> watchStats();
}
```

### AuthRepository

```dart
abstract class AuthRepository {
  Future<User> signIn(String email, String password);
  Future<void> signOut();
  Future<User?> getCurrentUser();
  Future<void> refreshSession();
  Stream<User?> watchAuthState();
}
```

## Implémentation des Repositories

### OperationRepositoryImpl - Architecture

**Stratégie de synchronisation :**

1. **Lecture** : Toujours depuis le cache local (Hive) pour performance
2. **Écriture** : 
   - Écrire d'abord dans PocketBase (si online)
   - Puis mettre à jour le cache local
   - Si offline, écrire dans le cache avec flag `needsSync`
3. **Synchronisation** :
   - Au démarrage : pull depuis PocketBase vers Hive
   - Périodiquement : push les opérations `needsSync` vers PocketBase
   - Sur reconnexion : sync automatique

```dart
class OperationRepositoryImpl implements OperationRepository {
  final PbOperationsDatasource _remoteDatasource;
  final LocalOperationsDatasource _localDatasource;
  final Connectivity _connectivity;

  OperationRepositoryImpl(
    this._remoteDatasource,
    this._localDatasource,
    this._connectivity,
  );

  @override
  Future<List<WaveOperation>> getAllOperations() async {
    // Toujours lire depuis le cache local
    return await _localDatasource.getAll();
  }

  @override
  Future<WaveOperation> addOperation(WaveOperation operation) async {
    try {
      // Tenter d'écrire sur PocketBase
      final remoteOp = await _remoteDatasource.create(operation);
      
      // Sauvegarder dans le cache local
      await _localDatasource.save(remoteOp);
      
      // Mettre à jour la dette client et les stats
      await _updateClientDebt(operation);
      
      return remoteOp;
    } catch (e) {
      // Si offline ou erreur réseau, sauvegarder localement avec flag sync
      final localOp = operation.copyWith(needsSync: true);
      await _localDatasource.save(localOp);
      await _updateClientDebt(operation);
      return localOp;
    }
  }

  Future<void> _updateClientDebt(WaveOperation operation) async {
    final effects = OperationEffects.calculate(
      operation.type,
      operation.amount,
      operation.isPaid,
    );
    
    if (effects.debtDelta != 0) {
      // Mettre à jour la dette du client
      final client = await _clientRepository.getClientById(operation.clientId);
      if (client != null) {
        final updatedClient = client.copyWith(
          totalDebt: client.totalDebt + effects.debtDelta,
        );
        await _clientRepository.updateClient(updatedClient);
      }
    }
  }

  @override
  Stream<List<WaveOperation>> watchOperations() {
    return _localDatasource.watchAll();
  }
}
```


## Data Sources

### PocketBase Client Singleton

```dart
class PbClient {
  static final PbClient _instance = PbClient._internal();
  factory PbClient() => _instance;
  PbClient._internal();

  late final PocketBase pb;

  void init(String baseUrl) {
    pb = PocketBase(baseUrl);
    
    // Auto-refresh du token
    pb.authStore.onChange.listen((event) {
      if (event.token.isEmpty) {
        // Token expiré, tenter refresh
        _refreshToken();
      }
    });
  }

  Future<void> _refreshToken() async {
    try {
      await pb.collection('users').authRefresh();
    } catch (e) {
      // Échec du refresh, déconnecter l'utilisateur
      pb.authStore.clear();
    }
  }

  bool get isAuthenticated => pb.authStore.isValid;
}
```

### PbOperationsDatasource

```dart
class PbOperationsDatasource {
  final PocketBase _pb;

  PbOperationsDatasource(this._pb);

  Future<List<WaveOperation>> getAll() async {
    final records = await _pb.collection('operations').getFullList(
      sort: '-createdAt',
    );
    return records.map((r) => WaveOperation.fromJson(r.toJson())).toList();
  }

  Future<WaveOperation> create(WaveOperation operation) async {
    final record = await _pb.collection('operations').create(
      body: operation.toJson(),
    );
    return WaveOperation.fromJson(record.toJson());
  }

  Future<WaveOperation> update(WaveOperation operation) async {
    final record = await _pb.collection('operations').update(
      operation.id,
      body: operation.toJson(),
    );
    return WaveOperation.fromJson(record.toJson());
  }

  Future<void> delete(String id) async {
    await _pb.collection('operations').delete(id);
  }
}
```

### LocalOperationsDatasource (Hive)

```dart
class LocalOperationsDatasource {
  static const String boxName = 'operations';
  
  Box<Map>? _box;

  Future<void> init() async {
    _box = await Hive.openBox<Map>(boxName);
  }

  Future<List<WaveOperation>> getAll() async {
    final maps = _box!.values.toList();
    return maps.map((m) => WaveOperation.fromJson(Map<String, dynamic>.from(m))).toList();
  }

  Future<void> save(WaveOperation operation) async {
    await _box!.put(operation.id, operation.toJson());
  }

  Future<void> delete(String id) async {
    await _box!.delete(id);
  }

  Stream<List<WaveOperation>> watchAll() {
    return _box!.watch().map((_) => getAll()).asyncMap((future) => future);
  }

  Future<void> clear() async {
    await _box!.clear();
  }
}
```


## Providers Riverpod (Sans Codegen)

### Setup des Repositories

```dart
// providers/repositories_provider.dart

final pbClientProvider = Provider<PocketBase>((ref) {
  return PbClient().pb;
});

final operationRepositoryProvider = Provider<OperationRepository>((ref) {
  final pb = ref.watch(pbClientProvider);
  final remoteDatasource = PbOperationsDatasource(pb);
  final localDatasource = LocalOperationsDatasource();
  return OperationRepositoryImpl(remoteDatasource, localDatasource);
});

final clientRepositoryProvider = Provider<ClientRepository>((ref) {
  final pb = ref.watch(pbClientProvider);
  final remoteDatasource = PbClientsDatasource(pb);
  final localDatasource = LocalClientsDatasource();
  return ClientRepositoryImpl(remoteDatasource, localDatasource);
});

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  final pb = ref.watch(pbClientProvider);
  final remoteDatasource = PbPaymentsDatasource(pb);
  final localDatasource = LocalPaymentsDatasource();
  return PaymentRepositoryImpl(remoteDatasource, localDatasource);
});

final statsRepositoryProvider = Provider<StatsRepository>((ref) {
  final operationRepo = ref.watch(operationRepositoryProvider);
  final clientRepo = ref.watch(clientRepositoryProvider);
  final paymentRepo = ref.watch(paymentRepositoryProvider);
  return StatsRepositoryImpl(operationRepo, clientRepo, paymentRepo);
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final pb = ref.watch(pbClientProvider);
  final remoteDatasource = PbAuthDatasource(pb);
  final localDatasource = LocalAuthDatasource();
  return AuthRepositoryImpl(remoteDatasource, localDatasource);
});
```

### Auth Provider

```dart
// providers/auth_provider.dart

final authStateProvider = StreamProvider<User?>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  return authRepo.watchAuthState();
});

final currentUserProvider = FutureProvider<User?>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  return authRepo.getCurrentUser();
});

class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  final AuthRepository _authRepository;

  AuthNotifier(this._authRepository) : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    state = const AsyncValue.loading();
    try {
      final user = await _authRepository.getCurrentUser();
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final user = await _authRepository.signIn(email, password);
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signOut() async {
    await _authRepository.signOut();
    state = const AsyncValue.data(null);
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AsyncValue<User?>>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  return AuthNotifier(authRepo);
});
```

### Operations Provider

```dart
// providers/operations_provider.dart

final operationsProvider = StreamProvider<List<WaveOperation>>((ref) {
  final repo = ref.watch(operationRepositoryProvider);
  return repo.watchOperations();
});

final operationsByClientProvider = FutureProvider.family<List<WaveOperation>, String>((ref, clientId) {
  final repo = ref.watch(operationRepositoryProvider);
  return repo.getOperationsByClient(clientId);
});

class OperationsNotifier extends StateNotifier<AsyncValue<void>> {
  final OperationRepository _repository;

  OperationsNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<void> addOperation(WaveOperation operation) async {
    state = const AsyncValue.loading();
    try {
      await _repository.addOperation(operation);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateOperation(WaveOperation operation) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateOperation(operation);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteOperation(String id) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteOperation(id);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final operationsNotifierProvider = StateNotifierProvider<OperationsNotifier, AsyncValue<void>>((ref) {
  final repo = ref.watch(operationRepositoryProvider);
  return OperationsNotifier(repo);
});
```

### Clients Provider

```dart
// providers/clients_provider.dart

final clientsProvider = StreamProvider<List<Client>>((ref) {
  final repo = ref.watch(clientRepositoryProvider);
  return repo.watchClients();
});

final clientByIdProvider = FutureProvider.family<Client?, String>((ref, id) {
  final repo = ref.watch(clientRepositoryProvider);
  return repo.getClientById(id);
});

class ClientsNotifier extends StateNotifier<AsyncValue<void>> {
  final ClientRepository _repository;

  ClientsNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<void> addClient(Client client) async {
    state = const AsyncValue.loading();
    try {
      await _repository.addClient(client);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateClient(Client client) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateClient(client);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteClient(String id) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteClient(id);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final clientsNotifierProvider = StateNotifierProvider<ClientsNotifier, AsyncValue<void>>((ref) {
  final repo = ref.watch(clientRepositoryProvider);
  return ClientsNotifier(repo);
});
```

### Stats Provider

```dart
// providers/stats_provider.dart

final statsProvider = StreamProvider<WaveStats>((ref) {
  final repo = ref.watch(statsRepositoryProvider);
  return repo.watchStats();
});
```

### Filters Provider

```dart
// providers/filters_provider.dart

class OperationFilters {
  final String? clientId;
  final WaveOperationType? type;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool? isPaid;

  OperationFilters({
    this.clientId,
    this.type,
    this.startDate,
    this.endDate,
    this.isPaid,
  });

  OperationFilters copyWith({
    String? clientId,
    WaveOperationType? type,
    DateTime? startDate,
    DateTime? endDate,
    bool? isPaid,
  }) {
    return OperationFilters(
      clientId: clientId ?? this.clientId,
      type: type ?? this.type,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isPaid: isPaid ?? this.isPaid,
    );
  }
}

class FiltersNotifier extends StateNotifier<OperationFilters> {
  FiltersNotifier() : super(OperationFilters());

  void setClientFilter(String? clientId) {
    state = state.copyWith(clientId: clientId);
  }

  void setTypeFilter(WaveOperationType? type) {
    state = state.copyWith(type: type);
  }

  void setDateRange(DateTime? start, DateTime? end) {
    state = OperationFilters(
      clientId: state.clientId,
      type: state.type,
      startDate: start,
      endDate: end,
      isPaid: state.isPaid,
    );
  }

  void setPaidFilter(bool? isPaid) {
    state = state.copyWith(isPaid: isPaid);
  }

  void clearFilters() {
    state = OperationFilters();
  }
}

final filtersProvider = StateNotifierProvider<FiltersNotifier, OperationFilters>((ref) {
  return FiltersNotifier();
});

final filteredOperationsProvider = Provider<List<WaveOperation>>((ref) {
  final operations = ref.watch(operationsProvider).value ?? [];
  final filters = ref.watch(filtersProvider);

  return operations.where((op) {
    if (filters.clientId != null && op.clientId != filters.clientId) {
      return false;
    }
    if (filters.type != null && op.type != filters.type) {
      return false;
    }
    if (filters.isPaid != null && op.isPaid != filters.isPaid) {
      return false;
    }
    if (filters.startDate != null && op.createdAt.isBefore(filters.startDate!)) {
      return false;
    }
    if (filters.endDate != null && op.createdAt.isAfter(filters.endDate!)) {
      return false;
    }
    return true;
  }).toList();
});
```


## Navigation (GoRouter)

```dart
// core/router/app_router.dart

final goRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final isAuthenticated = authState.value != null;
      final isOnAuthPage = state.matchedLocation.startsWith('/auth');
      final isOnSplash = state.matchedLocation == '/splash';

      if (isOnSplash) return null;

      if (!isAuthenticated && !isOnAuthPage) {
        return '/auth/login';
      }

      if (isAuthenticated && isOnAuthPage) {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: '/auth/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: '/operations',
        builder: (context, state) => const OperationsListPage(),
      ),
      GoRoute(
        path: '/operations/add',
        builder: (context, state) => const AddOperationPage(),
      ),
      GoRoute(
        path: '/clients',
        builder: (context, state) => const ClientsListPage(),
      ),
      GoRoute(
        path: '/clients/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ClientDetailsPage(clientId: id);
        },
      ),
      GoRoute(
        path: '/clients/add',
        builder: (context, state) => const AddClientPage(),
      ),
      GoRoute(
        path: '/payments/add/:clientId',
        builder: (context, state) {
          final clientId = state.pathParameters['clientId']!;
          return AddPaymentPage(clientId: clientId);
        },
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsPage(),
      ),
    ],
  );
});
```


## Services Additionnels

### Export Service

```dart
// core/services/export_service.dart

class ExportService {
  // Export CSV
  Future<String> exportOperationsToCSV(List<WaveOperation> operations) async {
    final csv = const ListToCsvConverter().convert([
      ['ID', 'Client ID', 'Type', 'Montant', 'Payé', 'Date'],
      ...operations.map((op) => [
        op.id,
        op.clientId,
        op.type.displayName,
        op.amount.toString(),
        op.isPaid ? 'Oui' : 'Non',
        DateFormat('dd/MM/yyyy HH:mm').format(op.createdAt),
      ]),
    ]);
    
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/operations_${DateTime.now().millisecondsSinceEpoch}.csv';
    final file = File(path);
    await file.writeAsString(csv);
    
    return path;
  }

  Future<String> exportClientsToCSV(List<Client> clients) async {
    final csv = const ListToCsvConverter().convert([
      ['ID', 'Nom', 'Téléphone', 'Dette Totale'],
      ...clients.map((c) => [
        c.id,
        c.name,
        c.phone,
        c.totalDebt.toString(),
      ]),
    ]);
    
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/clients_${DateTime.now().millisecondsSinceEpoch}.csv';
    final file = File(path);
    await file.writeAsString(csv);
    
    return path;
  }

  // Export PDF
  Future<Uint8List> generateOperationsPDF(List<WaveOperation> operations) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text('Rapport des Opérations', style: pw.TextStyle(fontSize: 24)),
          ),
          pw.Text('Date: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}'),
          pw.SizedBox(height: 20),
          pw.Table.fromTextArray(
            headers: ['Type', 'Montant', 'Payé', 'Date'],
            data: operations.map((op) => [
              op.type.displayName,
              '${op.amount} FCFA',
              op.isPaid ? 'Oui' : 'Non',
              DateFormat('dd/MM/yyyy').format(op.createdAt),
            ]).toList(),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  Future<Uint8List> generateClientDebtsPDF(List<Client> clients) async {
    final pdf = pw.Document();

    final clientsWithDebt = clients.where((c) => c.totalDebt > 0).toList();
    final totalDebt = clientsWithDebt.fold<double>(0, (sum, c) => sum + c.totalDebt);

    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text('Rapport des Dettes Clients', style: pw.TextStyle(fontSize: 24)),
          ),
          pw.Text('Date: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}'),
          pw.Text('Total des dettes: $totalDebt FCFA', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 20),
          pw.Table.fromTextArray(
            headers: ['Nom', 'Téléphone', 'Dette'],
            data: clientsWithDebt.map((c) => [
              c.name,
              c.phone,
              '${c.totalDebt} FCFA',
            ]).toList(),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  Future<void> sharePDF(Uint8List pdfBytes, String filename) async {
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/$filename';
    final file = File(path);
    await file.writeAsBytes(pdfBytes);
    
    await Share.shareXFiles([XFile(path)], text: 'Rapport Wave Money Agent');
  }
}

final exportServiceProvider = Provider<ExportService>((ref) {
  return ExportService();
});
```

### Notification Service

```dart
// core/services/notification_service.dart

class NotificationService {
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(android: androidSettings, iOS: iosSettings);
    
    await _notifications.initialize(settings);
  }

  Future<void> showOperationNotification(WaveOperation operation) async {
    const androidDetails = AndroidNotificationDetails(
      'operations',
      'Opérations',
      channelDescription: 'Notifications pour les opérations',
      importance: Importance.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _notifications.show(
      operation.id.hashCode,
      'Opération enregistrée',
      '${operation.type.displayName} - ${operation.amount} FCFA',
      details,
    );
  }

  Future<void> showPaymentNotification(ClientPayment payment, Client client) async {
    const androidDetails = AndroidNotificationDetails(
      'payments',
      'Paiements',
      channelDescription: 'Notifications pour les paiements',
      importance: Importance.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _notifications.show(
      payment.id.hashCode,
      'Paiement reçu',
      '${client.name} - ${payment.amount} FCFA',
      details,
    );
  }

  Future<void> showDebtReminderNotification(Client client) async {
    const androidDetails = AndroidNotificationDetails(
      'debt_reminders',
      'Rappels de dettes',
      channelDescription: 'Rappels pour les dettes clients',
      importance: Importance.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _notifications.show(
      client.id.hashCode,
      'Rappel de dette',
      '${client.name} doit ${client.totalDebt} FCFA',
      details,
    );
  }

  Future<void> scheduleDebtReminders(List<Client> clients) async {
    for (final client in clients) {
      if (client.totalDebt > 50000) {
        // Vérifier si la dette existe depuis plus de 7 jours
        // (nécessite de stocker la date de première dette)
        await showDebtReminderNotification(client);
      }
    }
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});
```


## UI/UX Design

### Theme

```dart
// core/theme/app_theme.dart

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF00A8E8), // Bleu Wave
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
      ),
    );
  }
}
```

### HomePage (Dashboard) - Structure

```dart
// presentation/pages/home/home_page.dart

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(statsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wave Money Agent'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: statsAsync.when(
        data: (stats) => _buildDashboard(context, stats),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Erreur: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/operations/add'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, WaveStats stats) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Cartes de statistiques
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'UV',
                  value: '${stats.totalUv} FCFA',
                  icon: Icons.account_balance_wallet,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: StatCard(
                  title: 'Espèces',
                  value: '${stats.totalEspece} FCFA',
                  icon: Icons.money,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          StatCard(
            title: 'Dettes Clients',
            value: '${stats.totalClientDebts} FCFA',
            icon: Icons.warning,
            color: Colors.orange,
          ),
          const SizedBox(height: 24),
          
          // Boutons d'action rapide
          _buildQuickActions(context),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: () => context.push('/operations/add'),
          icon: const Icon(Icons.add),
          label: const Text('Nouvelle Opération'),
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: () => context.push('/clients'),
          icon: const Icon(Icons.people),
          label: const Text('Gérer les Clients'),
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: () => context.push('/operations'),
          icon: const Icon(Icons.history),
          label: const Text('Historique des Opérations'),
        ),
      ],
    );
  }
}
```

### AddOperationPage - Structure

```dart
// presentation/pages/operations/add_operation_page.dart

class AddOperationPage extends ConsumerStatefulWidget {
  const AddOperationPage({super.key});

  @override
  ConsumerState<AddOperationPage> createState() => _AddOperationPageState();
}

class _AddOperationPageState extends ConsumerState<AddOperationPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  
  WaveOperationType? _selectedType;
  String? _selectedClientId;
  bool _isPaid = false;

  @override
  Widget build(BuildContext context) {
    final clientsAsync = ref.watch(clientsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Nouvelle Opération')),
      body: clientsAsync.when(
        data: (clients) => _buildForm(clients),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Erreur: $error')),
      ),
    );
  }

  Widget _buildForm(List<Client> clients) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Dropdown type d'opération
          DropdownButtonFormField<WaveOperationType>(
            value: _selectedType,
            decoration: const InputDecoration(labelText: 'Type d\'opération'),
            items: WaveOperationType.values.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(type.displayName),
              );
            }).toList(),
            onChanged: (value) => setState(() => _selectedType = value),
            validator: (value) => value == null ? 'Sélectionnez un type' : null,
          ),
          const SizedBox(height: 16),
          
          // Dropdown client
          DropdownButtonFormField<String>(
            value: _selectedClientId,
            decoration: const InputDecoration(labelText: 'Client'),
            items: clients.map((client) {
              return DropdownMenuItem(
                value: client.id,
                child: Text(client.name),
              );
            }).toList(),
            onChanged: (value) => setState(() => _selectedClientId = value),
            validator: (value) => value == null ? 'Sélectionnez un client' : null,
          ),
          const SizedBox(height: 16),
          
          // Montant
          TextFormField(
            controller: _amountController,
            decoration: const InputDecoration(
              labelText: 'Montant',
              suffixText: 'FCFA',
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Entrez un montant';
              }
              final amount = double.tryParse(value);
              if (amount == null || amount <= 0) {
                return 'Montant invalide';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // Checkbox payé
          CheckboxListTile(
            title: const Text('Payé'),
            value: _isPaid,
            onChanged: (value) => setState(() => _isPaid = value ?? false),
          ),
          const SizedBox(height: 24),
          
          // Bouton soumettre
          ElevatedButton(
            onPressed: _submitForm,
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final operation = WaveOperation(
      id: '', // Généré par PocketBase
      clientId: _selectedClientId!,
      type: _selectedType!,
      amount: double.parse(_amountController.text),
      isPaid: _isPaid,
      createdAt: DateTime.now(),
    );

    try {
      await ref.read(operationsNotifierProvider.notifier).addOperation(operation);
      
      // Notification
      await ref.read(notificationServiceProvider).showOperationNotification(operation);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Opération enregistrée')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }
}
```


## PocketBase Configuration

### Collections Schema

#### Collection: users
- Utilise l'auth intégrée de PocketBase
- Champs additionnels :
  - `name` (text)
  - `phone` (text, optional)

#### Collection: clients

```javascript
{
  "name": "clients",
  "type": "base",
  "schema": [
    {
      "name": "name",
      "type": "text",
      "required": true
    },
    {
      "name": "phone",
      "type": "text",
      "required": true
    },
    {
      "name": "totalDebt",
      "type": "number",
      "required": true,
      "min": 0
    },
    {
      "name": "userId",
      "type": "relation",
      "required": true,
      "options": {
        "collectionId": "users",
        "cascadeDelete": true
      }
    }
  ],
  "indexes": [
    "CREATE INDEX idx_clients_userId ON clients (userId)"
  ]
}
```

#### Collection: operations

```javascript
{
  "name": "operations",
  "type": "base",
  "schema": [
    {
      "name": "clientId",
      "type": "relation",
      "required": true,
      "options": {
        "collectionId": "clients",
        "cascadeDelete": false
      }
    },
    {
      "name": "type",
      "type": "select",
      "required": true,
      "options": {
        "values": [
          "venteCredit",
          "transfert",
          "depotUv",
          "retraitUv"
        ]
      }
    },
    {
      "name": "amount",
      "type": "number",
      "required": true,
      "min": 0
    },
    {
      "name": "isPaid",
      "type": "bool",
      "required": true
    },
    {
      "name": "userId",
      "type": "relation",
      "required": true,
      "options": {
        "collectionId": "users",
        "cascadeDelete": true
      }
    }
  ],
  "indexes": [
    "CREATE INDEX idx_operations_clientId ON operations (clientId)",
    "CREATE INDEX idx_operations_userId ON operations (userId)",
    "CREATE INDEX idx_operations_created ON operations (created)"
  ]
}
```

#### Collection: payments

```javascript
{
  "name": "payments",
  "type": "base",
  "schema": [
    {
      "name": "clientId",
      "type": "relation",
      "required": true,
      "options": {
        "collectionId": "clients",
        "cascadeDelete": false
      }
    },
    {
      "name": "amount",
      "type": "number",
      "required": true,
      "min": 0
    },
    {
      "name": "userId",
      "type": "relation",
      "required": true,
      "options": {
        "collectionId": "users",
        "cascadeDelete": true
      }
    }
  ],
  "indexes": [
    "CREATE INDEX idx_payments_clientId ON payments (clientId)",
    "CREATE INDEX idx_payments_userId ON payments (userId)"
  ]
}
```

### API Rules (Security)

**Règle générale** : Chaque utilisateur ne peut accéder qu'à ses propres données.

#### clients - List/View Rule
```javascript
@request.auth.id != "" && userId = @request.auth.id
```

#### clients - Create Rule
```javascript
@request.auth.id != "" && @request.data.userId = @request.auth.id
```

#### clients - Update Rule
```javascript
@request.auth.id != "" && userId = @request.auth.id
```

#### clients - Delete Rule
```javascript
@request.auth.id != "" && userId = @request.auth.id
```

#### operations - List/View Rule
```javascript
@request.auth.id != "" && userId = @request.auth.id
```

#### operations - Create Rule
```javascript
@request.auth.id != "" && @request.data.userId = @request.auth.id
```

#### operations - Update Rule
```javascript
@request.auth.id != "" && userId = @request.auth.id
```

#### operations - Delete Rule
```javascript
@request.auth.id != "" && userId = @request.auth.id
```

#### payments - List/View Rule
```javascript
@request.auth.id != "" && userId = @request.auth.id
```

#### payments - Create Rule
```javascript
@request.auth.id != "" && @request.data.userId = @request.auth.id
```

### Migration Script

```javascript
// pb_migrations/initial_setup.js

migrate((db) => {
  // Créer collection clients
  const clientsCollection = new Collection({
    name: "clients",
    type: "base",
    schema: [
      {
        name: "name",
        type: "text",
        required: true
      },
      {
        name: "phone",
        type: "text",
        required: true
      },
      {
        name: "totalDebt",
        type: "number",
        required: true
      },
      {
        name: "userId",
        type: "relation",
        required: true,
        options: {
          collectionId: "_pb_users_auth_",
          cascadeDelete: true
        }
      }
    ]
  });
  
  return db.saveCollection(clientsCollection);
}, (db) => {
  return db.deleteCollection("clients");
});
```


## Error Handling

### Exception Hierarchy

```dart
// core/exceptions/app_exception.dart

abstract class AppException implements Exception {
  final String message;
  final String? code;

  AppException(this.message, {this.code});

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  NetworkException(super.message, {super.code});
}

class AuthException extends AppException {
  AuthException(super.message, {super.code});
}

class ValidationException extends AppException {
  ValidationException(super.message, {super.code});
}

class SyncException extends AppException {
  SyncException(super.message, {super.code});
}
```

### Error Handling Strategy

1. **Network Errors** : Sauvegarder localement et marquer pour sync
2. **Auth Errors** : Rediriger vers login
3. **Validation Errors** : Afficher message à l'utilisateur
4. **Sync Conflicts** : Prioriser serveur et notifier l'utilisateur

## Testing Strategy

### Tests Unitaires (Prioritaires)

1. **Modèles** :
   - Sérialisation/désérialisation JSON
   - copyWith methods
   
2. **Règles Métier** :
   - OperationEffects.calculate() pour chaque type
   - StatsCalculator.calculate()
   
3. **Repositories** :
   - Mock des datasources
   - Test des opérations CRUD
   - Test de la logique de synchronisation

### Tests d'Intégration (Optionnels)

1. **PocketBase Integration** :
   - Test avec instance PocketBase de test
   - CRUD complet
   
2. **Hive Integration** :
   - Test de persistance locale
   - Test de synchronisation

### Tests Widget (Optionnels)

1. **Pages principales** :
   - HomePage rendering
   - AddOperationPage form validation
   
2. **Widgets** :
   - StatCard
   - OperationCard

## Performance Considerations

### Optimisations

1. **Cache Local** : Toujours lire depuis Hive pour performance
2. **Lazy Loading** : Charger les opérations par pagination si nécessaire
3. **Debouncing** : Sur les recherches et filtres
4. **Indexation** : Index PocketBase sur userId, clientId, created
5. **Batch Operations** : Synchroniser par lots lors de la reconnexion

### Limites

- Maximum 1000 opérations chargées en mémoire
- Pagination côté serveur si plus de 1000 records
- Cache local limité à 30 jours d'historique

## Security Considerations

1. **Authentication** : Token JWT avec refresh automatique
2. **Authorization** : Règles PocketBase strictes (userId filter)
3. **Data Isolation** : Chaque agent ne voit que ses données
4. **Local Storage** : Hive non chiffré (considérer encryption si données sensibles)
5. **HTTPS** : Toujours utiliser HTTPS pour PocketBase en production

## Deployment

### PocketBase Setup

1. Installer PocketBase sur serveur ou utiliser PocketHost
2. Configurer les collections via l'admin UI
3. Activer HTTPS
4. Configurer CORS si nécessaire
5. Backup automatique de la DB

### Flutter App

1. Configurer l'URL PocketBase dans `app_constants.dart`
2. Build APK : `flutter build apk --release`
3. Build iOS : `flutter build ios --release`
4. Tester sur devices réels
5. Publier sur Play Store / App Store

## Maintenance

### Monitoring

- Logs PocketBase pour erreurs serveur
- Crash reporting (Firebase Crashlytics optionnel)
- Analytics d'usage (optionnel)

### Updates

- Migrations PocketBase pour changements de schéma
- Versioning de l'app Flutter
- Backward compatibility des modèles JSON

## Conclusion du Design

Ce design privilégie :
- **Simplicité** : Pas d'annotations, code manuel clair
- **Performance** : Cache local Hive, lecture rapide
- **Robustesse** : Gestion offline/online, sync automatique
- **Maintenabilité** : Architecture clean, séparation des responsabilités
- **Sécurité** : Isolation des données par utilisateur

L'architecture est prête pour l'implémentation. Tous les composants sont définis avec des exemples de code concrets.
