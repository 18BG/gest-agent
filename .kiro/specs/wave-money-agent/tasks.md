# Implementation Plan - Wave Money Agent

- [x] 1. Configuration initiale du projet





  - Configurer pubspec.yaml avec toutes les dépendances (riverpod, dio, hive, pocketbase, go_router, pdf, csv, flutter_local_notifications)
  - Initialiser Hive dans main.dart
  - Créer la structure de dossiers complète (core, data, domain, presentation)
  - _Requirements: 1.1, 5.1_

- [x] 2. Modèles de domaine et enums





  - [x] 2.1 Créer WaveOperationType enum avec displayName


    - Définir les 4 types : venteCredit, transfert, depotUv, retraitUv
    - Implémenter la méthode displayName pour l'affichage
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5_
  
  - [x] 2.2 Créer le modèle WaveOperation


    - Implémenter toJson(), fromJson(), copyWith() manuellement
    - Ajouter tous les champs : id, clientId, type, amount, isPaid, createdAt, updatedAt
    - _Requirements: 2.1, 2.6_
  
  - [x] 2.3 Créer le modèle Client


    - Implémenter toJson(), fromJson(), copyWith() manuellement
    - Champs : id, name, phone, totalDebt, createdAt, updatedAt
    - _Requirements: 3.1_
  
  - [x] 2.4 Créer le modèle ClientPayment


    - Implémenter toJson(), fromJson() manuellement
    - Champs : id, clientId, amount, createdAt
    - _Requirements: 4.1, 4.3_
  


  - [x] 2.5 Créer le modèle WaveStats





    - Implémenter copyWith()
    - Champs : totalUv, totalEspece, totalClientDebts


    - _Requirements: 6.1, 6.2, 6.3_
  
  - [x] 2.6 Créer le modèle User





    - Implémenter toJson(), fromJson() pour l'authentification
    - Champs : id, email, name
    - _Requirements: 1.1_

- [x] 3. Règles métier Wave









  - [x] 3.1 Implémenter OperationEffects calculator


    - Créer la classe OperationEffects avec uvDelta, especeDelta, debtDelta
    - Implémenter calculate() avec switch sur WaveOperationType
    - Appliquer les règles exactes du tableau métier
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5_
  
  - [x] 3.2 Implémenter StatsCalculator


    - Créer la méthode calculate() qui parcourt opérations et paiements
    - Calculer totalUv, totalEspece, totalClientDebts
    - _Requirements: 6.1, 6.2, 6.3, 6.4_


- [x] 4. Interfaces des repositories






  - [x] 4.1 Créer OperationRepository interface

    - Méthodes : getAllOperations, getOperationsByClient, addOperation, updateOperation, deleteOperation, watchOperations
    - _Requirements: 2.6, 2.7, 2.8_
  

  - [x] 4.2 Créer ClientRepository interface

    - Méthodes : getAllClients, getClientById, addClient, updateClient, deleteClient, watchClients
    - _Requirements: 3.1, 3.2, 3.4, 3.5_
  

  - [x] 4.3 Créer PaymentRepository interface

    - Méthodes : getPaymentsByClient, addPayment, watchPayments
    - _Requirements: 4.1, 4.3_
  

  - [x] 4.4 Créer StatsRepository interface

    - Méthodes : getStats, watchStats
    - _Requirements: 6.1, 6.2, 6.3, 6.5_
  

  - [x] 4.5 Créer AuthRepository interface

    - Méthodes : signIn, signOut, getCurrentUser, refreshSession, watchAuthState
    - _Requirements: 1.1, 1.2, 1.4, 1.5_

