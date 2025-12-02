# Design UI Moderne - Wave Money Agent

## 🎨 Philosophie de Design

**Style** : Modern, Clean, Professional avec touches de glassmorphism
**Inspiration** : Applications bancaires modernes (Revolut, N26, Lydia)
**Couleurs** : Dégradés subtils, ombres douces, espaces blancs généreux

---

## 🏠 HOMEPAGE - DASHBOARD MODERNE

### Vision Globale
Un dashboard élégant avec :
- Header avec avatar et salutation personnalisée
- Cards avec glassmorphism et dégradés
- Graphiques visuels pour les stats
- Actions rapides avec icônes modernes
- Bottom navigation bar

### Layout Détaillé

```
┌─────────────────────────────────────────┐
│  👤 Bonjour, [Nom]          🔔 [3]      │ ← Header avec avatar
│  Lundi 25 Novembre 2025                 │
├─────────────────────────────────────────┤
│                                         │
│  ┌───────────────────────────────────┐ │
│  │ 💎 Solde Total                    │ │ ← Card principale avec dégradé
│  │                                   │ │
│  │      1 250 000 FCFA              │ │ ← Gros chiffre
│  │                                   │ │
│  │  📊 +12% ce mois                 │ │ ← Indicateur tendance
│  └───────────────────────────────────┘ │
│                                         │
│  ┌──────────────┐  ┌──────────────┐   │
│  │ 💰 UV        │  │ 💵 Espèces   │   │ ← Cards avec icônes
│  │              │  │              │   │   et mini graphiques
│  │ 850K         │  │ 400K         │   │
│  │ ▁▂▃▅▄▃▂     │  │ ▃▄▅▃▂▁▂     │   │ ← Sparkline
│  └──────────────┘  └──────────────┘   │
│                                         │
│  ┌─────────────────────────────────┐   │
│  │ ⚠️  Dettes à Recouvrer          │   │ ← Card alerte avec
│  │                                 │   │   liste des top 3
│  │  👤 Mamadou Diop      50K FCFA │   │
│  │  👤 Fatou Sall        35K FCFA │   │
│  │  👤 Ibrahima Fall     28K FCFA │   │
│  │                                 │   │
│  │  [Voir tout →]                  │   │
│  └─────────────────────────────────┘   │
│                                         │
│  Actions Rapides                        │
│  ┌────┐ ┌────┐ ┌────┐ ┌────┐          │
│  │ ➕ │ │ 💸 │ │ 👥 │ │ 📊 │          │ ← Boutons ronds
│  │Opé │ │Paie│ │Cli │ │Rap │          │   avec icônes
│  └────┘ └────┘ └────┘ └────┘          │
│                                         │
├─────────────────────────────────────────┤
│  🏠    📋    👥    ⚙️                  │ ← Bottom Nav
└─────────────────────────────────────────┘
```

### Spécifications Techniques

#### Header
```dart
- Padding: 20px top, 16px horizontal
- Avatar: 48x48, CircleAvatar avec image ou initiales
- Salutation: Text 24px, Bold, couleur primaire
- Date: Text 14px, Regular, gris
- Notification badge: 24x24, rouge avec nombre
```

#### Card Solde Total
```dart
- Gradient: LinearGradient [Color(0xFF00A8E8), Color(0xFF0077B6)]
- Border radius: 24px
- Padding: 32px
- Shadow: BoxShadow blur 20, offset (0, 10), color black12
- Montant: 48px, ExtraBold, blanc
- Indicateur: 16px, Medium, blanc70
```

#### Cards UV & Espèces
```dart
- Background: Blanc avec opacity 0.9
- Border: 1px solid gris clair
- Border radius: 20px
- Padding: 20px
- Shadow: BoxShadow blur 10, offset (0, 4)
- Icône: 32x32, couleur thème
- Label: 14px, Medium, gris
- Montant: 28px, Bold, noir
- Sparkline: fl_chart, hauteur 40px
```

#### Card Dettes
```dart
- Background: Orange gradient léger
- Border radius: 20px
- Padding: 20px
- Liste: 3 items max avec avatar, nom, montant
- Avatar: 36x36
- Bouton "Voir tout": TextButton avec flèche
```

