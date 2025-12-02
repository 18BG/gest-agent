import 'package:flutter/material.dart';

/// Constantes de l'application Wave Agent
class AppConstants {
  // Empêcher l'instanciation
  AppConstants._();

  /// URL du serveur PocketBase
  /// Pour le développement local: http://127.0.0.1:8090
  /// Pour Android emulator: http://10.0.2.2:8090
  /// Pour production: remplacer par l'URL du serveur
//  static const String pocketbaseUrl = 'http://10.0.2.2:8090';
  static const String pocketbaseUrl = 'https://agent.relais.dev';
  /// Seuil de dette pour déclencher une notification (en FCFA)
  static const double debtThreshold = 50000;
}

/// Palette de couleurs Wave Agent
/// Design sobre: bleu Wave, gris, blanc
class WaveColors {
  WaveColors._();

  /// Couleur principale Wave - Bleu #00A8E8
  static const Color primary = Color(0xFF00A8E8);
  
  /// Couleur primaire foncée pour contraste
  static const Color primaryDark = Color(0xFF0088C0);
  
  /// Couleur primaire claire pour backgrounds
  static const Color primaryLight = Color(0xFFE0F4FC);

  /// Blanc - fond principal
  static const Color white = Color(0xFFFFFFFF);
  
  /// Gris très clair - fond secondaire
  static const Color greyLight = Color(0xFFF5F5F5);
  
  /// Gris moyen - bordures et séparateurs
  static const Color grey = Color(0xFFBDBDBD);
  
  /// Gris foncé - texte secondaire
  static const Color greyDark = Color(0xFF757575);

  /// Noir - texte principal
  static const Color textPrimary = Color(0xFF212121);
  
  /// Gris - texte secondaire
  static const Color textSecondary = Color(0xFF757575);

  /// Vert succès - pour les confirmations
  static const Color success = Color(0xFF4CAF50);
  
  /// Rouge erreur - pour les dettes et erreurs
  static const Color error = Color(0xFFE53935);
  
  /// Orange avertissement
  static const Color warning = Color(0xFFFF9800);
}

/// Constantes pour les types d'opérations
class OperationTypes {
  OperationTypes._();

  static const String depotUv = 'depot_uv';
  static const String retraitUv = 'retrait_uv';
  static const String transfert = 'transfert';
  static const String venteCredit = 'vente_credit';
}
