# Règles de Sécurité PocketBase - Wave Money Agent

## Vue d'Ensemble

Toutes les collections utilisent un modèle de sécurité basé sur l'isolation par utilisateur (`userId`). Chaque utilisateur ne peut accéder qu'à ses propres données.

## Règles par Collection

### Collection: `clients`

| Action | Règle | Description |
|--------|-------|-------------|
| **List** | `userId = @request.auth.id` | L'utilisateur ne voit que ses propres clients |
| **View** | `userId = @request.auth.id` | L'utilisateur ne peut voir que ses propres clients |
| **Create** | `@request.data.userId = @request.auth.id` | Le userId doit être celui de l'utilisateur connecté |
| **Update** | `userId = @request.auth.id` | L'utilisateur ne peut modifier que ses propres clients |
| **Delete** | `userId = @request.auth.id` | L'utilisateur ne peut supprimer que ses propres clients |

### Collection: `operations`

| Action | Règle | Description |
|--------|-------|-------------|
| **List** | `userId = @request.auth.id` | L'utilisateur ne voit que ses propres opérations |
| **View** | `userId = @request.auth.id` | L'utilisateur ne peut voir que ses propres opérations |
| **Create** | `@request.data.userId = @request.auth.id` | Le userId doit être celui de l'utilisateur connecté |
| **Update** | `userId = @request.auth.id` | L'utilisateur ne peut modifier que ses propres opérations |
| **Delete** | `userId = @request.auth.id` | L'utilisateur ne peut supprimer que ses propres opérations |

### Collection: `payments`

| Action | Règle | Description |
|--------|-------|-------------|
| **List** | `userId = @request.auth.id` | L'utilisateur ne voit que ses propres paiements |
| **View** | `userId = @request.auth.id` | L'utilisateur ne peut voir que ses propres paiements |
| **Create** | `@request.data.userId = @request.auth.id` | Le userId doit être celui de l'utilisateur connecté |
| **Update** | `userId = @request.auth.id` | L'utilisateur ne peut modifier que ses propres paiements |
| **Delete** | `userId = @request.auth.id` | L'utilisateur ne peut supprimer que ses propres paiements |

## Explication des Règles

### Variables Disponibles

- `@request.auth.id` : ID de l'utilisateur authentifié
- `@request.data` : Données envoyées dans la requête
- `userId` : Champ userId de l'enregistrement

### Règles de Lecture (List/View)

```javascript
userId = @request.auth.id
```

**Signification:** L'enregistrement doit appartenir à l'utilisateur connecté.

**Exemple:** Si l'utilisateur A est connecté, il ne verra que les clients où `userId = A.id`

### Règles de Création (Create)

```javascript
@request.data.userId = @request.auth.id
```

**Signification:** Le userId fourni dans les données doit correspondre à l'utilisateur connecté.

**Exemple:** 
```dart
// ✅ Autorisé
await pb.collection('clients').create(body: {
  'name': 'Jean',
  'userId': pb.authStore.model?.id, // ID de l'utilisateur connecté
});

// ❌ Refusé
await pb.collection('clients').create(body: {
  'name': 'Jean',
  'userId': 'autre-user-id', // ID d'un autre utilisateur
});
```

### Règles de Modification/Suppression (Update/Delete)

```javascript
userId = @request.auth.id
```

**Signification:** L'enregistrement à modifier/supprimer doit appartenir à l'utilisateur connecté.

**Exemple:**
```dart
// ✅ Autorisé (si le client appartient à l'utilisateur)
await pb.collection('clients').update(clientId, body: {
  'name': 'Nouveau nom',
});

// ❌ Refusé (si le client appartient à un autre utilisateur)
await pb.collection('clients').update(autreClientId, body: {
  'name': 'Nouveau nom',
});
```

## Cascade Delete

### Relations avec Cascade Delete Activé

1. **operations.clientId → clients**
   - Si un client est supprimé, toutes ses opérations sont automatiquement supprimées

2. **payments.clientId → clients**
   - Si un client est supprimé, tous ses paiements sont automatiquement supprimés

### Relations avec Cascade Delete Désactivé

1. **clients.userId → users**
2. **operations.userId → users**
3. **payments.userId → users**

**Raison:** La suppression d'un compte utilisateur ne doit pas automatiquement supprimer toutes ses données. Cela permet une gestion manuelle ou une archive des données.