#### Actions Rapides
```dart
- Container: 72x72
- Background: Gradient selon action
- Border radius: 20px
- Icône: 32x32, blanc
- Label: 12px, Medium, gris
- Spacing: 12px entre les boutons
```

---

## 📋 OPERATIONS LIST PAGE - MODERNE

### Vision
Liste moderne avec :
- Filtres en chips horizontaux
- Timeline visuelle
- Swipe actions (supprimer, modifier)
- Animations de transition

### Layout

```
┌─────────────────────────────────────────┐
│  ← Opérations              🔍  ⋮        │
├─────────────────────────────────────────┤
│  ○ Tout  ● Payé  ○ Non payé  ○ Filtres │ ← Chips filtres
├─────────────────────────────────────────┤
│                                         │
│  Aujourd'hui                            │
│  ┌─────────────────────────────────┐   │
│  │ 14:30  │ 💸 Transfert           │   │
│  │        │ Mamadou Diop           │   │
│  │        │ 25 000 FCFA    ✓ Payé │   │
│  └─────────────────────────────────┘   │
│                                         │
│  ┌─────────────────────────────────┐   │
│  │ 11:15  │ 💰 Vente Crédit        │   │
│  │        │ Fatou Sall             │   │
│  │        │ 15 000 FCFA    ⚠ Dette│   │
│  └─────────────────────────────────┘   │
│                                         │
│  Hier                                   │
│  ┌─────────────────────────────────┐   │
│  │ 16:45  │ 📥 Dépôt UV            │   │
│  │        │ Ibrahima Fall          │   │
│  │        │ 50 000 FCFA    ✓ Payé │   │
│  └─────────────────────────────────┘   │
│                                         │
│                                    [+]  │ ← FAB moderne
└─────────────────────────────────────────┘
```

### Spécifications

#### Chips Filtres
```dart
- Height: 40px
- Padding: 12px horizontal
- Border radius: 20px
- Active: Gradient bleu, texte blanc
- Inactive: Gris clair, texte gris foncé
- Spacing: 8px
```

#### Card Opération
```dart
- Background: Blanc
- Border radius: 16px
- Padding: 16px
- Shadow: BoxShadow blur 8, offset (0, 2)
- Timeline: Ligne verticale 2px, gris clair
- Heure: 14px, Medium, gris
- Type: 18px, SemiBold, noir
- Client: 14px, Regular, gris
- Montant: 20px, Bold, couleur selon type
- Badge statut: Chip 24px height
```

#### Swipe Actions
```dart
- Swipe left: Supprimer (rouge)
- Swipe right: Modifier (bleu)
- Icon size: 24px
- Animation: Smooth 300ms
```

---

## 👥 CLIENTS LIST PAGE - MODERNE

### Vision
Liste de contacts moderne avec :
- Recherche avec suggestions
- Groupement alphabétique
- Quick actions sur chaque card
- Stats visuelles par client

### Layout

```
┌─────────────────────────────────────────┐
│  ← Clients                 ⋮            │
├─────────────────────────────────────────┤
│  🔍 Rechercher un client...             │
├─────────────────────────────────────────┤
│                                         │
│  Clients avec dettes (3)                │
│  ┌─────────────────────────────────┐   │
│  │ 👤  Mamadou Diop                │   │
│  │     77 123 45 67                │   │
│  │                                 │   │
│  │     Dette: 50 000 FCFA          │   │ ← Barre de progression
│  │     ████████░░ 80%              │   │
│  │                                 │   │
│  │     [💸 Payer]  [📞 Appeler]   │   │ ← Actions rapides
│  └─────────────────────────────────┘   │
│                                         │
│  ┌─────────────────────────────────┐   │
│  │ 👤  Fatou Sall                  │   │
│  │     77 987 65 43                │   │
│  │                                 │   │
│  │     Dette: 35 000 FCFA          │   │
│  │     ██████░░░░ 60%              │   │
│  │                                 │   │
│  │     [💸 Payer]  [📞 Appeler]   │   │
│  └─────────────────────────────────┘   │
│                                         │
│  Tous les clients (12)                  │
│  A                                      │
│  ┌─────────────────────────────────┐   │
│  │ 👤  Abdou Kane        ✓ À jour  │   │
│  └─────────────────────────────────┘   │
│                                         │
│                                    [+]  │
└─────────────────────────────────────────┘
```

