# Implementation Plan

## Phase 1: Setup et Structure

- [x] 1. Nettoyer le projet et créer la nouvelle structure





  - [x] 1.1 Supprimer les dossiers `lib/core/`, `lib/data/`, `lib/domain/`, `lib/presentation/`


  - [x] 1.2 Créer la structure simple : `lib/models/`, `lib/services/`, `lib/screens/`, `lib/widgets/`, `lib/utils/`


  - [x] 1.3 Mettre à jour `pubspec.yaml` - retirer go_router, flutter_riverpod, garder pocketbase et flutter_local_notifications


  - _Requirements: Architecture simple_

- [x] 2. Créer les modèles de données






  - [x] 2.1 Créer `lib/models/user.dart`

  - [x] 2.2 Créer `lib/models/client.dart`



  - [x] 2.3 Créer `lib/models/operation.dart`


  - [x] 2.4 Créer `lib/models/payment.dart`

  - _Requirements: 3.1, 4.1, 5.1, 5.2_

- [x] 2.5 Write property test for round-trip client


  - **Property 8: Round-trip client**
  - **Validates: Requirements 5.2**

- [x] 2.6 Write property test for round-trip operation


  - **Property 7: Round-trip opération**
  - **Validates: Requirements 5.1**

## Phase 2: Services

- [x] 3. Créer le service de base de données





  - [x] 3.1 Créer `lib/services/database_service.dart` avec singleton pattern


  - [x] 3.2 Implémenter les méthodes CRUD pour operations



  - [x] 3.3 Implémenter les méthodes CRUD pour clients

  - [x] 3.4 Implémenter les méthodes CRUD pour payments
  - [x] 3.5 Implémenter `getBalances()` pour calculer UV et Espèces
  - _Requirements: 5.1, 5.2, 5.3_

- [x] 3.6 Write property test for balance calculation


  - **Property 3: Mise à jour des soldes après opération**
  - **Validates: Requirements 3.5**

- [x] 3.7 Write property test for operations sorting

  - **Property 4: Tri des opérations par date**
  - **Validates: Requirements 3.6**


- [x] 3.8 Write property test for clients sorting
  - **Property 5: Tri des clients par dette**
  - **Validates: Requirements 4.2**

- [x] 4. Créer le service d'authentification






  - [x] 4.1 Créer `lib/services/auth_service.dart` avec singleton pattern

  - [x] 4.2 Implémenter `login(email, password)`



  - [x] 4.3 Implémenter `logout()`
  - [x] 4.4 Implémenter `checkSession()` pour restaurer la session
  - _Requirements: 1.1, 1.2, 1.3, 1.4_

- [x] 4.5 Write property test for valid authentication


  - **Property 1: Authentification avec identifiants valides**
  - **Validates: Requirements 1.2**

- [x] 4.6 Write property test for invalid authentication

  - **Property 2: Authentification avec identifiants invalides**
  - **Validates: Requirements 1.3**

- [x] 5. Créer le service de notifications





  - [x] 5.1 Créer `lib/services/notification_service.dart`




  - [x] 5.2 Implémenter `showOperationConfirmation()`
  - [x] 5.3 Implémenter `checkDebtThreshold(client)` pour alerter si dette élevée
  - _Requirements: 6.1, 6.2, 6.3_

- [x] 5.4 Write property test for debt threshold notification


  - **Property 9: Notification de dette élevée**
  - **Validates: Requirements 6.2**

- [x] 6. Checkpoint - Vérifier les services





  - Ensure all tests pass, ask the user if questions arise.

## Phase 3: Écrans Principaux

- [x] 7. Créer l'écran de login





  - [x] 7.1 Créer `lib/screens/login_screen.dart`





  - [x] 7.2 Formulaire simple avec email et mot de passe





  - [x] 7.3 Gestion des erreurs avec SnackBar





  - [x] 7.4 Navigation vers HomeScreen après login réussi





  - _Requirements: 1.1, 1.2, 1.3_

