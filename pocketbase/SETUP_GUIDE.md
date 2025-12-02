# Guide de Configuration PocketBase - Wave Money Agent

## Étape par Étape

### 1. Installation de PocketBase

#### Windows:
```bash
# Téléchargez depuis https://github.com/pocketbase/pocketbase/releases
# Extrayez pocketbase.exe dans un dossier (ex: C:\pocketbase)
cd C:\pocketbase
pocketbase.exe serve
```

#### Linux/Mac:
```bash
# Téléchargez depuis https://github.com/pocketbase/pocketbase/releases
wget https://github.com/pocketbase/pocketbase/releases/download/v0.20.0/pocketbase_0.20.0_linux_amd64.zip
unzip pocketbase_0.20.0_linux_amd64.zip
chmod +x pocketbase
./pocketbase serve
```

### 2. Premier Lancement

1. Lancez PocketBase: `./pocketbase serve`
2. Ouvrez votre navigateur: http://127.0.0.1:8090/_/
3. Créez un compte administrateur (email + mot de passe)

### 3. Import du Schéma

#### Méthode 1: Import JSON (Recommandé)

1. Dans l'interface admin, allez dans **Settings** (⚙️)
2. Cliquez sur **Import collections**
3. Ouvrez le fichier `pb_schema.json` de ce dossier
4. Copiez tout le contenu
5. Collez dans la zone de texte
6. Cliquez sur **Review** puis **Confirm**

#### Méthode 2: Migration JavaScript

1. Copiez le fichier `migrations/1732464000_create_collections.js` dans le dossier `pb_migrations/` de votre installation PocketBase
2. Redémarrez PocketBase
3. Les collections seront créées automatiquement

### 4. Vérification

Après l'import, vous devriez voir 3 collections dans l'interface admin:

- ✅ **clients** (4 champs + userId)
- ✅ **operations** (5 champs + userId)
- ✅ **payments** (3 champs + userId)

### 5. Création d'un Utilisateur de Test

#### Via l'interface admin:

1. Allez dans **Collections** > **users**
2. Cliquez sur **New record**
3. Remplissez:
   - Email: `agent@wave.com`
   - Password: `Test123456!`
   - Name: `Agent Test`
4. Cliquez sur **Create**

#### Via l'API (depuis votre app Flutter):

```dart
final pb = PocketBase('http://127.0.0.1:8090');

try {
  await pb.collection('users').create(body: {
    'email': 'agent@wave.com',
    'password': 'Test123456!',
    'passwordConfirm': 'Test123456!',
    'name': 'Agent Test',
  });
  print('Utilisateur créé avec succès');
} catch (e) {
  print('Erreur: $e');
}
```

### 6. Test de Connexion

Dans votre app Flutter:

```dart
final pb = PocketBase('http://127.0.0.1:8090');

try {
  final authData = await pb.collection('users').authWithPassword(
    'agent@wave.com',
    'Test123456!',
  );
  print('Connecté: ${authData.record?.data['name']}');
  print('Token: ${pb.authStore.token}');
} catch (e) {
  print('Erreur de connexion: $e');
}
```

### 7. Configuration de l'App Flutter

Mettez à jour l'URL PocketBase dans votre app:

**Fichier:** `lib/core/constants/app_constants.dart`

```dart
class AppConstants {
  // Développement local
  static const String pocketbaseUrl = 'http://127.0.0.1:8090';
  
  // Pour tester sur un appareil physique, utilisez l'IP de votre PC:
  // static const String pocketbaseUrl = 'http://192.168.1.X:8090';
  
  // Production
  // static const String pocketbaseUrl = 'https://votre-domaine.com';
}
```

### 8. Test des Collections

#### Créer un client:

```dart
final client = await pb.collection('clients').create(body: {
  'name': 'Jean Dupont',
  'phone': '+221 77 123 45 67',
  'totalDebt': 0,
  'userId': pb.authStore.model?.id,
});
```

#### Créer une opération:

```dart
final operation = await pb.collection('operations').create(body: {
  'clientId': client.id,
  'type': 'venteCredit',
  'amount': 5000,
  'isPaid': false,
  'userId': pb.authStore.model?.id,
});
```

#### Créer un paiement:

```dart
final payment = await pb.collection('payments').create(body: {
  'clientId': client.id,
  'amount': 2000,
  'userId': pb.authStore.model?.id,
});
```

### 9. Vérification des Règles de Sécurité

Pour vérifier que les règles fonctionnent:

1. Créez 2 utilisateurs différents
2. Connectez-vous avec l'utilisateur 1
3. Créez un client
4. Déconnectez-vous et connectez-vous avec l'utilisateur 2
5. Essayez de lister les clients → Vous ne devriez voir que les clients de l'utilisateur 2

### 10. Vérification des Index

Dans l'interface admin:

1. Allez dans **Collections** > **clients**
2. Cliquez sur l'onglet **Indexes**
3. Vous devriez voir:
   - `idx_clients_userId`
   - `idx_clients_created`

Répétez pour `operations` et `payments`.

## Résolution de Problèmes

### Erreur: "Failed to connect"

- Vérifiez que PocketBase est lancé: `./pocketbase serve`
- Vérifiez l'URL dans `app_constants.dart`
- Si vous testez sur un appareil physique, utilisez l'IP de votre PC au lieu de `127.0.0.1`

### Erreur: "Unauthorized"

- Vérifiez que vous êtes bien authentifié
- Vérifiez que le token n'a pas expiré
- Vérifiez que le `userId` correspond à l'utilisateur connecté

### Erreur: "Failed to create record"

- Vérifiez que tous les champs requis sont fournis
- Vérifiez que le `userId` est correct
- Vérifiez les règles de création dans l'interface admin

### Les collections n'apparaissent pas

- Vérifiez que l'import JSON s'est bien passé
- Essayez de créer les collections manuellement
- Vérifiez les logs de PocketBase dans le terminal

## Commandes Utiles

```bash
# Lancer PocketBase
./pocketbase serve

# Lancer sur un port différent
./pocketbase serve --http=0.0.0.0:8091

# Créer un backup
./pocketbase export

# Importer un backup
./pocketbase import backup.zip

# Voir les logs
./pocketbase serve --debug
```

## Prochaines Étapes

Une fois PocketBase configuré:

1. ✅ Lancez votre app Flutter
2. ✅ Testez la connexion
3. ✅ Créez quelques clients de test
4. ✅ Créez des opérations
5. ✅ Testez les paiements
6. ✅ Vérifiez que les statistiques se calculent correctement

## Support

- Documentation PocketBase: https://pocketbase.io/docs/
- Discord: https://discord.gg/pocketbase
- GitHub Issues: https://github.com/pocketbase/pocketbase/issues


SELECT 
  u.id,
  COALESCE(SUM(CASE WHEN o.type = 'retraitUv' THEN o.amount WHEN o.type = 'approvisionnementUv' THEN o.amount ELSE -o.amount END), 0) as uvBalance,
  COALESCE(SUM(CASE WHEN o.type = 'retraitUv' THEN -o.amount WHEN o.type = 'approvisionnementEspece' THEN o.amount WHEN o.type = 'approvisionnementUv' THEN 0 WHEN o.isPaid = 1 THEN o.amount ELSE 0 END), 0) as cashBalance,
  COALESCE((SELECT SUM(c.totalDebt) FROM clients c WHERE c.userId = u.id), 0) as totalDebts
FROM users u
LEFT JOIN operations o ON o.userId = u.id
GROUP BY u.id
