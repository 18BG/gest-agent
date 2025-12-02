# Requirements Document

## Introduction

Application mobile simple pour un agent Wave au Sénégal. L'app permet de gérer les opérations quotidiennes (dépôts, retraits, transferts), suivre les soldes (UV et espèces), et gérer les clients avec leurs dettes. L'objectif est une app **simple, rapide et efficace** - pas de design sophistiqué, juste fonctionnel.

## Glossaire

- **Agent Wave** : Personne qui effectue des opérations Wave pour des clients
- **UV** : Unité de Valeur - solde électronique dans le compte Wave de l'agent
- **Espèces** : Argent liquide en caisse
- **Opération** : Transaction effectuée (dépôt, retrait, transfert, achat crédit)
- **Dette** : Montant qu'un client doit à l'agent (opération non payée)
- **PocketBase** : Backend léger utilisé pour stocker les données

## Requirements

### Requirement 1: Authentification Simple

**User Story:** En tant qu'agent, je veux me connecter avec mon email et mot de passe, pour accéder à mon espace de travail.

#### Acceptance Criteria

1. WHEN l'agent lance l'app THEN le système SHALL afficher un écran de connexion avec email et mot de passe
2. WHEN l'agent entre des identifiants valides THEN le système SHALL le rediriger vers l'écran d'accueil
3. WHEN l'agent entre des identifiants invalides THEN le système SHALL afficher un message d'erreur clair
4. WHILE l'agent est connecté THEN le système SHALL maintenir sa session active

### Requirement 2: Dashboard Accueil

**User Story:** En tant qu'agent, je veux voir mes soldes et accéder rapidement aux fonctions principales, pour gérer mon activité efficacement.

#### Acceptance Criteria

1. WHEN l'agent accède à l'accueil THEN le système SHALL afficher le solde UV et le solde Espèces
2. WHEN l'agent accède à l'accueil THEN le système SHALL afficher le total des dettes clients
3. WHEN l'agent tape sur "Nouvelle opération" THEN le système SHALL ouvrir le formulaire d'ajout
4. WHEN l'agent tape sur "Clients" THEN le système SHALL afficher la liste des clients
5. WHEN l'agent tape sur "Opérations" THEN le système SHALL afficher l'historique des opérations

### Requirement 3: Gestion des Opérations

**User Story:** En tant qu'agent, je veux enregistrer mes opérations rapidement, pour garder une trace de mon activité.

#### Acceptance Criteria

1. WHEN l'agent crée une opération THEN le système SHALL demander le type (dépôt, retrait, transfert, achat crédit)
2. WHEN l'agent crée une opération THEN le système SHALL demander le montant
3. WHEN l'agent crée une opération THEN le système SHALL permettre de sélectionner un client (optionnel)
4. WHEN l'agent crée une opération THEN le système SHALL permettre de marquer si c'est payé ou dette
5. WHEN une opération est enregistrée THEN le système SHALL mettre à jour les soldes automatiquement
6. WHEN l'agent consulte l'historique THEN le système SHALL afficher les opérations triées par date décroissante

### Requirement 4: Gestion des Clients

**User Story:** En tant qu'agent, je veux gérer ma liste de clients et leurs dettes, pour suivre qui me doit de l'argent.

#### Acceptance Criteria

1. WHEN l'agent ajoute un client THEN le système SHALL demander le nom et le numéro de téléphone
2. WHEN l'agent consulte la liste THEN le système SHALL afficher les clients triés par dette décroissante
3. WHEN l'agent consulte un client THEN le système SHALL afficher son historique d'opérations et sa dette totale
4. WHEN l'agent enregistre un paiement de dette THEN le système SHALL réduire la dette du client

### Requirement 5: Persistance des Données

**User Story:** En tant qu'agent, je veux que mes données soient sauvegardées, pour ne rien perdre.

#### Acceptance Criteria

1. WHEN une opération est créée THEN le système SHALL la sauvegarder dans PocketBase
2. WHEN un client est créé THEN le système SHALL le sauvegarder dans PocketBase
3. WHEN l'agent ouvre l'app THEN le système SHALL charger les données depuis PocketBase

### Requirement 6: Notifications

**User Story:** En tant qu'agent, je veux recevoir des notifications pour les événements importants, pour ne rien manquer.

#### Acceptance Criteria

1. WHEN une opération est enregistrée THEN le système SHALL afficher une notification de confirmation
2. WHEN un client a une dette qui dépasse un seuil THEN le système SHALL notifier l'agent
3. WHEN l'app est en arrière-plan THEN le système SHALL pouvoir envoyer des notifications locales
