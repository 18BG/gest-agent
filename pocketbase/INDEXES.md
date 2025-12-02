# Index de Performance - Wave Money Agent

## Vue d'Ensemble

Les index sont cruciaux pour les performances des requêtes dans PocketBase. Ce document détaille tous les index créés et leur utilité.

## Index par Collection

### Collection: `clients`

#### Index 1: `idx_clients_userId`
```sql
CREATE INDEX idx_clients_userId ON clients (userId)
```

**Utilité:**
- Accélère les requêtes filtrées par `userId`
- Utilisé dans toutes les opérations CRUD (List, View, Update, Delete)
- Critique pour les règles de sécurité

**Requêtes optimisées:**
```dart
// Liste tous les clients de l'utilisateur connecté
await pb.collection('clients').getFullList(
  filter: 'userId = "${pb.authStore.model?.id}"',
);

// Compte le nombre de clients
await pb.collection('clients').getFullList(
  filter: 'userId = "${pb.authStore.model?.id}"',
).then((list) => list.length);
```

**Impact:** Sans cet index, chaque requête devrait scanner toute la table.

---

#### Index 2: `idx_clients_created`
```sql
CREATE INDEX idx_clients_created ON clients (created)
```

**Utilité:**
- Accélère le tri par date de création
- Utilisé pour afficher les clients récents en premier

**Requêtes optimisées:**
```dart
// Clients triés par date de création (plus récents en premier)
await pb.collection('clients').getFullList(
  sort: '-created',
);

// Clients créés dans une période
await pb.collection('clients').getFullList(
  filter: 'created >= "2024-01-01" && created <= "2024-12-31"',
);
```

---

### Collection: `operations`

#### Index 1: `idx_operations_userId`
```sql
CREATE INDEX idx_operations_userId ON operations (userId)
```

**Utilité:**
- Accélère les requêtes filtrées par `userId`
- Critique pour les règles de sécurité
- Utilisé dans toutes les opérations CRUD

**Requêtes optimisées:**
```dart
// Liste toutes les opérations de l'utilisateur
await pb.collection('operations').getFullList(
  filter: 'userId = "${pb.authStore.model?.id}"',
);
```

---

#### Index 2: `idx_operations_clientId`
```sql
CREATE INDEX idx_operations_clientId ON operations (clientId)
```

**Utilité:**
- Accélère les requêtes d'opérations par client
- Utilisé dans la page de détails client
- Critique pour afficher l'historique des opérations

**Requêtes optimisées:**
```dart
// Toutes les opérations d'un client
await pb.collection('operations').getFullList(
  filter: 'clientId = "${clientId}"',
);

// Opérations impayées d'un client
await pb.collection('operations').getFullList(
  filter: 'clientId = "${clientId}" && isPaid = false',
);

// Compte le nombre d'opérations par client
await pb.collection('operations').getFullList(
  filter: 'clientId = "${clientId}"',
).then((list) => list.length);
```

---

#### Index 3: `idx_operations_created`
```sql
CREATE INDEX idx_operations_created ON operations (created)
```

**Utilité:**
- Accélère le tri par date de création
- Utilisé pour afficher l'historique chronologique
- Optimise les filtres par période

**Requêtes optimisées:**
```dart
// Opérations triées par date (plus récentes en premier)
await pb.collection('operations').getFullList(
  sort: '-created',
);

// Opérations d'une période spécifique
await pb.collection('operations').getFullList(
  filter: 'created >= "2024-11-01" && created <= "2024-11-30"',
);

// Opérations des 7 derniers jours
final sevenDaysAgo = DateTime.now().subtract(Duration(days: 7));
await pb.collection('operations').getFullList(
  filter: 'created >= "${sevenDaysAgo.toIso8601String()}"',
);
```

---

#### Index 4: `idx_operations_type`
```sql
CREATE INDEX idx_operations_type ON operations (type)
```

**Utilité:**
- Accélère les filtres par type d'opération
- Utilisé dans les filtres de la liste des opérations
- Optimise les statistiques par type

**Requêtes optimisées:**
```dart
// Toutes les ventes de crédit
await pb.collection('operations').getFullList(
  filter: 'type = "venteCredit"',
);

// Tous les transferts impayés
await pb.collection('operations').getFullList(
  filter: 'type = "transfert" && isPaid = false',
);

// Statistiques par type
for (final type in ['venteCredit', 'transfert', 'depotUv', 'retraitUv']) {
  final ops = await pb.collection('operations').getFullList(
    filter: 'type = "$type"',
  );
  print('$type: ${ops.length} opérations');
}
```

---

### Collection: `payments`

#### Index 1: `idx_payments_userId`
```sql
CREATE INDEX idx_payments_userId ON payments (userId)
```

**Utilité:**
- Accélère les requêtes filtrées par `userId`
- Critique pour les règles de sécurité
- Utilisé dans toutes les opérations CRUD

**Requêtes optimisées:**
```dart
// Liste tous les paiements de l'utilisateur
await pb.collection('payments').getFullList(
  filter: 'userId = "${pb.authStore.model?.id}"',
);
```