- [x] 5. PocketBase datasources





  - [x] 5.1 Créer PbClient singleton


    - Initialiser PocketBase avec baseUrl
    - Implémenter auto-refresh du token avec authStore.onChange
    - Gérer l'expiration et le refresh automatique
    - _Requirements: 1.1, 1.2_
  
  - [x] 5.2 Créer PbAuthDatasource


    - Implémenter signIn avec collection users
    - Implémenter signOut et authRefresh
    - Gérer les erreurs d'authentification
    - _Requirements: 1.1, 1.3, 1.5_
  
  - [x] 5.3 Créer PbOperationsDatasource


    - Implémenter getAll avec sort par createdAt
    - Implémenter create, update, delete
    - Mapper les records PocketBase vers WaveOperation
    - _Requirements: 2.6, 2.7, 2.8_
  
  - [x] 5.4 Créer PbClientsDatasource


    - Implémenter CRUD complet pour clients
    - Mapper les records vers Client model
    - _Requirements: 3.1, 3.4, 3.5_
  
  - [x] 5.5 Créer PbPaymentsDatasource


    - Implémenter getByClient et create
    - Mapper vers ClientPayment model
    - _Requirements: 4.1, 4.3_

- [x] 6. Hive datasources locales





  - [x] 6.1 Créer HiveService pour initialisation


    - Initialiser Hive avec getApplicationDocumentsDirectory
    - Ouvrir les boxes nécessaires
    - _Requirements: 5.1_


  
  - [ ] 6.2 Créer LocalOperationsDatasource
    - Implémenter getAll, save, delete avec Hive Box<Map>
    - Implémenter watchAll avec box.watch()


    - Stocker les opérations en JSON Map
    - _Requirements: 5.2, 5.3_
  


  - [ ] 6.3 Créer LocalClientsDatasource
    - Implémenter CRUD local pour clients


    - Utiliser Hive Box<Map>
    - _Requirements: 5.2, 5.3_
  
  - [ ] 6.4 Créer LocalPaymentsDatasource
    - Implémenter stockage local des paiements
    - _Requirements: 5.2, 5.3_
  
  - [ ] 6.5 Créer LocalAuthDatasource
    - Stocker le token et user info localement
    - Implémenter saveToken, getToken, clearToken
    - _Requirements: 1.4_

- [x] 7. Implémentation des repositories





  - [x] 7.1 Implémenter OperationRepositoryImpl


    - Injecter PbOperationsDatasource et LocalOperationsDatasource
    - Stratégie : écrire sur PocketBase puis cache local, lire depuis cache
    - Implémenter _updateClientDebt() pour appliquer les effets d'opération
    - Gérer le mode offline avec flag needsSync
    - _Requirements: 2.6, 2.7, 2.8, 5.2, 5.3, 5.4_
  
  - [x] 7.2 Implémenter ClientRepositoryImpl


    - Stratégie similaire : remote puis local
    - Implémenter toutes les méthodes CRUD
    - _Requirements: 3.1, 3.2, 3.4, 3.5, 5.2, 5.3_
  
  - [x] 7.3 Implémenter PaymentRepositoryImpl


    - Lors d'addPayment, mettre à jour espèces et dette client
    - Appliquer la règle : espèces += amount, dette -= amount
    - _Requirements: 4.1, 4.2, 4.3, 4.4, 5.2, 5.3_
  
  - [x] 7.4 Implémenter StatsRepositoryImpl


    - Utiliser StatsCalculator pour calculer les stats
    - Récupérer toutes les opérations, paiements et clients
    - Implémenter watchStats avec combineLatest des streams
    - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5_
  
  - [x] 7.5 Implémenter AuthRepositoryImpl


    - Implémenter signIn avec PbAuthDatasource
    - Sauvegarder le token localement
    - Implémenter getCurrentUser depuis cache local
    - Gérer refreshSession automatiquement
    - _Requirements: 1.1, 1.2, 1.4, 1.5_


