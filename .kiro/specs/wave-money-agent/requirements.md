# Requirements Document - Wave Money Agent

## Introduction

Wave Money Agent est une application mobile Flutter destinée aux agents Wave pour gérer leurs opérations quotidiennes : unités virtuelles (UV), espèces, et dettes clients. L'application fonctionne en mode online/offline avec synchronisation via PocketBase, offre des exports PDF/CSV, des filtres avancés et des notifications locales pour le suivi des dettes.

## Glossaire

- **Agent Wave** : Utilisateur de l'application qui effectue des transactions financières
- **UV (Unités Virtuelles)** : Solde virtuel de l'agent dans le système Wave
- **Espèces** : Argent liquide physique détenu par l'agent
- **Dette Client** : Montant dû par un client à l'agent pour des opérations non payées
- **Opération** : Transaction financière ( vente crédit, transfert, dépôt UV, retrait UV)
- **PocketBase** : Backend BaaS utilisé pour l'authentification et la persistance des données
- **Système** : L'application Wave Money Agent
- **Cache Local** : Stockage Hive pour le mode offline
- **Synchronisation** : Processus bidirectionnel entre PocketBase et le cache local

## Requirements

### Requirement 1 - Authentification Agent

**User Story:** En tant qu'agent Wave, je veux me connecter de manière sécurisée à l'application, afin d'accéder à mes données et opérations personnelles.

#### Acceptance Criteria

1. WHEN l'Agent Wave saisit un email et un mot de passe valides, THE Système SHALL authentifier l'agent via PocketBase et créer une session locale
2. WHEN le token d'authentification expire, THE Système SHALL rafraîchir automatiquement le token sans déconnecter l'agent
3. IF l'authentification échoue après 3 tentatives, THEN THE Système SHALL bloquer temporairement les tentatives pendant 5 minutes
4. WHEN l'Agent Wave ouvre l'application avec une session valide existante, THE Système SHALL restaurer automatiquement la session sans redemander les identifiants
5. WHEN l'Agent Wave se déconnecte, THE Système SHALL supprimer la session locale et le token d'authentification

### Requirement 2 - Gestion des Opérations

**User Story:** En tant qu'agent Wave, je veux enregistrer toutes mes opérations financières, afin de maintenir un suivi précis de mes UV, espèces et dettes clients.

#### Acceptance Criteria

1. WHEN l'Agent Wave crée une opération de type "vente_credit", THE Système SHALL décrémenter les UV du montant, incrémenter les espèces si payé, et incrémenter la dette client si non payé
2. WHEN l'Agent Wave crée une opération de type "transfert", THE Système SHALL décrémenter les UV du montant, incrémenter les espèces si payé, et incrémenter la dette client si non payé
3. WHEN l'Agent Wave crée une opération de type "depot_uv", THE Système SHALL décrémenter les UV du montant, incrémenter les espèces si payé, et incrémenter la dette client si non payé
4. WHEN l'Agent Wave crée une opération de type "retrait_uv", THE Système SHALL incrémenter les UV du montant et décrémenter les espèces du montant
6. WHEN une opération est créée, THE Système SHALL persister l'opération dans PocketBase et dans le cache local Hive
7. WHEN l'Agent Wave modifie une opération existante, THE Système SHALL recalculer les UV, espèces et dettes selon les nouvelles valeurs
8. WHEN l'Agent Wave supprime une opération, THE Système SHALL inverser les effets de l'opération sur les UV, espèces et dettes

### Requirement 3 - Gestion des Clients

**User Story:** En tant qu'agent Wave, je veux gérer mes clients et leurs dettes, afin de suivre qui me doit de l'argent et combien.

#### Acceptance Criteria

1. WHEN l'Agent Wave crée un nouveau client, THE Système SHALL enregistrer le nom, téléphone et initialiser la dette totale à zéro
2. WHEN l'Agent Wave consulte la liste des clients, THE Système SHALL afficher tous les clients avec leur dette actuelle triés par dette décroissante
3. WHEN l'Agent Wave sélectionne un client, THE Système SHALL afficher les détails du client incluant l'historique des opérations impayées et des paiements
4. WHEN l'Agent Wave modifie les informations d'un client, THE Système SHALL mettre à jour les données dans PocketBase et le cache local
5. WHEN l'Agent Wave supprime un client avec une dette supérieure à zéro, THE Système SHALL afficher un avertissement et demander confirmation

### Requirement 4 - Paiement des Dettes Clients

**User Story:** En tant qu'agent Wave, je veux enregistrer les paiements de mes clients, afin de réduire leurs dettes et mettre à jour mes espèces.

#### Acceptance Criteria

1. WHEN l'Agent Wave enregistre un paiement client, THE Système SHALL incrémenter les espèces du montant payé
2. WHEN l'Agent Wave enregistre un paiement client, THE Système SHALL décrémenter la dette du client du montant payé avec un minimum de zéro
3. WHEN l'Agent Wave enregistre un paiement client, THE Système SHALL persister le paiement dans PocketBase avec la date et l'heure
4. IF un paiement dépasse la dette actuelle du client, THEN THE Système SHALL limiter le paiement au montant de la dette et afficher un avertissement
5. WHEN un paiement est enregistré, THE Système SHALL envoyer une notification locale confirmant le paiement

### Requirement 5 - Synchronisation Online/Offline

