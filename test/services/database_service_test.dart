// import 'package:glados/glados.dart';
// import 'package:gest_agent/models/operation.dart';
// import 'package:gest_agent/models/client.dart';
// import 'package:gest_agent/models/payment.dart';

// /// Générateur de OperationType pour les tests property-based
// extension OperationTypeGenerator on Any {
//   Generator<OperationType> get operationType =>
//       any.choose(OperationType.values);
// }

// /// Générateur de Operation pour les tests property-based
// extension OperationGenerator on Any {
//   Generator<Operation> get operation => combine6(
//         any.nonEmptyLetters,
//         any.operationType,
//         any.positiveIntOrZero,
//         any.bool,
//         any.nonEmptyLetters,
//         any.positiveIntOrZero,
//         (clientId, type, amount, isPaid, userId, timestamp) => Operation(
//           id: 'op_${timestamp.abs()}',
//           clientId: clientId,
//           type: type,
//           amount: amount.toDouble(),
//           isPaid: isPaid,
//           userId: userId,
//           createdAt: DateTime.fromMillisecondsSinceEpoch(
//             timestamp.abs() * 1000 + 1609459200000,
//           ),
//         ),
//       );
// }

// /// Générateur de Client pour les tests property-based
// extension ClientGenerator on Any {
//   Generator<Client> get client => combine5(
//         any.nonEmptyLetters,
//         any.nonEmptyLetters,
//         any.positiveIntOrZero,
//         any.nonEmptyLetters,
//         any.positiveIntOrZero,
//         (name, phone, debt, userId, timestamp) => Client(
//           id: 'client_${timestamp.abs()}',
//           name: name,
//           phone: phone,
//           totalDebt: debt.toDouble(),
//           userId: userId,
//           createdAt: DateTime.fromMillisecondsSinceEpoch(
//             timestamp.abs() * 1000 + 1609459200000,
//           ),
//         ),
//       );

//   /// Générateur de Client avec dette positive (pour tester les paiements)
//   Generator<Client> get clientWithDebt => combine5(
//         any.nonEmptyLetters,
//         any.nonEmptyLetters,
//         any.intInRange(1, 1000000), // Dette entre 1 et 1 000 000 FCFA
//         any.nonEmptyLetters,
//         any.positiveIntOrZero,
//         (name, phone, debt, userId, timestamp) => Client(
//           id: 'client_${timestamp.abs()}',
//           name: name,
//           phone: phone,
//           totalDebt: debt.toDouble(),
//           userId: userId,
//           createdAt: DateTime.fromMillisecondsSinceEpoch(
//             timestamp.abs() * 1000 + 1609459200000,
//           ),
//         ),
//       );
// }

// /// Générateur de Payment pour les tests property-based
// extension PaymentGenerator on Any {
//   Generator<Payment> get payment => combine4(
//         any.nonEmptyLetters,
//         any.positiveIntOrZero,
//         any.nonEmptyLetters,
//         any.positiveIntOrZero,
//         (clientId, amount, userId, timestamp) => Payment(
//           id: 'payment_${timestamp.abs()}',
//           clientId: clientId,
//           amount: amount.toDouble(),
//           userId: userId,
//           createdAt: DateTime.fromMillisecondsSinceEpoch(
//             timestamp.abs() * 1000 + 1609459200000,
//           ),
//         ),
//       );
// }

// /// Calcule les soldes à partir d'une liste d'opérations (logique pure)
// /// Cette fonction reproduit la logique de DatabaseService.getBalances()
// Map<String, double> calculateBalances(List<Operation> operations) {
//   double uvBalance = 0;
//   double cashBalance = 0;

//   for (final op in operations) {
//     switch (op.type) {
//       case OperationType.depotUv:
//         if (op.isPaid) {
//           cashBalance += op.amount;
//         }
//         uvBalance -= op.amount;
//         break;

//       case OperationType.retraitUv:
//         cashBalance -= op.amount;
//         uvBalance += op.amount;
//         break;

//       case OperationType.transfert:
//         uvBalance -= op.amount;
//         if (op.isPaid) {
//           cashBalance += op.amount;
//         }
//         break;

//       case OperationType.venteCredit:
//         if (op.isPaid) {
//           cashBalance += op.amount;
//         }
//         break;
//     }
//   }

//   return {'uv': uvBalance, 'cash': cashBalance};
// }

// /// Trie les opérations par date décroissante (logique pure)
// List<Operation> sortOperationsByDate(List<Operation> operations) {
//   final sorted = List<Operation>.from(operations);
//   sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
//   return sorted;
// }

// /// Trie les clients par dette décroissante (logique pure)
// List<Client> sortClientsByDebt(List<Client> clients) {
//   final sorted = List<Client>.from(clients);
//   sorted.sort((a, b) => b.totalDebt.compareTo(a.totalDebt));
//   return sorted;
// }