- [x] 8. Providers Riverpod





  - [x] 8.1 Créer repositories providers


    - Créer pbClientProvider
    - Créer operationRepositoryProvider, clientRepositoryProvider, paymentRepositoryProvider
    - Créer statsRepositoryProvider, authRepositoryProvider
    - _Requirements: Tous_
  
  - [x] 8.2 Créer AuthNotifier et authNotifierProvider


    - Implémenter StateNotifier<AsyncValue<User?>>
    - Méthodes : signIn, signOut, _init
    - Créer authStateProvider (StreamProvider)
    - _Requirements: 1.1, 1.4, 1.5_
  
  - [x] 8.3 Créer OperationsNotifier et providers


    - Implémenter StateNotifier pour addOperation, updateOperation, deleteOperation
    - Créer operationsProvider (StreamProvider)
    - Créer operationsByClientProvider (FutureProvider.family)
    - _Requirements: 2.6, 2.7, 2.8_
  
  - [x] 8.4 Créer ClientsNotifier et providers


    - Implémenter StateNotifier pour CRUD clients
    - Créer clientsProvider (StreamProvider)
    - Créer clientByIdProvider (FutureProvider.family)
    - _Requirements: 3.1, 3.2, 3.4, 3.5_
  
  - [x] 8.5 Créer PaymentsNotifier et providers


    - Implémenter addPayment dans StateNotifier
    - Créer paymentsProvider pour watch
    - _Requirements: 4.1, 4.3_
  
  - [x] 8.6 Créer statsProvider


    - StreamProvider qui watch les stats
    - _Requirements: 6.1, 6.2, 6.3, 6.5_
  
  - [x] 8.7 Créer FiltersNotifier et filteredOperationsProvider


    - Implémenter StateNotifier<OperationFilters>
    - Méthodes : setClientFilter, setTypeFilter, setDateRange, setPaidFilter, clearFilters
    - Créer filteredOperationsProvider qui applique les filtres
    - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5_

- [x] 9. Services additionnels







  - [x] 9.1 Créer ExportService

    - Implémenter exportOperationsToCSV avec csv package
    - Implémenter exportClientsToCSV
    - Implémenter generateOperationsPDF avec pdf package
    - Implémenter generateClientDebtsPDF
    - Implémenter sharePDF avec share_plus
    - Créer exportServiceProvider
    - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5_
  
  - [x] 9.2 Créer NotificationService


    - Initialiser FlutterLocalNotificationsPlugin
    - Implémenter showOperationNotification
    - Implémenter showPaymentNotification
    - Implémenter showDebtReminderNotification
    - Implémenter scheduleDebtReminders (dette > 50000 FCFA)
    - Créer notificationServiceProvider
    - _Requirements: 9.1, 9.2, 9.3, 9.4, 9.5_

- [x] 10. Navigation et routing




  - [x] 10.1 Créer AppRouter avec GoRouter


    - Configurer toutes les routes : /splash, /auth/login, /home, /operations, /clients, /settings
    - Implémenter redirect logic basé sur authStateProvider
    - Rediriger vers /auth/login si non authentifié
    - Rediriger vers /home si authentifié et sur page auth
    - Créer goRouterProvider
    - _Requirements: 1.1, 1.4_

- [x] 11. Theme et constantes





  - [x] 11.1 Créer AppTheme


    - Définir lightTheme avec Material 3
    - Utiliser Color(0xFF00A8E8) comme seedColor (bleu Wave)
    - Configurer AppBarTheme, CardTheme, InputDecorationTheme
    - _Requirements: Tous (UI)_
  
  - [x] 11.2 Créer AppConstants


    - Définir POCKETBASE_URL
    - Définir limites et constantes métier
    - _Requirements: Tous_
  
  - [x] 11.3 Créer utils (validators, formatters)


    - Créer CurrencyFormatter pour affichage FCFA
    - Créer DateFormatter
    - Créer Validators pour formulaires
    - _Requirements: 10.1, 10.2_

