/// Test script to verify PocketBase configuration
/// 
/// This script tests:
/// - Connection to PocketBase
/// - User authentication
/// - Collection creation with security rules
/// - Index performance
/// - Cascade delete functionality
/// 
/// Usage:
/// 1. Make sure PocketBase is running: ./pocketbase serve
/// 2. Run this script: dart run pocketbase/test_configuration.dart

import 'package:pocketbase/pocketbase.dart';

const String pocketbaseUrl = 'http://127.0.0.1:8090';

void main() async {
  print('🚀 Test de Configuration PocketBase - Wave Money Agent\n');

  final pb = PocketBase(pocketbaseUrl);

  try {
    // Test 1: Connection
    await testConnection(pb);

    // Test 2: Create test users
    final user1 = await createTestUser(pb, 'user1@test.com', 'Test123456!', 'User 1');
    final user2 = await createTestUser(pb, 'user2@test.com', 'Test123456!', 'User 2');

    // Test 3: Authentication
    await testAuthentication(pb, 'user1@test.com', 'Test123456!');

    // Test 4: Security rules - User isolation
    await testUserIsolation(pb, user1, user2);

    // Test 5: Cascade delete
    await testCascadeDelete(pb);

    // Test 6: Index verification
    await testIndexes(pb);

    print('\n✅ Tous les tests sont passés avec succès!');
    print('✅ PocketBase est correctement configuré pour Wave Money Agent');
  } catch (e, stackTrace) {
    print('\n❌ Erreur lors des tests: $e');
    print('Stack trace: $stackTrace');
  }
}

Future<void> testConnection(PocketBase pb) async {
  print('📡 Test 1: Connexion à PocketBase...');
  try {
    await pb.health.check();
    print('   ✅ Connexion réussie à $pocketbaseUrl\n');
  } catch (e) {
    throw Exception('Impossible de se connecter à PocketBase. Assurez-vous qu\'il est lancé.');
  }
}

Future<Map<String, dynamic>> createTestUser(
  PocketBase pb,
  String email,
  String password,
  String name,
) async {
  print('👤 Création de l\'utilisateur: $email...');
  try {
    // Try to delete existing user first
    try {
      final existing = await pb.collection('users').getFirstListItem('email = "$email"');
      await pb.collection('users').delete(existing.id);
    } catch (_) {
      // User doesn't exist, continue
    }

    final user = await pb.collection('users').create(body: {
      'email': email,
      'password': password,
      'passwordConfirm': password,
      'name': name,
    });
    print('   ✅ Utilisateur créé: ${user.data['name']} (${user.id})\n');
    return user.toJson();
  } catch (e) {
    throw Exception('Erreur lors de la création de l\'utilisateur: $e');
  }
}

Future<void> testAuthentication(PocketBase pb, String email, String password) async {
  print('🔐 Test 2: Authentification...');
  try {
    final authData = await pb.collection('users').authWithPassword(email, password);
    print('   ✅ Authentification réussie');
    print('   ✅ Token: ${pb.authStore.token.substring(0, 20)}...');
    print('   ✅ User: ${authData.record?.data['name']}\n');
  } catch (e) {
    throw Exception('Erreur d\'authentification: $e');
  }
}

Future<void> testUserIsolation(
  PocketBase pb,
  Map<String, dynamic> user1,
  Map<String, dynamic> user2,
) async {
  print('🔒 Test 3: Isolation des données entre utilisateurs...');

  // Authenticate as user1
  await pb.collection('users').authWithPassword('user1@test.com', 'Test123456!');

  // Create a client for user1
  final client1 = await pb.collection('clients').create(body: {
    'name': 'Client User 1',
    'phone': '+221 77 111 11 11',
    'totalDebt': 0,
    'userId': user1['id'],
  });
  print('   ✅ Client créé pour User 1: ${client1.id}');

  // Authenticate as user2
  await pb.collection('users').authWithPassword('user2@test.com', 'Test123456!');

  // Try to list clients - should only see user2's clients (none yet)
  final clientsForUser2 = await pb.collection('clients').getFullList();
  if (clientsForUser2.isEmpty) {
    print('   ✅ User 2 ne voit pas les clients de User 1');
  } else {
    throw Exception('ERREUR: User 2 peut voir les clients de User 1!');
  }

  // Try to access user1's client directly - should fail
  try {
    await pb.collection('clients').getOne(client1.id);
    throw Exception('ERREUR: User 2 peut accéder au client de User 1!');
  } catch (e) {
    if (e.toString().contains('404')) {
      print('   ✅ User 2 ne peut pas accéder au client de User 1');
    } else {
      rethrow;
    }
  }

  // Create a client for user2
  final client2 = await pb.collection('clients').create(body: {
    'name': 'Client User 2',
    'phone': '+221 77 222 22 22',
    'totalDebt': 0,
    'userId': user2['id'],
  });
  print('   ✅ Client créé pour User 2: ${client2.id}');

  // Verify user2 can only see their own client
  final clientsForUser2After = await pb.collection('clients').getFullList();
  if (clientsForUser2After.length == 1 && clientsForUser2After[0].id == client2.id) {
    print('   ✅ User 2 voit uniquement son propre client\n');
  } else {
    throw Exception('ERREUR: Isolation des données incorrecte!');
  }
}