// /// Calcule la nouvelle dette après un paiement (logique pure)
// /// Reproduit la logique de DatabaseService.createPayment()
// /// La dette ne peut pas être négative (clamp à 0)
// double calculateDebtAfterPayment(double currentDebt, double paymentAmount) {
//   return (currentDebt - paymentAmount).clamp(0.0, double.infinity);
// }

// void main() {
//   group('DatabaseService Balance Calculation', () {
//     /// **Feature: wave-agent-simple, Property 3: Mise à jour des soldes après opération**
//     /// *For any* opération créée, les soldes UV et Espèces doivent être recalculés correctement selon le type d'opération
//     /// **Validates: Requirements 3.5**
//     Glados(any.list(any.operation)).test(
//       'Property 3: Balance calculation is consistent with operation types',
//       (operations) {
//         final balances = calculateBalances(operations);

//         // Recalculer manuellement pour vérifier
//         double expectedUv = 0;
//         double expectedCash = 0;

//         for (final op in operations) {
//           switch (op.type) {
//             case OperationType.depotUv:
//               if (op.isPaid) expectedCash += op.amount;
//               expectedUv -= op.amount;
//               break;
//             case OperationType.retraitUv:
//               expectedCash -= op.amount;
//               expectedUv += op.amount;
//               break;
//             case OperationType.transfert:
//               expectedUv -= op.amount;
//               if (op.isPaid) expectedCash += op.amount;
//               break;
//             case OperationType.venteCredit:
//               if (op.isPaid) expectedCash += op.amount;
//               break;
//           }
//         }

//         expect(balances['uv'], equals(expectedUv));
//         expect(balances['cash'], equals(expectedCash));
//       },
//     );

//     test('Empty operations list returns zero balances', () {
//       final balances = calculateBalances([]);
//       expect(balances['uv'], equals(0.0));
//       expect(balances['cash'], equals(0.0));
//     });

//     test('Depot UV increases cash when paid, decreases UV', () {
//       final op = Operation(
//         id: 'op1',
//         type: OperationType.depotUv,
//         amount: 10000,
//         isPaid: true,
//         userId: 'user1',
//         createdAt: DateTime.now(),
//       );

//       final balances = calculateBalances([op]);
//       expect(balances['cash'], equals(10000.0));
//       expect(balances['uv'], equals(-10000.0));
//     });

//     test('Retrait UV decreases cash, increases UV', () {
//       final op = Operation(
//         id: 'op1',
//         type: OperationType.retraitUv,
//         amount: 5000,
//         isPaid: true,
//         userId: 'user1',
//         createdAt: DateTime.now(),
//       );

//       final balances = calculateBalances([op]);
//       expect(balances['cash'], equals(-5000.0));
//       expect(balances['uv'], equals(5000.0));
//     });
//   });

//   group('DatabaseService Operations Sorting', () {
//     /// **Feature: wave-agent-simple, Property 4: Tri des opérations par date**
//     /// *For any* liste d'opérations retournée, les opérations doivent être triées par date décroissante (plus récente en premier)
//     /// **Validates: Requirements 3.6**
//     Glados(any.list(any.operation)).test(
//       'Property 4: Operations are sorted by date descending',
//       (operations) {
//         final sorted = sortOperationsByDate(operations);

//         // Vérifier que chaque élément est >= au suivant (date décroissante)
//         for (int i = 0; i < sorted.length - 1; i++) {
//           expect(
//             sorted[i].createdAt.millisecondsSinceEpoch >=
//                 sorted[i + 1].createdAt.millisecondsSinceEpoch,
//             isTrue,
//             reason:
//                 'Operation at index $i should be more recent than operation at index ${i + 1}',
//           );
//         }
//       },
//     );

//     test('Sorting preserves all operations', () {
//       final operations = [
//         Operation(
//           id: 'op1',
//           type: OperationType.depotUv,
//           amount: 1000,
//           isPaid: true,
//           userId: 'user1',
//           createdAt: DateTime(2024, 1, 1),
//         ),
//         Operation(
//           id: 'op2',
//           type: OperationType.retraitUv,
//           amount: 2000,
//           isPaid: false,
//           userId: 'user1',
//           createdAt: DateTime(2024, 1, 3),
//         ),
//         Operation(
//           id: 'op3',
//           type: OperationType.transfert,
//           amount: 3000,
//           isPaid: true,
//           userId: 'user1',
//           createdAt: DateTime(2024, 1, 2),
//         ),
//       ];

//       final sorted = sortOperationsByDate(operations);

//       expect(sorted.length, equals(3));
//       expect(sorted[0].id, equals('op2')); // Jan 3 - most recent
//       expect(sorted[1].id, equals('op3')); // Jan 2
//       expect(sorted[2].id, equals('op1')); // Jan 1 - oldest
//     });
//   });