- [x] 12. Widgets réutilisables







  - [x] 12.1 Créer StatCard widget

    - Afficher titre, valeur, icône, couleur
    - Utilisé dans HomePage pour UV, Espèces, Dettes
    - _Requirements: 6.1, 6.2, 6.3_

  
  - [x] 12.2 Créer OperationCard widget

    - Afficher type, montant, client, date, statut payé
    - Utilisé dans listes d'opérations
    - _Requirements: 2.1_
  



  - [x] 12.3 Créer ClientCard widget

    - Afficher nom, téléphone, dette
    - Utilisé dans ClientsListPage
    - _Requirements: 3.2_

  
  - [x] 12.4 Créer CustomButton widget

    - Bouton stylisé réutilisable
    - _Requirements: Tous (UI)_


- [x] 13. Pages d'authentification






  - [x] 13.1 Créer SplashPage

    - Afficher logo d'auto Gestionnaire
    - Vérifier session existante avec authNotifierProvider
    - Rediriger automatiquement vers /home ou /auth/login
    - _Requirements: 1.4_
  


  - [x] 13.2 Créer LoginPage





    - Formulaire email + password
    - Validation des champs
    - Appeler authNotifier.signIn()
    - Afficher erreurs d'authentification
    - Gérer le blocage après 3 tentatives échouées
    - _Requirements: 1.1, 1.3_

- [x] 14. HomePage (Dashboard)





  - [x] 14.1 Créer HomePage


    - Afficher 3 StatCards : UV, Espèces, Dettes
    - Utiliser statsProvider pour les données
    - Afficher boutons d'action rapide : Nouvelle Opération, Gérer Clients, Historique
    - FloatingActionButton pour ajouter opération
    - AppBar avec bouton Settings
    - Gérer les états loading et error
    - _Requirements: 6.1, 6.2, 6.3, 6.4_

- [x] 15. Pages des opérations






  - [x] 15.1 Créer AddOperationPage

    - Formulaire avec DropdownButtonFormField pour type d'opération
    - DropdownButtonFormField pour sélection client
    - TextFormField pour montant avec validation (> 0)
    - CheckboxListTile pour isPaid
    - Validation complète du              formulaire
    - Appeler operationsNotifier.addOperation()
    - Afficher notification après succès
    - Gérer les erreurs réseau
    - _Requirements: 2.6, 9.2, 10.1, 10.2_
  


  - [x] 15.2 Créer OperationsListPage





    - Afficher liste des opérations avec operationsProvider
    - Utiliser OperationCard pour chaque item
    - Implémenter filtres avec filtersProvider
    - Filtres : client, type, date range, isPaid
    - Bouton pour exporter CSV/PDF
    - Pull-to-refresh
    - _Requirements: 2.1, 8.1, 8.2, 8.3, 8.4, 8.5, 7.1_

- [x] 16. Pages des clients





  - [x] 16.1 Créer ClientsListPage


    - Afficher liste des clients avec clientsProvider
    - Utiliser ClientCard pour chaque item
    - Trier par dette décroissante
    - Barre de recherche par nom
    - FloatingActionButton pour ajouter client
    - Navigation vers ClientDetailsPage au tap
    - _Requirements: 3.2_
  
  - [x] 16.2 Créer AddClientPage


    - Formulaire : nom, téléphone
    - Validation des champs
    - Initialiser totalDebt à 0
    - Appeler clientsNotifier.addClient()
    - _Requirements: 3.1, 10.1, 10.2_
  
  - [x] 16.3 Créer ClientDetailsPage


    - Afficher infos client avec clientByIdProvider
    - Afficher dette actuelle en grand
    - Afficher historique des opérations impayées
    - Afficher historique des paiements
    - Bouton "Ajouter Paiement"
    - Bouton "Modifier Client"
    - Afficher avertissement si suppression avec dette > 0
    - _Requirements: 3.3, 3.5_

