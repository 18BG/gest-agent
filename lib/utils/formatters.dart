import 'package:intl/intl.dart';

/// Utilitaires de formatage pour l'application Wave Agent
class Formatters {
  // Empêcher l'instanciation
  Formatters._();

  /// Formateur de nombres pour le français
  static final NumberFormat _numberFormat = NumberFormat('#,###', 'fr_FR');

  /// Formate un montant en FCFA
  /// Exemple: 1500000 → "1 500 000 FCFA"
  static String formatFCFA(double amount) {
    return '${_numberFormat.format(amount.round())} FCFA';
  }

  /// Formate un montant en FCFA sans le suffixe
  /// Exemple: 1500000 → "1 500 000"
  static String formatAmount(double amount) {
    return _numberFormat.format(amount.round());
  }

  /// Formate un montant avec signe (+ ou -)
  /// Exemple: 1500000 → "+1 500 000 FCFA" ou "-1 500 000 FCFA"
  static String formatFCFAWithSign(double amount) {
    final sign = amount >= 0 ? '+' : '';
    return '$sign${_numberFormat.format(amount.round())} FCFA';
  }

  /// Formate une date en format court français
  /// Exemple: "25/11/2024"
  static String formatDateShort(DateTime date) {
    return DateFormat('dd/MM/yyyy', 'fr_FR').format(date);
  }

  /// Formate une date avec l'heure
  /// Exemple: "25/11/2024 14:30"
  static String formatDateTime(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm', 'fr_FR').format(date);
  }

  /// Formate l'heure uniquement
  /// Exemple: "14:30"
  static String formatTime(DateTime date) {
    return DateFormat('HH:mm', 'fr_FR').format(date);
  }

  /// Formate une date relative (aujourd'hui, hier, ou date)
  static String formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Aujourd\'hui ${formatTime(date)}';
    } else if (dateOnly == today.subtract(const Duration(days: 1))) {
      return 'Hier ${formatTime(date)}';
    } else {
      return formatDateTime(date);
    }
  }

  /// Formate un numéro de téléphone sénégalais
  /// Exemple: "771234567" → "77 123 45 67"
  static String formatPhone(String phone) {
    // Nettoyer le numéro
    final cleaned = phone.replaceAll(RegExp(r'[^\d]'), '');
    
    if (cleaned.length == 9) {
      // Format: XX XXX XX XX
      return '${cleaned.substring(0, 2)} ${cleaned.substring(2, 5)} ${cleaned.substring(5, 7)} ${cleaned.substring(7, 9)}';
    }
    
    // Retourner tel quel si format non reconnu
    return phone;
  }
}
