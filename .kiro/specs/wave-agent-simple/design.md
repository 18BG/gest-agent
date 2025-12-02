# Design Document - Wave Agent Simple

## Overview

Application Flutter simple pour agent Wave. Philosophie : **code minimal, UI fonctionnel, pas de sur-architecture**.

### Principes de Design

1. **Simplicité** - Pas de packages inutiles, pas de patterns complexes
2. **Efficacité** - L'agent doit pouvoir faire une opération en moins de 10 secondes
3. **Lisibilité** - UI sobre, chiffres bien visibles, pas de gradients flashy
4. **Maintenabilité** - Code direct, facile à comprendre et modifier

## Architecture

### Structure des Dossiers (Simple)

```
lib/
├── main.dart              # Point d'entrée
├── app.dart               # MaterialApp configuration
├── models/                # Modèles de données simples
│   ├── user.dart
│   ├── client.dart
│   ├── operation.dart
│   └── payment.dart
├── services/              # Services (PocketBase, Auth, Notifications)
│   ├── auth_service.dart
│   ├── database_service.dart
│   └── notification_service.dart
├── screens/               # Écrans de l'app
│   ├── login_screen.dart
│   ├── home_screen.dart
│   ├── operations_screen.dart
│   ├── add_operation_screen.dart
│   ├── clients_screen.dart
│   ├── client_detail_screen.dart
│   └── add_client_screen.dart
├── widgets/               # Widgets réutilisables (peu)
│   ├── balance_card.dart
│   ├── operation_tile.dart
│   └── client_tile.dart
└── utils/                 # Helpers
    └── formatters.dart
```

### Navigation (Simple)

Pas de go_router. Navigation Flutter standard :

```dart
// Aller vers un écran
Navigator.push(context, MaterialPageRoute(builder: (_) => AddOperationScreen()));

// Retour
Navigator.pop(context);

// Remplacer (après login)
Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomeScreen()));
```

### State Management (Simple)

- **StatefulWidget** pour les formulaires et états locaux
- **Un seul service singleton** pour l'auth et les données
- Pas de Riverpod/Bloc/Provider complexe pour cette app simple

## Components and Interfaces

### Models

```dart
// client.dart
class Client {
  final String id;
  final String name;
  final String phone;
  double totalDebt;
  final DateTime createdAt;
}

// operation.dart
class Operation {
  final String id;
  final String type; // 'depot', 'retrait', 'transfert', 'credit'
  final double amount;
  final String? clientId;
  final bool isPaid;
  final DateTime createdAt;
}

// payment.dart
class Payment {
  final String id;
  final String clientId;
  final double amount;
  final DateTime createdAt;
}
```

### Services

```dart
// database_service.dart
class DatabaseService {
  static final instance = DatabaseService._();
  late PocketBase pb;
  
  Future<void> init(String url) async { ... }
  
  // Operations
  Future<List<Operation>> getOperations() async { ... }
  Future<Operation> createOperation(Operation op) async { ... }
  
  // Clients
  Future<List<Client>> getClients() async { ... }
  Future<Client> createClient(Client client) async { ... }
  Future<void> updateClientDebt(String clientId, double newDebt) async { ... }
  
  // Stats
  Future<Map<String, double>> getBalances() async { ... }
}

// auth_service.dart
class AuthService {
  static final instance = AuthService._();
  User? currentUser;
  
  Future<bool> login(String email, String password) async { ... }
  Future<void> logout() async { ... }
  bool get isLoggedIn => currentUser != null;
}
```

## Data Models

### PocketBase Collections (existantes)

On garde le schéma PocketBase existant, c'est correct :

- **users** : id, email, password, name
- **clients** : id, name, phone, totalDebt, userId, createdAt
- **operations** : id, type, amount, clientId, isPaid, userId, createdAt
- **payments** : id, clientId, amount, userId, createdAt

## UI Design

### Philosophie UI