## Scénarios de Test

### Scénario 1: Isolation des Données

**Setup:**
- Utilisateur A crée un client "Client A"
- Utilisateur B crée un client "Client B"

**Test:**
```dart
// Connecté en tant qu'utilisateur A
final clients = await pb.collection('clients').getFullList();
// Résultat: Seulement "Client A"

// Connecté en tant qu'utilisateur B
final clients = await pb.collection('clients').getFullList();
// Résultat: Seulement "Client B"
```

### Scénario 2: Tentative de Création avec Mauvais userId

**Test:**
```dart
// Connecté en tant qu'utilisateur A
try {
  await pb.collection('clients').create(body: {
    'name': 'Test',
    'phone': '123456789',
    'totalDebt': 0,
    'userId': 'user-b-id', // ID d'un autre utilisateur
  });
} catch (e) {
  // Erreur: 400 Bad Request
  // Message: Failed to create record
}
```

### Scénario 3: Tentative de Modification de Données d'un Autre Utilisateur

**Test:**
```dart
// Utilisateur A crée un client
final clientA = await pb.collection('clients').create(body: {
  'name': 'Client A',
  'phone': '123456789',
  'totalDebt': 0,
  'userId': userA.id,
});

// Utilisateur B tente de modifier le client de A
// (Connecté en tant qu'utilisateur B)
try {
  await pb.collection('clients').update(clientA.id, body: {
    'name': 'Modifié par B',
  });
} catch (e) {
  // Erreur: 404 Not Found
  // Le client n'existe pas pour l'utilisateur B
}
```

### Scénario 4: Cascade Delete

**Test:**
```dart
// Créer un client
final client = await pb.collection('clients').create(body: {
  'name': 'Client Test',
  'phone': '123456789',
  'totalDebt': 0,
  'userId': pb.authStore.model?.id,
});

// Créer des opérations pour ce client
await pb.collection('operations').create(body: {
  'clientId': client.id,
  'type': 'venteCredit',
  'amount': 5000,
  'isPaid': false,
  'userId': pb.authStore.model?.id,
});

// Supprimer le client
await pb.collection('clients').delete(client.id);

// Vérifier que les opérations ont été supprimées
final operations = await pb.collection('operations').getFullList(
  filter: 'clientId = "${client.id}"',
);
// Résultat: Liste vide (opérations supprimées automatiquement)
```

## Bonnes Pratiques

### 1. Toujours Inclure le userId lors de la Création

```dart
// ✅ Bon
await pb.collection('clients').create(body: {
  'name': 'Jean',
  'phone': '123456789',
  'totalDebt': 0,
  'userId': pb.authStore.model?.id, // Toujours inclure
});
```

### 2. Ne Jamais Hardcoder les userId

```dart
// ❌ Mauvais
await pb.collection('clients').create(body: {
  'userId': 'abc123', // Hardcodé
});

// ✅ Bon
await pb.collection('clients').create(body: {
  'userId': pb.authStore.model?.id, // Dynamique
});
```

### 3. Gérer les Erreurs d'Autorisation

```dart
try {
  await pb.collection('clients').update(clientId, body: data);
} catch (e) {
  if (e is ClientException && e.statusCode == 404) {
    // Le client n'existe pas ou n'appartient pas à l'utilisateur
    print('Accès refusé ou client introuvable');
  }
}
```

### 4. Vérifier l'Authentification Avant les Opérations

```dart
if (!pb.authStore.isValid) {
  throw Exception('Utilisateur non authentifié');
}

// Continuer avec les opérations
```

## Audit et Monitoring

### Logs PocketBase

PocketBase enregistre automatiquement:
- Tentatives de connexion
- Échecs d'authentification
- Violations de règles de sécurité

Pour activer les logs détaillés:
```bash
./pocketbase serve --debug
```

### Vérification Manuelle

Dans l'interface admin:
1. Allez dans **Logs**
2. Filtrez par collection
3. Vérifiez les tentatives d'accès non autorisées

## Mise à Jour des Règles

Si vous devez modifier les règles:

1. Allez dans **Collections** > [nom de la collection]
2. Cliquez sur **API Rules**
3. Modifiez les règles
4. Testez avec différents utilisateurs
5. Sauvegardez

**⚠️ Attention:** Ne supprimez jamais les vérifications de `userId` sans une bonne raison de sécurité.
