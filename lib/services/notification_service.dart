import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/client.dart';
import '../utils/constants.dart';

/// Service de notifications avec singleton pattern
/// Gère les notifications locales pour l'agent Wave
///
/// Requirements: 6.1, 6.2, 6.3
class NotificationService {
  // Singleton instance
  static final NotificationService _instance = NotificationService._internal();
  static NotificationService get instance => _instance;

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// Seuil de dette pour déclencher une notification (en FCFA)
  /// Configurable selon les besoins de l'agent
  double debtThreshold = AppConstants.debtThreshold;

  /// Vérifie si le service est initialisé
  bool get isInitialized => _isInitialized;

  /// Initialise le service de notifications
  /// Doit être appelé au démarrage de l'app
  Future<void> init() async {
    if (_isInitialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(initSettings);
    _isInitialized = true;
  }


  /// Affiche une notification de confirmation d'opération
  ///
  /// Requirements: 6.1
  Future<void> showOperationConfirmation({
    required String operationType,
    required double amount,
    String? clientName,
  }) async {
    if (!_isInitialized) await init();

    final String title = 'Opération enregistrée';
    final String body = clientName != null
        ? '$operationType de ${_formatAmount(amount)} pour $clientName'
        : '$operationType de ${_formatAmount(amount)}';

    await _showNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
    );
  }

  /// Vérifie si la dette d'un client dépasse le seuil et notifie si nécessaire
  /// Retourne true si une notification a été envoyée
  ///
  /// Requirements: 6.2
  Future<bool> checkDebtThreshold(Client client) async {
    if (!shouldNotifyForDebt(client)) {
      return false;
    }

    if (!_isInitialized) await init();

    await _showNotification(
      id: client.id.hashCode,
      title: 'Alerte dette élevée',
      body: '${client.name} a une dette de ${_formatAmount(client.totalDebt)}',
    );

    return true;
  }

  /// Vérifie si un client doit déclencher une notification de dette
  /// Méthode pure pour faciliter les tests
  bool shouldNotifyForDebt(Client client) {
    return client.totalDebt > debtThreshold;
  }

  /// Affiche une notification locale
  Future<void> _showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'wave_agent_channel',
      'Wave Agent',
      channelDescription: 'Notifications pour l\'agent Wave',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(id, title, body, details);
  }

  /// Formate un montant en FCFA
  String _formatAmount(double amount) {
    return '${amount.toStringAsFixed(0)} FCFA';
  }
}