### Spécifications

#### Card Client avec Dette
```dart
- Background: Gradient orange léger
- Border: 2px solid orange
- Border radius: 20px
- Padding: 20px
- Avatar: 56x56, avec badge dette
- Nom: 20px, Bold, noir
- Téléphone: 14px, Regular, gris
- Dette: 24px, ExtraBold, orange
- Progress bar: 8px height, rounded, gradient
- Boutons: 36px height, rounded, avec icônes
```

#### Card Client Sans Dette
```dart
- Background: Blanc
- Border: 1px solid gris clair
- Border radius: 16px
- Padding: 16px
- Avatar: 48x48
- Badge "À jour": Vert, 12px
```

---

## 🎨 Système de Couleurs Moderne

```dart
// Gradients principaux
final primaryGradient = LinearGradient(
  colors: [Color(0xFF00A8E8), Color(0xFF0077B6)],
);

final successGradient = LinearGradient(
  colors: [Color(0xFF06D6A0), Color(0xFF00B894)],
);

final warningGradient = LinearGradient(
  colors: [Color(0xFFFFB703), Color(0xFFFB8500)],
);

final dangerGradient = LinearGradient(
  colors: [Color(0xFFEF476F), Color(0xFFD62828)],
);

// Couleurs neutres
final neutral50 = Color(0xFFFAFAFA);
final neutral100 = Color(0xFFF5F5F5);
final neutral200 = Color(0xFFEEEEEE);
final neutral300 = Color(0xFFE0E0E0);
final neutral400 = Color(0xFFBDBDBD);
final neutral500 = Color(0xFF9E9E9E);
final neutral600 = Color(0xFF757575);
final neutral700 = Color(0xFF616161);
final neutral800 = Color(0xFF424242);
final neutral900 = Color(0xFF212121);
```

---

## 🎭 Animations & Micro-interactions

```dart
// Transitions de page
- Hero animations pour les cards
- Fade + Slide pour les listes
- Scale pour les boutons

// Hover states (web/desktop)
- Scale 1.05 sur hover
- Shadow augmentée
- Brightness +10%

// Loading states
- Shimmer effect pour skeleton
- Circular progress avec gradient
- Pulse animation pour refresh

// Success feedback
- Confetti animation
- Checkmark animation
- Haptic feedback
```

---

## 📐 Spacing & Typography

```dart
// Spacing scale
final space4 = 4.0;
final space8 = 8.0;
final space12 = 12.0;
final space16 = 16.0;
final space20 = 20.0;
final space24 = 24.0;
final space32 = 32.0;
final space48 = 48.0;

// Typography scale
final displayLarge = TextStyle(fontSize: 48, fontWeight: FontWeight.w800);
final displayMedium = TextStyle(fontSize: 36, fontWeight: FontWeight.w700);
final headlineLarge = TextStyle(fontSize: 32, fontWeight: FontWeight.w700);
final headlineMedium = TextStyle(fontSize: 28, fontWeight: FontWeight.w600);
final titleLarge = TextStyle(fontSize: 24, fontWeight: FontWeight.w600);
final titleMedium = TextStyle(fontSize: 20, fontWeight: FontWeight.w600);
final bodyLarge = TextStyle(fontSize: 18, fontWeight: FontWeight.w400);
final bodyMedium = TextStyle(fontSize: 16, fontWeight: FontWeight.w400);
final bodySmall = TextStyle(fontSize: 14, fontWeight: FontWeight.w400);
final labelLarge = TextStyle(fontSize: 14, fontWeight: FontWeight.w600);
final labelMedium = TextStyle(fontSize: 12, fontWeight: FontWeight.w600);
```

---

## 🎯 Prochaines Étapes

1. **Créer le nouveau AppTheme** avec gradients et couleurs modernes
2. **Refaire HomePage** avec le nouveau design
3. **Refaire OperationsListPage** avec timeline et swipe actions
4. **Refaire ClientsListPage** avec groupement et quick actions

Prêt à commencer l'implémentation ?