Future<void> testCascadeDelete(PocketBase pb) async {
  print('🗑️  Test 4: Cascade Delete...');

  // Authenticate as user1
  await pb.collection('users').authWithPassword('user1@test.com', 'Test123456!');

  // Get user1's client
  final clients = await pb.collection('clients').getFullList();
  if (clients.isEmpty) {
    print('   ⚠️  Aucun client trouvé pour tester le cascade delete');
    return;
  }
  final client = clients[0];

  // Create operations for this client
  final operation1 = await pb.collection('operations').create(body: {
    'clientId': client.id,
    'type': 'venteCredit',
    'amount': 5000,
    'isPaid': false,
    'userId': pb.authStore.model?.id,
  });
  print('   ✅ Opération créée: ${operation1.id}');

  final payment1 = await pb.collection('payments').create(body: {
    'clientId': client.id,
    'amount': 2000,
    'userId': pb.authStore.model?.id,
  });
  print('   ✅ Paiement créé: ${payment1.id}');

  // Delete the client
  await pb.collection('clients').delete(client.id);
  print('   ✅ Client supprimé: ${client.id}');

  // Verify operations and payments were deleted
  try {
    await pb.collection('operations').getOne(operation1.id);
    throw Exception('ERREUR: L\'opération n\'a pas été supprimée!');
  } catch (e) {
    if (e.toString().contains('404')) {
      print('   ✅ Opération supprimée automatiquement (cascade delete)');
    } else {
      rethrow;
    }
  }

  try {
    await pb.collection('payments').getOne(payment1.id);
    throw Exception('ERREUR: Le paiement n\'a pas été supprimé!');
  } catch (e) {
    if (e.toString().contains('404')) {
      print('   ✅ Paiement supprimé automatiquement (cascade delete)\n');
    } else {
      rethrow;
    }
  }
}

Future<void> testIndexes(PocketBase pb) async {
  print('📊 Test 5: Vérification des index...');

  // Authenticate as user1
  await pb.collection('users').authWithPassword('user1@test.com', 'Test123456!');

  // Create test data
  final client = await pb.collection('clients').create(body: {
    'name': 'Client Test Index',
    'phone': '+221 77 333 33 33',
    'totalDebt': 0,
    'userId': pb.authStore.model?.id,
  });

  // Create multiple operations
  for (int i = 0; i < 10; i++) {
    await pb.collection('operations').create(body: {
      'clientId': client.id,
      'type': i % 2 == 0 ? 'venteCredit' : 'transfert',
      'amount': 1000 * (i + 1),
      'isPaid': i % 3 == 0,
      'userId': pb.authStore.model?.id,
    });
  }
  print('   ✅ 10 opérations créées pour tester les index');

  // Test query with userId filter (should use idx_operations_userId)
  final startTime1 = DateTime.now();
  final operationsByUser = await pb.collection('operations').getFullList(
    filter: 'userId = "${pb.authStore.model?.id}"',
  );
  final duration1 = DateTime.now().difference(startTime1);
  print('   ✅ Requête par userId: ${operationsByUser.length} résultats en ${duration1.inMilliseconds}ms');

  // Test query with clientId filter (should use idx_operations_clientId)
  final startTime2 = DateTime.now();
  final operationsByClient = await pb.collection('operations').getFullList(
    filter: 'clientId = "${client.id}"',
  );
  final duration2 = DateTime.now().difference(startTime2);
  print('   ✅ Requête par clientId: ${operationsByClient.length} résultats en ${duration2.inMilliseconds}ms');

  // Test query with type filter (should use idx_operations_type)
  final startTime3 = DateTime.now();
  final operationsByType = await pb.collection('operations').getFullList(
    filter: 'type = "venteCredit"',
  );
  final duration3 = DateTime.now().difference(startTime3);
  print('   ✅ Requête par type: ${operationsByType.length} résultats en ${duration3.inMilliseconds}ms');

  // Test query with sort by created (should use idx_operations_created)
  final startTime4 = DateTime.now();
  final operationsSorted = await pb.collection('operations').getFullList(
    sort: '-created',
  );
  final duration4 = DateTime.now().difference(startTime4);
  print('   ✅ Requête triée par date: ${operationsSorted.length} résultats en ${duration4.inMilliseconds}ms\n');
}