- [x] 17. Page de paiement




  - [x] 17.1 Créer AddPaymentPage


    - Recevoir clientId en paramètre
    - Afficher nom du client et dette actuelle
    - TextFormField pour montant avec validation
    - Valider que montant <= dette actuelle
    - Appeler paymentsNotifier.addPayment()
    - Afficher notification après succès
    - Mettre à jour automatiquement espèces et dette
    - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 9.3_

- [x] 18. Page des paramètres




  - [x] 18.1 Créer SettingsPage


    - Section Export : boutons pour CSV opérations, CSV clients, PDF dettes
    - Section Notifications : toggle pour activer/désactiver
    - Bouton Déconnexion
    - Afficher version de l'app
    - Appeler exportService pour les exports
    - Appeler authNotifier.signOut() pour déconnexion
    - _Requirements: 1.5, 7.1, 7.2, 7.3, 9.5_

- [x] 19. Configuration de l'app principale





  - [x] 19.1 Créer app.dart


    - Configurer ProviderScope
    - Utiliser goRouterProvider pour MaterialApp.router
    - Appliquer AppTheme
    - Initialiser NotificationService
    - _Requirements: Tous_


  
  - [x] 19.2 Configurer main.dart





    - Initialiser Hive avec HiveService
    - Initialiser PbClient avec URL
    - Initialiser NotificationService
    - Gérer les erreurs Flutter avec runZonedGuarded
    - Lancer l'app avec runApp
    - _Requirements: 1.1, 5.1, 9.1_

- [x] 20. Gestion des erreurs et exceptions







  - [x] 20.1 Créer hiérarchie d'exceptions

    - AppException, NetworkException, AuthException, ValidationException, SyncException
    - _Requirements: 10.3, 10.4, 10.5_
  
  - [x] 20.2 Implémenter gestion d'erreurs dans repositories


    - Try-catch dans toutes les méthodes
    - Convertir erreurs PocketBase en AppException
    - Logger les erreurs
    - _Requirements: 5.4, 10.3_

- [x] 21. Configuration PocketBase





  - [x] 21.1 Créer schémas des collections

    - Créer collection clients avec champs : name, phone, totalDebt, userId
    - Créer collection operations avec champs : clientId, type, amount, isPaid, userId
    - Créer collection payments avec champs : clientId, amount, userId
    - Configurer les relations et cascadeDelete
    - _Requirements: Tous (Backend)_

  


  - [x] 21.2 Configurer les règles de sécurité
    - Règles List/View : userId = @request.auth.id
    - Règles Create : @request.data.userId = @request.auth.id

    - Règles Update/Delete : userId = @request.auth.id
    - Appliquer à toutes les collections
    - _Requirements: Tous (Sécurité)_
  
  - [x] 21.3 Créer les index
    - Index sur userId pour toutes les collections
    - Index sur clientId pour operations et payments
    - Index sur created pour operations
    - _Requirements: Tous (Performance)_

- [ ] 22. Tests et validation
  - [ ] 22.1 Tests unitaires des modèles
    - Tester toJson/fromJson pour tous les modèles
    - Tester copyWith
    - _Requirements: 2.1-2.6_
  
  - [ ] 22.2 Tests unitaires des règles métier
    - Tester OperationEffects.calculate pour chaque type
    - Tester StatsCalculator.calculate
    - _Requirements: 2.1-2.5, 6.1-6.3_
  
  - [ ] 22.3 Tests des repositories
    - Mock des datasources
    - Tester CRUD complet
    - Tester logique de synchronisation
    - _Requirements: 5.1-5.5_

- [ ] 23. Documentation et README
  - [ ] 23.1 Créer README.md complet
    - Instructions d'installation PocketBase
    - Configuration de l'URL dans app_constants.dart
    - Commandes Flutter : flutter pub get, flutter run
    - Build APK/iOS
    - Configuration des notifications
    - _Requirements: Tous_
  
  - [ ] 23.2 Documenter les collections PocketBase
    - Schémas JSON des collections
    - Règles de sécurité
    - Migrations
    - _Requirements: Tous (Backend)_
