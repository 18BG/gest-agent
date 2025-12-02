# Configuration PocketBase - Wave Money Agent

## 🎯 Démarrage Rapide

Toute la configuration PocketBase se trouve dans le dossier `pocketbase/`.

### 📖 Commencez ici:
👉 **[pocketbase/QUICK_START.md](pocketbase/QUICK_START.md)** - Configuration en 5 minutes

### 📚 Documentation Complète:
👉 **[pocketbase/INDEX.md](pocketbase/INDEX.md)** - Table des matières complète

---

## 🚀 Installation Rapide

### 1. Télécharger PocketBase
```bash
# Windows: Téléchargez depuis https://github.com/pocketbase/pocketbase/releases
# Linux/Mac:
wget https://github.com/pocketbase/pocketbase/releases/download/v0.20.0/pocketbase_0.20.0_linux_amd64.zip
unzip pocketbase_0.20.0_linux_amd64.zip
chmod +x pocketbase
```

### 2. Lancer PocketBase
```bash
./pocketbase serve
```

### 3. Configurer (Interface Web)
1. Ouvrez http://127.0.0.1:8090/_/
2. Créez un compte admin
3. Allez dans Settings > Import collections
4. Importez le fichier `pocketbase/pb_schema.json`

### 4. Créer un Utilisateur de Test
- Email: `agent@wave.com`
- Password: `Test123456!`

### 5. Configurer l'App Flutter
Dans `lib/core/constants/app_constants.dart`:
```dart
static const String pocketbaseUrl = 'http://127.0.0.1:8090';
```

---

## 📁 Fichiers de Configuration

```
pocketbase/
├── QUICK_START.md              # ⭐ Démarrage rapide (5 min)
├── INDEX.md                    # 📋 Table des matières
├── SETUP_GUIDE.md              # 📖 Guide détaillé
├── README.md                   # 📚 Documentation complète
├── SECURITY_RULES.md           # 🔒 Règles de sécurité
├── INDEXES.md                  # ⚡ Index de performance
├── pb_schema.json              # 📄 Schéma des collections
├── test_configuration.dart     # 🧪 Script de test
└── migrations/
    └── 1732464000_create_collections.js
```

---

## ✅ Collections Créées

1. **clients** - Informations clients et dettes
2. **operations** - Opérations Wave (vente crédit, transfert, dépôt UV, retrait UV)
3. **payments** - Paiements de dettes

---

## 🔐 Sécurité

- ✅ Isolation complète des données par utilisateur
- ✅ Règles de sécurité sur toutes les collections
- ✅ Cascade delete pour les relations
- ✅ Validation des données

---

## ⚡ Performance

- ✅ 9 index créés pour optimiser les requêtes
- ✅ Temps de réponse < 100ms
- ✅ Scalable jusqu'à des milliers d'enregistrements

---

## 🧪 Test de la Configuration

```bash
dart run pocketbase/test_configuration.dart
```

---

## 📱 URLs de Configuration

**Développement local:**
```dart
static const String pocketbaseUrl = 'http://127.0.0.1:8090';
```

**Test sur appareil physique:**
```dart
static const String pocketbaseUrl = 'http://192.168.1.X:8090';
```

**Production:**
```dart
static const String pocketbaseUrl = 'https://votre-domaine.com';
```

---

## 🆘 Besoin d'Aide?

- **Démarrage rapide:** [pocketbase/QUICK_START.md](pocketbase/QUICK_START.md)
- **Guide détaillé:** [pocketbase/SETUP_GUIDE.md](pocketbase/SETUP_GUIDE.md)
- **Documentation PocketBase:** https://pocketbase.io/docs/
- **Discord:** https://discord.gg/pocketbase

---

## 📝 Prochaines Étapes

Après avoir configuré PocketBase:

1. ✅ Lancez l'app Flutter: `flutter run`
2. ✅ Connectez-vous avec l'utilisateur de test
3. ✅ Créez des clients
4. ✅ Enregistrez des opérations
5. ✅ Testez les paiements
6. ✅ Vérifiez les statistiques

---

**Temps de configuration: ~5 minutes** ⏱️

**Bon développement!** 🚀