//   group('DatabaseService Clients Sorting', () {
//     /// **Feature: wave-agent-simple, Property 5: Tri des clients par dette**
//     /// *For any* liste de clients retournée, les clients doivent être triés par dette décroissante (plus grande dette en premier)
//     /// **Validates: Requirements 4.2**
//     Glados(any.list(any.client)).test(
//       'Property 5: Clients are sorted by debt descending',
//       (clients) {
//         final sorted = sortClientsByDebt(clients);

//         // Vérifier que chaque élément a une dette >= au suivant
//         for (int i = 0; i < sorted.length - 1; i++) {
//           expect(
//             sorted[i].totalDebt >= sorted[i + 1].totalDebt,
//             isTrue,
//             reason:
//                 'Client at index $i should have debt >= client at index ${i + 1}',
//           );
//         }
//       },
//     );

//     test('Sorting preserves all clients', () {
//       final clients = [
//         Client(
//           id: 'c1',
//           name: 'Client A',
//           phone: '77 111 11 11',
//           totalDebt: 5000,
//           userId: 'user1',
//           createdAt: DateTime.now(),
//         ),
//         Client(
//           id: 'c2',
//           name: 'Client B',
//           phone: '77 222 22 22',
//           totalDebt: 50000,
//           userId: 'user1',
//           createdAt: DateTime.now(),
//         ),
//         Client(
//           id: 'c3',
//           name: 'Client C',
//           phone: '77 333 33 33',
//           totalDebt: 25000,
//           userId: 'user1',
//           createdAt: DateTime.now(),
//         ),
//       ];

//       final sorted = sortClientsByDebt(clients);

//       expect(sorted.length, equals(3));
//       expect(sorted[0].id, equals('c2')); // 50000 - highest debt
//       expect(sorted[1].id, equals('c3')); // 25000
//       expect(sorted[2].id, equals('c1')); // 5000 - lowest debt
//     });
//   });

//   group('DatabaseService Debt Reduction', () {
//     /// **Feature: wave-agent-simple, Property 6: Réduction de dette après paiement**
//     /// *For any* paiement enregistré pour un client, la dette du client doit diminuer exactement du montant payé
//     /// **Validates: Requirements 4.4**
//     Glados2(any.clientWithDebt, any.intInRange(1, 100000)).test(
//       'Property 6: Debt reduction after payment equals payment amount',
//       (client, paymentAmountInt) {
//         final paymentAmount = paymentAmountInt.toDouble();
        
//         // Limiter le paiement à la dette actuelle (on ne peut pas payer plus que la dette)
//         final actualPayment = paymentAmount.clamp(0.0, client.totalDebt);
        
//         final newDebt = calculateDebtAfterPayment(client.totalDebt, actualPayment);
        
//         // La nouvelle dette doit être exactement la dette initiale moins le paiement
//         expect(newDebt, equals(client.totalDebt - actualPayment));
        
//         // La dette ne peut jamais être négative
//         expect(newDebt, greaterThanOrEqualTo(0.0));
        
//         // La réduction de dette est exactement le montant payé
//         final debtReduction = client.totalDebt - newDebt;
//         expect(debtReduction, equals(actualPayment));
//       },
//     );

//     test('Payment reduces debt by exact amount', () {
//       final client = Client(
//         id: 'c1',
//         name: 'Test Client',
//         phone: '77 123 45 67',
//         totalDebt: 50000,
//         userId: 'user1',
//         createdAt: DateTime.now(),
//       );

//       final newDebt = calculateDebtAfterPayment(client.totalDebt, 20000);
      
//       expect(newDebt, equals(30000.0));
//     });

//     test('Full payment reduces debt to zero', () {
//       final client = Client(
//         id: 'c1',
//         name: 'Test Client',
//         phone: '77 123 45 67',
//         totalDebt: 50000,
//         userId: 'user1',
//         createdAt: DateTime.now(),
//       );

//       final newDebt = calculateDebtAfterPayment(client.totalDebt, 50000);
      
//       expect(newDebt, equals(0.0));
//     });

//     test('Overpayment clamps debt to zero', () {
//       final client = Client(
//         id: 'c1',
//         name: 'Test Client',
//         phone: '77 123 45 67',
//         totalDebt: 50000,
//         userId: 'user1',
//         createdAt: DateTime.now(),
//       );

//       // Paiement supérieur à la dette
//       final newDebt = calculateDebtAfterPayment(client.totalDebt, 75000);
      
//       // La dette ne peut pas être négative
//       expect(newDebt, equals(0.0));
//     });

//     test('Zero payment does not change debt', () {
//       final client = Client(
//         id: 'c1',
//         name: 'Test Client',
//         phone: '77 123 45 67',
//         totalDebt: 50000,
//         userId: 'user1',
//         createdAt: DateTime.now(),
//       );

//       final newDebt = calculateDebtAfterPayment(client.totalDebt, 0);
      
//       expect(newDebt, equals(50000.0));
//     });
//   });
// }
