import 'package:glados/glados.dart';
import 'package:gest_agent/models/operation.dart';

/// Générateur de OperationType pour les tests property-based
extension OperationTypeGenerator on Any {
  Generator<OperationType> get operationType => any.choose(OperationType.values);
}

/// Générateur de Operation pour les tests property-based
extension OperationGenerator on Any {
  Generator<Operation> get operation => combine6(
        any.nonEmptyLetters,
        any.operationType,
        any.positiveIntOrZero,
        any.bool,
        any.nonEmptyLetters,
        any.positiveIntOrZero,
        (clientId, type, amount, isPaid, userId, timestamp) => Operation(
          id: 'op_${timestamp.abs()}',
          clientId: clientId,
          type: type,
          amount: amount.toDouble(),
          isPaid: isPaid,
          userId: userId,
          createdAt: DateTime.fromMillisecondsSinceEpoch(
            timestamp.abs() * 1000 + 1609459200000, // Base: 2021-01-01
          ),
        ),
      );
}

void main() {
  group('Operation Model', () {
    /// **Feature: wave-agent-simple, Property 7: Round-trip opération**
    /// *For any* opération créée puis récupérée depuis PocketBase, les données doivent être identiques
    /// **Validates: Requirements 5.1**
    Glados(any.operation).test(
      'Property 7: Round-trip operation - toFullJson/fromJson preserves data',
      (operation) {
        // Sérialiser vers JSON puis désérialiser
        final json = operation.toFullJson();
        final restored = Operation.fromJson(json);

        // Vérifier que toutes les données sont préservées
        expect(restored.id, equals(operation.id));
        expect(restored.clientId, equals(operation.clientId));
        expect(restored.type, equals(operation.type));
        expect(restored.amount, equals(operation.amount));
        expect(restored.isPaid, equals(operation.isPaid));
        expect(restored.userId, equals(operation.userId));
        expect(
          restored.createdAt.millisecondsSinceEpoch,
          equals(operation.createdAt.millisecondsSinceEpoch),
        );
      },
    );

    test('fromJson handles valid PocketBase record', () {
      final json = {
        'id': 'op123',
        'clientId': 'client456',
        'type': 'depotUv',
        'amount': 25000,
        'isPaid': true,
        'userId': 'user789',
        'created': '2024-01-15T14:30:00.000Z',
      };

      final operation = Operation.fromJson(json);

      expect(operation.id, equals('op123'));
      expect(operation.clientId, equals('client456'));
      expect(operation.type, equals(OperationType.depotUv));
      expect(operation.amount, equals(25000.0));
      expect(operation.isPaid, isTrue);
      expect(operation.userId, equals('user789'));
    });

    test('toJson produces valid PocketBase create payload', () {
      final operation = Operation(
        id: 'op123',
        clientId: 'client456',
        type: OperationType.transfert,
        amount: 10000,
        isPaid: false,
        userId: 'user789',
        createdAt: DateTime.now(),
      );

      final json = operation.toJson();

      expect(json['clientId'], equals('client456'));
      expect(json['type'], equals('transfert'));
      expect(json['amount'], equals(10000));
      expect(json['isPaid'], isFalse);
      expect(json['userId'], equals('user789'));
      // toJson ne doit pas inclure id et created
      expect(json.containsKey('id'), isFalse);
      expect(json.containsKey('created'), isFalse);
    });

    test('OperationType.fromString handles all types', () {
      expect(OperationType.fromString('venteCredit'),
          equals(OperationType.venteCredit));
      expect(
          OperationType.fromString('transfert'), equals(OperationType.transfert));
      expect(OperationType.fromString('depotUv'), equals(OperationType.depotUv));
      expect(
          OperationType.fromString('retraitUv'), equals(OperationType.retraitUv));
    });

    test('OperationType.label returns correct labels', () {
      expect(OperationType.venteCredit.label, equals('Vente Crédit'));
      expect(OperationType.transfert.label, equals('Transfert'));
      expect(OperationType.depotUv.label, equals('Dépôt UV'));
      expect(OperationType.retraitUv.label, equals('Retrait UV'));
    });

    test('copyWith creates modified copy', () {
      final original = Operation(
        id: 'op123',
        clientId: 'client1',
        type: OperationType.depotUv,
        amount: 5000,
        isPaid: false,
        userId: 'user1',
        createdAt: DateTime.now(),
      );

      final modified = original.copyWith(isPaid: true, amount: 7500);

      expect(modified.isPaid, isTrue);
      expect(modified.amount, equals(7500));
      expect(modified.type, equals(original.type));
      expect(modified.id, equals(original.id));
    });
  });
}
