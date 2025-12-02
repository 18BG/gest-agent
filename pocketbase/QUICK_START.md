# Quick Start - PocketBase pour Wave Money Agent

## 🚀 Démarrage Rapide (5 minutes)

### Étape 1: Télécharger PocketBase (1 min)

**Windows:**
```bash
# Téléchargez depuis: https://github.com/pocketbase/pocketbase/releases
# Extrayez pocketbase.exe dans un dossier
```

**Linux/Mac:**
```bash
wget https://github.com/pocketbase/pocketbase/releases/download/v0.20.0/pocketbase_0.20.0_linux_amd64.zip
unzip pocketbase_0.20.0_linux_amd64.zip
chmod +x pocketbase
```

### Étape 2: Lancer PocketBase (30 sec)

```bash
./pocketbase serve
```

Ouvrez: http://127.0.0.1:8090/_/

### Étape 3: Créer un Compte Admin (30 sec)

1. Remplissez le formulaire de création de compte
2. Cliquez sur "Create"

### Étape 4: Importer les Collections (2 min)

1. Allez dans **Settings** (⚙️) > **Import collections**
2. Ouvrez le fichier `pocketbase/pb_schema.json`
3. Copiez tout le contenu
4. Collez dans la zone de texte
5. Cliquez sur **Review** puis **Confirm**

### Étape 5: Créer un Utilisateur de Test (1 min)

1. Allez dans **Collections** > **users**
2. Cliquez sur **New record**
3. Remplissez:
   - Email: `agent@wave.com`
   - Password: `Test123456!`
   - Name: `Agent Test`
4. Cliquez sur **Create**

### Étape 6: Configurer l'App Flutter (30 sec)

Dans `lib/core/constants/app_constants.dart`:

```dart
class AppConstants {
  static const String pocketbaseUrl = 'http://127.0.0.1:8090';
}
```

### Étape 7: Tester l'App (1 min)

```bash
flutter run
```

Connectez-vous avec:
- Email: `agent@wave.com`
- Password: `Test123456!`

---

## ✅ Vérification

Vous devriez voir:
- ✅ 3 collections dans PocketBase (clients, operations, payments)
- ✅ Connexion réussie dans l'app
- ✅ Dashboard avec 0 UV, 0 Espèces, 0 Dettes

---

## 📱 Test sur Appareil Physique

Si vous testez sur un téléphone/tablette:

1. Trouvez l'IP de votre PC:
   ```bash
   # Windows
   ipconfig
   
   # Linux/Mac
   ifconfig
   ```

2. Mettez à jour l'URL dans `app_constants.dart`:
   ```dart
   static const String pocketbaseUrl = 'http://192.168.1.X:8090';
   ```

3. Assurez-vous que votre appareil est sur le même réseau WiFi

---

## 🔧 Dépannage Rapide

### Erreur: "Failed to connect"
- ✅ Vérifiez que PocketBase est lancé
- ✅ Vérifiez l'URL dans `app_constants.dart`
- ✅ Vérifiez votre pare-feu

### Erreur: "Unauthorized"
- ✅ Vérifiez email/password
- ✅ Vérifiez que l'utilisateur existe dans PocketBase

### Collections non créées
- ✅ Réessayez l'import du schéma
- ✅ Vérifiez les logs de PocketBase dans le terminal

---

## 📚 Documentation Complète

Pour plus de détails, consultez:
- `README.md` - Documentation complète
- `SETUP_GUIDE.md` - Guide détaillé étape par étape
- `SECURITY_RULES.md` - Explication des règles de sécurité
- `INDEXES.md` - Documentation des index de performance

---

## 🎯 Prochaines Étapes

1. ✅ Créez quelques clients de test
2. ✅ Créez des opérations
3. ✅ Testez les paiements
4. ✅ Vérifiez les statistiques
5. ✅ Testez les exports PDF/CSV

---

## 💡 Conseils

- **Développement:** Utilisez `http://127.0.0.1:8090`
- **Test sur appareil:** Utilisez l'IP de votre PC
- **Production:** Déployez sur un serveur avec HTTPS

---

## 🆘 Besoin d'Aide?

- Documentation PocketBase: https://pocketbase.io/docs/
- Discord: https://discord.gg/pocketbase
- GitHub: https://github.com/pocketbase/pocketbase

---

**Temps total: ~5 minutes** ⏱️

Vous êtes prêt à développer! 🎉