---

#### Index 2: `idx_payments_clientId`
```sql
CREATE INDEX idx_payments_clientId ON payments (clientId)
```

**Utilité:**
- Accélère les requêtes de paiements par client
- Utilisé dans la page de détails client
- Critique pour afficher l'historique des paiements

**Requêtes optimisées:**
```dart
// Tous les paiements d'un client
await pb.collection('payments').getFullList(
  filter: 'clientId = "${clientId}"',
);

// Somme des paiements d'un client
final payments = await pb.collection('payments').getFullList(
  filter: 'clientId = "${clientId}"',
);
final total = payments.fold<double>(
  0,
  (sum, p) => sum + (p.data['amount'] as num).toDouble(),
);
```

---

#### Index 3: `idx_payments_created`
```sql
CREATE INDEX idx_payments_created ON payments (created)
```

**Utilité:**
- Accélère le tri par date de création
- Utilisé pour afficher l'historique chronologique
- Optimise les filtres par période

**Requêtes optimisées:**
```dart
// Paiements triés par date (plus récents en premier)
await pb.collection('payments').getFullList(
  sort: '-created',
);

// Paiements d'une période spécifique
await pb.collection('payments').getFullList(
  filter: 'created >= "2024-11-01" && created <= "2024-11-30"',
);
```

---

## Index Composites (Recommandations Futures)

Si les performances deviennent un problème avec beaucoup de données, considérez ces index composites:

### Pour `operations`:

```sql
-- Index composite pour filtrer par userId et clientId
CREATE INDEX idx_operations_userId_clientId ON operations (userId, clientId);

-- Index composite pour filtrer par userId et type
CREATE INDEX idx_operations_userId_type ON operations (userId, type);

-- Index composite pour filtrer par userId et isPaid
CREATE INDEX idx_operations_userId_isPaid ON operations (userId, isPaid);

-- Index composite pour filtrer par userId et trier par created
CREATE INDEX idx_operations_userId_created ON operations (userId, created DESC);
```

### Pour `clients`:

```sql
-- Index composite pour filtrer par userId et trier par totalDebt
CREATE INDEX idx_clients_userId_totalDebt ON clients (userId, totalDebt DESC);
```

## Mesure de Performance

### Comment Vérifier l'Utilisation des Index

PocketBase utilise SQLite en interne. Pour vérifier qu'un index est utilisé:

1. Activez les logs de debug:
```bash
./pocketbase serve --debug
```

2. Exécutez vos requêtes depuis l'app

3. Vérifiez les logs pour voir les requêtes SQL générées

### Benchmark des Requêtes

Utilisez le script `test_configuration.dart` pour mesurer les performances:

```bash
dart run pocketbase/test_configuration.dart
```

Le script teste:
- Requêtes par `userId`
- Requêtes par `clientId`
- Requêtes par `type`
- Tri par `created`

### Résultats Attendus

Avec les index:
- Requêtes simples: < 10ms
- Requêtes avec filtres multiples: < 50ms
- Requêtes avec tri: < 20ms

Sans les index:
- Requêtes simples: 50-100ms
- Requêtes avec filtres multiples: 200-500ms
- Requêtes avec tri: 100-300ms

## Maintenance des Index

### Reconstruction des Index

Si vous suspectez des problèmes de performance:

1. Exportez vos données:
```bash
./pocketbase export
```

2. Supprimez la base de données:
```bash
rm pb_data/data.db
```

3. Réimportez:
```bash
./pocketbase import backup.zip
```

Les index seront automatiquement reconstruits.

### Analyse de l'Utilisation

Pour voir la taille des index:

```sql
-- Dans l'interface admin, allez dans Settings > Database
SELECT name, sql FROM sqlite_master WHERE type = 'index';
```

## Impact sur les Performances

### Avantages:
- ✅ Requêtes 10-50x plus rapides
- ✅ Meilleure expérience utilisateur
- ✅ Scalabilité améliorée

### Inconvénients:
- ⚠️ Légère augmentation de la taille de la base de données (~10-20%)
- ⚠️ Légère augmentation du temps d'écriture (~5-10%)

**Conclusion:** Les avantages dépassent largement les inconvénients pour cette application.

## Monitoring en Production

### Métriques à Surveiller:

1. **Temps de réponse moyen:**
   - Objectif: < 100ms pour 95% des requêtes

2. **Taille de la base de données:**
   - Surveiller la croissance
   - Planifier des archives si nécessaire

3. **Nombre de requêtes par seconde:**
   - Identifier les pics d'utilisation
   - Optimiser les requêtes fréquentes

### Outils:

- Logs PocketBase (avec `--debug`)
- Monitoring applicatif (Firebase Analytics, Sentry)
- Profiling SQLite (si nécessaire)

## Conclusion

Les index créés couvrent tous les cas d'utilisation principaux de l'application Wave Money Agent. Ils garantissent des performances optimales même avec des milliers d'enregistrements par utilisateur.

**Recommandation:** Ne supprimez aucun de ces index. Ils sont tous essentiels pour les performances de l'application.