- **Fond blanc** - Propre et reposant
- **Une couleur primaire** - Bleu Wave (#00A8E8) uniquement
- **Texte noir/gris** - Lisible
- **Cards simples** - Fond blanc, bordure légère ou ombre subtile
- **Pas de gradients** - Couleurs plates
- **Espacement généreux** - Aéré mais pas excessif

### Écran Login

```
┌─────────────────────────────┐
│                             │
│         [Logo Wave]         │
│                             │
│   ┌─────────────────────┐   │
│   │ Email               │   │
│   └─────────────────────┘   │
│                             │
│   ┌─────────────────────┐   │
│   │ Mot de passe        │   │
│   └─────────────────────┘   │
│                             │
│   ┌─────────────────────┐   │
│   │    Se connecter     │   │  ← Bouton bleu simple
│   └─────────────────────┘   │
│                             │
└─────────────────────────────┘
```

### Écran Accueil

```
┌─────────────────────────────┐
│  Bonjour, [Nom]             │
├─────────────────────────────┤
│                             │
│  ┌───────────┐ ┌───────────┐│
│  │ UV        │ │ Espèces   ││  ← Cards blanches simples
│  │ 850 000   │ │ 400 000   ││
│  └───────────┘ └───────────┘│
│                             │
│  ┌─────────────────────────┐│
│  │ Dettes clients: 75 000  ││  ← Texte rouge si > 0
│  └─────────────────────────┘│
│                             │
│  ┌─────────────────────────┐│
│  │  + Nouvelle opération   ││  ← Bouton principal
│  └─────────────────────────┘│
│                             │
│  Dernières opérations       │
│  ─────────────────────────  │
│  Dépôt - 25 000 - 14:30    │
│  Retrait - 10 000 - 12:15  │
│  ...                        │
│                             │
├─────────────────────────────┤
│  🏠    📋    👥    ⚙️      │  ← Bottom nav simple
└─────────────────────────────┘
```

### Formulaire Opération

```
┌─────────────────────────────┐
│  ← Nouvelle opération       │
├─────────────────────────────┤
│                             │
│  Type d'opération           │
│  ┌─────────────────────────┐│
│  │ Dépôt ▼                 ││  ← Dropdown simple
│  └─────────────────────────┘│
│                             │
│  Montant (FCFA)             │
│  ┌─────────────────────────┐│
│  │ 0                       ││
│  └─────────────────────────┘│
│                             │
│  Client (optionnel)         │
│  ┌─────────────────────────┐│
│  │ Sélectionner... ▼       ││
│  └─────────────────────────┘│
│                             │
│  ☐ Opération payée          │
│                             │
│  ┌─────────────────────────┐│
│  │     Enregistrer         ││
│  └─────────────────────────┘│
│                             │
└─────────────────────────────┘
```

### Liste Clients

```
┌─────────────────────────────┐
│  ← Clients                  │
├─────────────────────────────┤
│  🔍 Rechercher...           │
├─────────────────────────────┤
│                             │
│  Mamadou Diop               │
│  77 123 45 67               │
│  Dette: 50 000 FCFA    →    │  ← Rouge si dette
│  ─────────────────────────  │
│  Fatou Sall                 │
│  77 987 65 43               │
│  À jour               →     │  ← Vert si pas de dette
│  ─────────────────────────  │
│  ...                        │
│                             │
│                        [+]  │  ← FAB pour ajouter
└─────────────────────────────┘
```

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system-essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property 1: Authentification avec identifiants valides
*For any* email et mot de passe valides dans la base, l'authentification doit réussir et retourner un utilisateur
**Validates: Requirements 1.2**

### Property 2: Authentification avec identifiants invalides
*For any* email ou mot de passe invalide, l'authentification doit échouer et retourner une erreur
**Validates: Requirements 1.3**

### Property 3: Mise à jour des soldes après opération
*For any* opération créée, les soldes UV et Espèces doivent être recalculés correctement selon le type d'opération
**Validates: Requirements 3.5**

### Property 4: Tri des opérations par date
*For any* liste d'opérations retournée, les opérations doivent être triées par date décroissante (plus récente en premier)
**Validates: Requirements 3.6**

### Property 5: Tri des clients par dette
*For any* liste de clients retournée, les clients doivent être triés par dette décroissante (plus grande dette en premier)
**Validates: Requirements 4.2**

### Property 6: Réduction de dette après paiement
*For any* paiement enregistré pour un client, la dette du client doit diminuer exactement du montant payé
**Validates: Requirements 4.4**

### Property 7: Round-trip opération
*For any* opération créée puis récupérée depuis PocketBase, les données doivent être identiques
**Validates: Requirements 5.1**

### Property 8: Round-trip client
*For any* client créé puis récupéré depuis PocketBase, les données doivent être identiques
**Validates: Requirements 5.2**

### Property 9: Notification de dette élevée
*For any* client dont la dette dépasse le seuil configuré, une notification doit être déclenchée
**Validates: Requirements 6.2**

## Error Handling

### Approche Simple

```dart
// Pas de classes d'exception complexes
// Juste try-catch avec messages clairs

try {
  await DatabaseService.instance.createOperation(operation);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Opération enregistrée')),
  );
} catch (e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Erreur: ${e.toString()}')),
  );
}
```

### Cas d'erreur gérés

- Connexion réseau échouée → Message "Vérifiez votre connexion"
- Identifiants invalides → Message "Email ou mot de passe incorrect"
- Données invalides → Message spécifique au champ

## Testing Strategy

### Approche

- **Tests unitaires** pour les services (auth, database)
- **Property-based tests** avec `fast_check` pour les propriétés de correction
- **Pas de tests widget complexes** - l'app est simple, les tests manuels suffisent pour l'UI

### Property-Based Testing

Utiliser le package `fast_check` pour Dart :

```dart
// Exemple: Property 4 - Tri des opérations
test('operations should be sorted by date descending', () {
  fc.assert(
    fc.property(
      fc.list(operationArbitrary),
      (operations) {
        final sorted = sortOperationsByDate(operations);
        for (int i = 0; i < sorted.length - 1; i++) {
          expect(sorted[i].createdAt.isAfter(sorted[i + 1].createdAt) || 
                 sorted[i].createdAt == sorted[i + 1].createdAt, isTrue);
        }
      },
    ),
  );
});
```

### Tests Unitaires

```dart
// auth_service_test.dart
test('login with valid credentials returns user', () async {
  final result = await AuthService.instance.login('test@test.com', 'password');
  expect(result, isTrue);
  expect(AuthService.instance.currentUser, isNotNull);
});

// database_service_test.dart
test('createOperation saves and returns operation', () async {
  final op = Operation(type: 'depot', amount: 1000, isPaid: true);
  final saved = await DatabaseService.instance.createOperation(op);
  expect(saved.id, isNotEmpty);
  expect(saved.amount, equals(1000));
});
```
