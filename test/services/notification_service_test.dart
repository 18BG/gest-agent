import 'package:glados/glados.dart';
import 'package:gest_agent/models/client.dart';
import 'package:gest_agent/services/notification_service.dart';

/// Générateur de Client pour les tests property-based
extension ClientGenerator on Any {
  Generator<Client> get client => combine5(
        any.nonEmptyLetters,
        any.nonEmptyLetters,
        any.positiveIntOrZero,
        any.nonEmptyLetters,
        any.positiveIntOrZero,
        (name, phone, debt, userId, timestamp) => Client(
          id: 'client_${timestamp.abs()}',
          name: name,
          phone: phone,
          totalDebt: debt.toDouble(),
          userId: userId,
          createdAt: DateTime.fromMillisecondsSinceEpoch(
            timestamp.abs() * 1000 + 1609459200000,
          ),
        ),
      );

  /// Générateur de Client avec dette au-dessus du seuil
  Generator<Client> clientWithHighDebt(double threshold) => combine5(
        any.nonEmptyLetters,
        any.nonEmptyLetters,
        any.intInRange(threshold.toInt() + 1, threshold.toInt() * 10 + 100000),
        any.nonEmptyLetters,
        any.positiveIntOrZero,
        (name, phone, debt, userId, timestamp) => Client(
          id: 'client_${timestamp.abs()}',
          name: name,
          phone: phone,
          totalDebt: debt.toDouble(),
          userId: userId,
          createdAt: DateTime.fromMillisecondsSinceEpoch(
            timestamp.abs() * 1000 + 1609459200000,
          ),
        ),
      );

  /// Générateur de Client avec dette en-dessous ou égale au seuil
  Generator<Client> clientWithLowDebt(double threshold) => combine5(
        any.nonEmptyLetters,
        any.nonEmptyLetters,
        any.intInRange(0, threshold.toInt()),
        any.nonEmptyLetters,
        any.positiveIntOrZero,
        (name, phone, debt, userId, timestamp) => Client(
          id: 'client_${timestamp.abs()}',
          name: name,
          phone: phone,
          totalDebt: debt.toDouble(),
          userId: userId,
          createdAt: DateTime.fromMillisecondsSinceEpoch(
            timestamp.abs() * 1000 + 1609459200000,
          ),
        ),
      );
}

void main() {
  group('NotificationService Debt Threshold', () {
    final notificationService = NotificationService.instance;
    final threshold = notificationService.debtThreshold;

    /// **Feature: wave-agent-simple, Property 9: Notification de dette élevée**
    /// *For any* client dont la dette dépasse le seuil configuré, une notification doit être déclenchée
    /// **Validates: Requirements 6.2**
    Glados(any.clientWithHighDebt(threshold)).test(
      'Property 9: Clients with debt above threshold should trigger notification',
      (client) {
        // La dette du client est au-dessus du seuil
        expect(client.totalDebt > threshold, isTrue,
            reason: 'Test precondition: client debt should be above threshold');

        // shouldNotifyForDebt doit retourner true
        final shouldNotify = notificationService.shouldNotifyForDebt(client);
        expect(shouldNotify, isTrue,
            reason:
                'Client with debt ${client.totalDebt} > threshold $threshold should trigger notification');
      },
    );

    Glados(any.clientWithLowDebt(threshold)).test(
      'Property 9 (inverse): Clients with debt at or below threshold should NOT trigger notification',
      (client) {
        // La dette du client est en-dessous ou égale au seuil
        expect(client.totalDebt <= threshold, isTrue,
            reason:
                'Test precondition: client debt should be at or below threshold');

        // shouldNotifyForDebt doit retourner false
        final shouldNotify = notificationService.shouldNotifyForDebt(client);
        expect(shouldNotify, isFalse,
            reason:
                'Client with debt ${client.totalDebt} <= threshold $threshold should NOT trigger notification');
      },
    );

    test('Debt exactly at threshold should NOT trigger notification', () {
      final client = Client(
        id: 'test_client',
        name: 'Test Client',
        phone: '77 000 00 00',
        totalDebt: threshold,
        userId: 'user1',
        createdAt: DateTime.now(),
      );

      final shouldNotify = notificationService.shouldNotifyForDebt(client);
      expect(shouldNotify, isFalse,
          reason: 'Debt exactly at threshold should NOT trigger notification');
    });

    test('Debt just above threshold should trigger notification', () {
      final client = Client(
        id: 'test_client',
        name: 'Test Client',
        phone: '77 000 00 00',
        totalDebt: threshold + 1,
        userId: 'user1',
        createdAt: DateTime.now(),
      );

      final shouldNotify = notificationService.shouldNotifyForDebt(client);
      expect(shouldNotify, isTrue,
          reason: 'Debt just above threshold should trigger notification');
    });

    test('Zero debt should NOT trigger notification', () {
      final client = Client(
        id: 'test_client',
        name: 'Test Client',
        phone: '77 000 00 00',
        totalDebt: 0,
        userId: 'user1',
        createdAt: DateTime.now(),
      );

      final shouldNotify = notificationService.shouldNotifyForDebt(client);
      expect(shouldNotify, isFalse,
          reason: 'Zero debt should NOT trigger notification');
    });
  });
}
