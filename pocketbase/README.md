# PocketBase Configuration - Wave Money Agent

Ce document décrit la configuration complète de PocketBase pour l'application Wave Money Agent.

## Installation de PocketBase

1. Téléchargez PocketBase depuis https://pocketbase.io/docs/
2. Extrayez l'exécutable dans un dossier de votre choix
3. Lancez PocketBase : `./pocketbase serve`
4. Accédez à l'interface admin : http://127.0.0.1:8090/_/

## Configuration Initiale

### 1. Créer un compte administrateur

Lors du premier lancement, créez un compte administrateur via l'interface web.

### 2. Importer le schéma des collections

Vous pouvez importer le schéma de deux façons :

#### Option A : Import automatique (Recommandé)

1. Allez dans **Settings** > **Import collections**
2. Copiez le contenu du fichier `pb_schema.json`
3. Cliquez sur **Import**

#### Option B : Création manuelle

Suivez les instructions ci-dessous pour créer chaque collection manuellement.

## Collections

### Collection: `clients`

**Type:** Base Collection

**Champs:**

| Nom | Type | Requis | Options |
|-----|------|--------|---------|
| name | text | ✓ | min: 1, max: 255 |
| phone | text | ✓ | min: 8, max: 20, pattern: `^[0-9+\-\s()]+$` |
| totalDebt | number | ✓ | min: 0 |
| userId | relation | ✓ | collection: users, maxSelect: 1 |

**Index:**
```sql
CREATE INDEX idx_clients_userId ON clients (userId);
CREATE INDEX idx_clients_created ON clients (created);
```

**Règles de sécurité:**
- **List:** `userId = @request.auth.id`
- **View:** `userId = @request.auth.id`
- **Create:** `@request.data.userId = @request.auth.id`
- **Update:** `userId = @request.auth.id`
- **Delete:** `userId = @request.auth.id`

---

### Collection: `operations`

**Type:** Base Collection

**Champs:**

| Nom | Type | Requis | Options |
|-----|------|--------|---------|
| clientId | relation | ✓ | collection: clients, cascadeDelete: true, maxSelect: 1 |
| type | select | ✓ | values: venteCredit, transfert, depotUv, retraitUv |
| amount | number | ✓ | min: 0 |
| isPaid | bool | ✓ | - |
| userId | relation | ✓ | collection: users, maxSelect: 1 |

**Index:**
```sql
CREATE INDEX idx_operations_userId ON operations (userId);
CREATE INDEX idx_operations_clientId ON operations (clientId);
CREATE INDEX idx_operations_created ON operations (created);
CREATE INDEX idx_operations_type ON operations (type);
```

**Règles de sécurité:**
- **List:** `userId = @request.auth.id`
- **View:** `userId = @request.auth.id`
- **Create:** `@request.data.userId = @request.auth.id`
- **Update:** `userId = @request.auth.id`
- **Delete:** `userId = @request.auth.id`

---

### Collection: `payments`

**Type:** Base Collection

**Champs:**

| Nom | Type | Requis | Options |
|-----|------|--------|---------|
| clientId | relation | ✓ | collection: clients, cascadeDelete: true, maxSelect: 1 |
| amount | number | ✓ | min: 0 |
| userId | relation | ✓ | collection: users, maxSelect: 1 |

**Index:**
```sql
CREATE INDEX idx_payments_userId ON payments (userId);
CREATE INDEX idx_payments_clientId ON payments (clientId);
CREATE INDEX idx_payments_created ON payments (created);
```

**Règles de sécurité:**
- **List:** `userId = @request.auth.id`
- **View:** `userId = @request.auth.id`
- **Create:** `@request.data.userId = @request.auth.id`
- **Update:** `userId = @request.auth.id`
- **Delete:** `userId = @request.auth.id`

---

### Collection: `user_balances` (VIEW)

**Type:** View Collection (calcul côté serveur)

Cette view calcule automatiquement les soldes UV, espèces et dettes pour chaque utilisateur.
Elle évite de charger toutes les opérations côté client pour calculer les soldes.

**Champs calculés:**

| Nom | Type | Description |
|-----|------|-------------|
| uvBalance | number | Solde UV de l'agent |
| cashBalance | number | Solde espèces de l'agent |
| totalDebts | number | Total des dettes clients |

**Logique de calcul:**

| Type d'opération | Impact UV | Impact Espèces |
|------------------|-----------|----------------|
| Dépôt UV | -montant | +montant (si payé) |
| Transfert | -montant | +montant (si payé) |
| Vente Crédit | -montant | +montant (si payé) |
| Retrait UV | +montant | -montant |

**Requête SQL:**
```sql
SELECT 
  u.id,
  COALESCE(SUM(CASE WHEN o.type = 'retraitUv' THEN o.amount ELSE -o.amount END), 0) as uvBalance,
  COALESCE(SUM(CASE WHEN o.type = 'retraitUv' THEN -o.amount WHEN o.isPaid = 1 THEN o.amount ELSE 0 END), 0) as cashBalance,
  COALESCE((SELECT SUM(c.totalDebt) FROM clients c WHERE c.userId = u.id), 0) as totalDebts
FROM users u
LEFT JOIN operations o ON o.userId = u.id
GROUP BY u.id
```

**Règles de sécurité:**
- **List:** `id = @request.auth.id`
- **View:** `id = @request.auth.id`

