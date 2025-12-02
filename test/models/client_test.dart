import 'package:glados/glados.dart';
import 'package:gest_agent/models/client.dart';

/// Générateur de Client pour les tests property-based
extension ClientGenerator on Any {
  Generator<Client> get client => combine5(
        any.nonEmptyLetters,
        any.nonEmptyLetters,
        any.positiveIntOrZero,
        any.nonEmptyLetters,
        any.positiveIntOrZero,
        (name, phone, debt, userId, timestamp) => Client(
          id: 'test_${timestamp.abs()}',
          name: name,
          phone: phone,
          totalDebt: debt.toDouble(),
          userId: userId,
          createdAt: DateTime.fromMillisecondsSinceEpoch(
            timestamp.abs() * 1000 + 1609459200000, // Base: 2021-01-01
          ),
        ),
      );
}

void main() {
  group('Client Model', () {
    /// **Feature: wave-agent-simple, Property 8: Round-trip client**
    /// *For any* client créé puis récupéré depuis PocketBase, les données doivent être identiques
    /// **Validates: Requirements 5.2**
    Glados(any.client).test(
      'Property 8: Round-trip client - toFullJson/fromJson preserves data',
      (client) {
        // Sérialiser vers JSON puis désérialiser
        final json = client.toFullJson();
        final restored = Client.fromJson(json);

        // Vérifier que toutes les données sont préservées
        expect(restored.id, equals(client.id));
        expect(restored.name, equals(client.name));
        expect(restored.phone, equals(client.phone));
        expect(restored.totalDebt, equals(client.totalDebt));
        expect(restored.userId, equals(client.userId));
        // Note: createdAt peut avoir une légère différence de précision ISO8601
        expect(
          restored.createdAt.millisecondsSinceEpoch,
          equals(client.createdAt.millisecondsSinceEpoch),
        );
      },
    );

    test('fromJson handles valid PocketBase record', () {
      final json = {
        'id': 'abc123',
        'name': 'Mamadou Diop',
        'phone': '77 123 45 67',
        'totalDebt': 50000,
        'userId': 'user123',
        'created': '2024-01-15T10:30:00.000Z',
      };

      final client = Client.fromJson(json);

      expect(client.id, equals('abc123'));
      expect(client.name, equals('Mamadou Diop'));
      expect(client.phone, equals('77 123 45 67'));
      expect(client.totalDebt, equals(50000.0));
      expect(client.userId, equals('user123'));
    });

    test('toJson produces valid PocketBase create payload', () {
      final client = Client(
        id: 'abc123',
        name: 'Fatou Sall',
        phone: '77 987 65 43',
        totalDebt: 25000,
        userId: 'user456',
        createdAt: DateTime.now(),
      );

      final json = client.toJson();

      expect(json['name'], equals('Fatou Sall'));
      expect(json['phone'], equals('77 987 65 43'));
      expect(json['totalDebt'], equals(25000));
      expect(json['userId'], equals('user456'));
      // toJson ne doit pas inclure id et created (gérés par PocketBase)
      expect(json.containsKey('id'), isFalse);
      expect(json.containsKey('created'), isFalse);
    });

    test('copyWith creates modified copy', () {
      final original = Client(
        id: 'abc123',
        name: 'Original',
        phone: '77 000 00 00',
        totalDebt: 10000,
        userId: 'user1',
        createdAt: DateTime.now(),
      );

      final modified = original.copyWith(totalDebt: 5000);

      expect(modified.totalDebt, equals(5000));
      expect(modified.name, equals(original.name));
      expect(modified.id, equals(original.id));
    });
  });
}