**User Story:** En tant qu'agent Wave, je veux que l'application fonctionne sans connexion internet, afin de continuer à travailler même dans des zones sans réseau.

#### Acceptance Criteria

1. WHEN l'application démarre avec une connexion internet, THE Système SHALL synchroniser toutes les données depuis PocketBase vers le cache local Hive
2. WHILE l'Agent Wave est hors ligne, THE Système SHALL enregistrer toutes les opérations dans le cache local uniquement
3. WHEN la connexion internet est rétablie, THE Système SHALL synchroniser automatiquement toutes les opérations locales vers PocketBase
4. IF un conflit de synchronisation est détecté, THEN THE Système SHALL prioriser les données du serveur et notifier l'agent du conflit
5. WHEN l'Agent Wave consulte ses données hors ligne, THE Système SHALL afficher les données du cache local avec un indicateur de statut offline

### Requirement 6 - Dashboard et Statistiques

**User Story:** En tant qu'agent Wave, je veux voir un tableau de bord avec mes totaux, afin d'avoir une vue d'ensemble rapide de ma situation financière.

#### Acceptance Criteria

1. WHEN l'Agent Wave ouvre le dashboard, THE Système SHALL calculer et afficher le total des UV basé sur toutes les opérations
2. WHEN l'Agent Wave ouvre le dashboard, THE Système SHALL calculer et afficher le total des espèces basé sur toutes les opérations et paiements
3. WHEN l'Agent Wave ouvre le dashboard, THE Système SHALL calculer et afficher le total des dettes clients en sommant toutes les dettes individuelles
4. WHEN les données changent suite à une opération ou un paiement, THE Système SHALL mettre à jour automatiquement les totaux du dashboard
5. WHEN l'Agent Wave rafraîchit le dashboard, THE Système SHALL recalculer tous les totaux depuis les données sources

### Requirement 7 - Export PDF et CSV

**User Story:** En tant qu'agent Wave, je veux exporter mes données en PDF et CSV, afin de partager des rapports ou faire des analyses externes.

#### Acceptance Criteria

1. WHEN l'Agent Wave demande un export CSV des opérations, THE Système SHALL générer un fichier CSV contenant toutes les opérations avec leurs détails
2. WHEN l'Agent Wave demande un export PDF des dettes clients, THE Système SHALL générer un document PDF formaté listant tous les clients avec leurs dettes
3. WHEN l'Agent Wave applique des filtres avant l'export, THE Système SHALL exporter uniquement les données filtrées
4. WHEN l'Agent Wave demande un export PDF, THE Système SHALL inclure la date de génération et les totaux calculés
5. WHEN un export est généré, THE Système SHALL permettre le partage du fichier via les applications natives du système

### Requirement 8 - Recherche et Filtrage

**User Story:** En tant qu'agent Wave, je veux filtrer et rechercher mes opérations, afin de trouver rapidement des transactions spécifiques.

#### Acceptance Criteria

1. WHEN l'Agent Wave saisit un nom de client dans la recherche, THE Système SHALL afficher uniquement les opérations liées à ce client
2. WHEN l'Agent Wave sélectionne un type d'opération dans le filtre, THE Système SHALL afficher uniquement les opérations de ce type
3. WHEN l'Agent Wave sélectionne un intervalle de dates, THE Système SHALL afficher uniquement les opérations dans cette période
4. WHEN l'Agent Wave active le filtre "non payé", THE Système SHALL afficher uniquement les opérations où isPaid est false
5. WHEN l'Agent Wave combine plusieurs filtres, THE Système SHALL appliquer tous les filtres simultanément avec une logique ET

### Requirement 9 - Notifications Locales

**User Story:** En tant qu'agent Wave, je veux recevoir des notifications pour les dettes importantes, afin de ne pas oublier de relancer mes clients.

#### Acceptance Criteria

1. WHEN une dette client dépasse 50000 FCFA pendant plus de 7 jours, THE Système SHALL envoyer une notification locale de rappel
2. WHEN l'Agent Wave enregistre une nouvelle opération, THE Système SHALL envoyer une notification locale confirmant l'enregistrement
3. WHEN l'Agent Wave enregistre un paiement client, THE Système SHALL envoyer une notification locale avec le montant et le nouveau solde de dette
4. WHEN l'Agent Wave ouvre une notification, THE Système SHALL naviguer vers la page de détails correspondante
5. WHERE les notifications sont activées dans les paramètres, THE Système SHALL respecter les préférences de notification de l'agent

### Requirement 10 - Validation et Gestion des Erreurs

**User Story:** En tant qu'agent Wave, je veux que l'application valide mes saisies et gère les erreurs proprement, afin d'éviter les erreurs de données.

#### Acceptance Criteria

1. WHEN l'Agent Wave saisit un montant négatif ou zéro, THE Système SHALL afficher un message d'erreur et empêcher la soumission
2. WHEN l'Agent Wave tente de créer une opération sans sélectionner de client, THE Système SHALL afficher un message d'erreur et empêcher la soumission
3. IF une erreur réseau survient pendant une synchronisation, THEN THE Système SHALL afficher un message d'erreur clair et proposer de réessayer
4. WHEN une opération échoue côté PocketBase, THE Système SHALL conserver les données localement et marquer l'opération pour synchronisation ultérieure
5. WHEN l'Agent Wave tente de supprimer une opération synchronisée, THE Système SHALL demander confirmation avant suppression