**Usage dans l'app Flutter:**
```dart
// Récupère tous les soldes en une seule requête
final balances = await DatabaseService.instance.getAllBalances();
print('UV: ${balances.uv}');
print('Espèces: ${balances.cash}');
print('Dettes: ${balances.debts}');
```

---

## Relations et Cascade Delete

### Relations configurées:

1. **operations.clientId → clients**
   - Type: Many-to-One
   - Cascade Delete: **Activé** (suppression d'un client supprime ses opérations)

2. **payments.clientId → clients**
   - Type: Many-to-One
   - Cascade Delete: **Activé** (suppression d'un client supprime ses paiements)

3. **clients.userId → users**
   - Type: Many-to-One
   - Cascade Delete: **Désactivé** (suppression d'un user ne supprime pas automatiquement)

4. **operations.userId → users**
   - Type: Many-to-One
   - Cascade Delete: **Désactivé**

5. **payments.userId → users**
   - Type: Many-to-One
   - Cascade Delete: **Désactivé**

## Règles de Sécurité

Toutes les collections suivent le même modèle de sécurité basé sur `userId`:

### Principe de base:
- Chaque enregistrement est lié à un utilisateur via le champ `userId`
- Un utilisateur ne peut accéder qu'à ses propres données

### Règles appliquées:

**List/View (Lecture):**
```javascript
userId = @request.auth.id
```
→ L'utilisateur ne peut lister/voir que les enregistrements où `userId` correspond à son ID

**Create (Création):**
```javascript
@request.data.userId = @request.auth.id
```
→ Lors de la création, le `userId` doit obligatoirement être l'ID de l'utilisateur authentifié

**Update/Delete (Modification/Suppression):**
```javascript
userId = @request.auth.id
```
→ L'utilisateur ne peut modifier/supprimer que ses propres enregistrements

## Index de Performance

Les index suivants sont créés pour optimiser les requêtes:

### Collection `clients`:
- `idx_clients_userId` - Accélère les requêtes filtrées par utilisateur
- `idx_clients_created` - Accélère le tri par date de création

### Collection `operations`:
- `idx_operations_userId` - Accélère les requêtes filtrées par utilisateur
- `idx_operations_clientId` - Accélère les requêtes d'opérations par client
- `idx_operations_created` - Accélère le tri par date de création
- `idx_operations_type` - Accélère les filtres par type d'opération

### Collection `payments`:
- `idx_payments_userId` - Accélère les requêtes filtrées par utilisateur
- `idx_payments_clientId` - Accélère les requêtes de paiements par client
- `idx_payments_created` - Accélère le tri par date de création

## Configuration de l'Application Flutter

Après avoir configuré PocketBase, mettez à jour l'URL dans votre application:

**Fichier:** `lib/core/constants/app_constants.dart`

```dart
class AppConstants {
  // URL de votre instance PocketBase
  static const String pocketbaseUrl = 'http://127.0.0.1:8090';
  
  // Pour production, utilisez votre URL de serveur:
  // static const String pocketbaseUrl = 'https://votre-domaine.com';
}
```

## Création d'un Utilisateur de Test

Via l'interface admin ou via l'API:

```dart
// Dans votre app Flutter
final pb = PocketBase('http://127.0.0.1:8090');

// Créer un utilisateur
await pb.collection('users').create(body: {
  'email': 'agent@wave.com',
  'password': 'motdepasse123',
  'passwordConfirm': 'motdepasse123',
  'name': 'Agent Wave Test',
});
```

## Vérification de la Configuration

Pour vérifier que tout fonctionne:

1. Créez un utilisateur de test
2. Authentifiez-vous avec cet utilisateur
3. Créez un client via l'API
4. Vérifiez que le client apparaît uniquement pour cet utilisateur
5. Testez la création d'opérations et de paiements

## Backup et Migration

### Backup automatique:
PocketBase crée automatiquement des backups dans le dossier `pb_data/backups/`

### Export manuel:
```bash
./pocketbase export
```

### Import:
```bash
./pocketbase import backup.zip
```

## Déploiement en Production

### Options de déploiement:

1. **VPS/Serveur dédié:**
   - Installez PocketBase sur votre serveur
   - Configurez un reverse proxy (Nginx/Caddy)
   - Activez HTTPS avec Let's Encrypt

2. **PocketHost (Recommandé pour débuter):**
   - Service d'hébergement PocketBase géré
   - https://pockethost.io
   - Configuration automatique HTTPS

3. **Docker:**
   ```dockerfile
   FROM alpine:latest
   RUN apk add --no-cache ca-certificates
   COPY pocketbase /usr/local/bin/pocketbase
   EXPOSE 8090
   CMD ["/usr/local/bin/pocketbase", "serve", "--http=0.0.0.0:8090"]
   ```

## Sécurité Additionnelle

### Recommandations:

1. **HTTPS obligatoire en production**
2. **Limitez les tentatives de connexion** (configuré dans PocketBase)
3. **Activez les logs d'audit**
4. **Sauvegardez régulièrement la base de données**
5. **Utilisez des mots de passe forts**
6. **Configurez CORS correctement:**
   ```
   Settings > Application > CORS
   Ajoutez votre domaine d'application
   ```

## Support et Documentation

- Documentation officielle: https://pocketbase.io/docs/
- Discord communautaire: https://discord.gg/pocketbase
- GitHub: https://github.com/pocketbase/pocketbase