- [x] 8. Créer l'écran d'accueil


  - [x] 8.1 Créer `lib/screens/home_screen.dart`
  - [x] 8.2 Afficher les soldes UV et Espèces
  - [x] 8.3 Afficher le total des dettes
  - [x] 8.4 Bouton "Nouvelle opération"
  - [x] 8.5 Liste des dernières opérations (5 max)
  - [x] 8.6 Bottom navigation bar simple
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5_

- [x] 9. Créer les widgets réutilisables


  - [x] 9.1 Créer `lib/widgets/balance_card.dart` - card simple pour afficher un solde
  - [x] 9.2 Créer `lib/widgets/operation_tile.dart` - ligne d'opération dans une liste
  - [x] 9.3 Créer `lib/widgets/client_tile.dart` - ligne de client dans une liste

  - _Requirements: 2.1, 3.6, 4.2_

## Phase 4: Gestion des Opérations

- [x] 10. Créer l'écran d'ajout d'opération





  - [x] 10.1 Créer `lib/screens/add_operation_screen.dart`








  - [x] 10.2 Dropdown pour le type d'opération





  - [x] 10.3 Champ montant avec validation





  - [x] 10.4 Dropdown pour sélectionner un client (optionnel)





  - [x] 10.5 Checkbox "Opération payée"





  - [x] 10.6 Bouton enregistrer avec feedback





  - [x] 10.7 Notification de confirmation après enregistrement









  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 6.1_

- [x] 11. Créer l'écran liste des opérations
  - [x] 11.1 Créer `lib/screens/operations_screen.dart`
  - [x] 11.2 Liste scrollable des opérations
  - [x] 11.3 Tri par date décroissante
  - [x] 11.4 Pull-to-refresh

  - _Requirements: 3.6_

- [x] 12. Checkpoint - Vérifier les opérations





  - Ensure all tests pass, ask the user if questions arise.

## Phase 5: Gestion des Clients

- [x] 13. Créer l'écran liste des clients






  - [x] 13.1 Créer `lib/screens/clients_screen.dart`




  - [x] 13.2 Barre de recherche simple





  - [x] 13.3 Liste triée par dette décroissante





  - [x] 13.4 FAB pour ajouter un client





  - _Requirements: 4.2_

- [x] 14. Créer l'écran ajout client
  - [x] 14.1 Créer `lib/screens/add_client_screen.dart`
  - [x] 14.2 Champs nom et téléphone
  - [x] 14.3 Validation et enregistrement

  - _Requirements: 4.1_

- [x] 15. Créer l'écran détail client





  - [x] 15.1 Créer `lib/screens/client_detail_screen.dart`



  - [x] 15.2 Afficher infos client et dette totale


  - [x] 15.3 Historique des opérations du client

  - [x] 15.4 Bouton "Enregistrer paiement"
  - [x] 15.5 Formulaire de paiement (montant)
  - _Requirements: 4.3, 4.4_


- [x] 15.6 Write property test for debt reduction

  - **Property 6: Réduction de dette après paiement**
  - **Validates: Requirements 4.4**

## Phase 6: Finalisation

- [x] 16. Configurer l'app principale





  - [x] 16.1 Mettre à jour `lib/main.dart` - initialisation simple



  - [x] 16.2 Mettre à jour `lib/app.dart` - MaterialApp avec thème simple



  - [x] 16.3 Créer `lib/utils/formatters.dart` - formatage montants FCFA





  - _Requirements: Tous_

- [x] 17. Créer le thème simple





  - [x] 17.1 Définir les couleurs (bleu Wave #00A8E8, gris, blanc)


  - [x] 17.2 Configurer le ThemeData minimal


  - _Requirements: UI sobre_
-

- [x] 18. Final Checkpoint - Vérifier l'app complète




  - Ensure all tests pass, ask the user if questions arise.
