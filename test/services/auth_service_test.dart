import 'package:glados/glados.dart';
import 'package:gest_agent/models/user.dart';

/// Générateur d'email valide pour les tests property-based
extension EmailGenerator on Any {
  Generator<String> get validEmail => combine2(
        any.nonEmptyLetters,
        any.choose(['gmail.com', 'yahoo.fr', 'wave.sn', 'test.com']),
        (name, domain) => '${name.toLowerCase()}@$domain',
      );

  Generator<String> get invalidEmail => any.choose([
        '',
        'invalid',
        'no-at-sign',
        '@nodomain',
      ]);
}

/// Générateur de mot de passe pour les tests property-based
extension PasswordGenerator on Any {
  Generator<String> get validPassword => any.nonEmptyLetters;
}

/// Générateur de User pour les tests property-based
extension UserGenerator on Any {
  Generator<User> get user => combine3(
        any.nonEmptyLetters,
        any.validEmail,
        any.nonEmptyLetters,
        (id, email, name) => User(
          id: 'user_$id',
          email: email,
          name: name,
          createdAt: DateTime.now(),
        ),
      );
}

/// Simule le résultat d'une authentification
/// Cette fonction représente la logique pure de validation
class AuthResult {
  final bool success;
  final User? user;
  final String? error;

  AuthResult.success(this.user)
      : success = true,
        error = null;

  AuthResult.failure(this.error)
      : success = false,
        user = null;
}

/// Simule la validation des identifiants (logique pure)
/// Dans un vrai système, cela vérifierait contre la base de données
AuthResult validateCredentials({
  required String email,
  required String password,
  required Map<String, String> validCredentials,
  required Map<String, User> users,
}) {
  // Vérifier que l'email n'est pas vide
  if (email.isEmpty) {
    return AuthResult.failure('Email requis');
  }

  // Vérifier que le mot de passe n'est pas vide
  if (password.isEmpty) {
    return AuthResult.failure('Mot de passe requis');
  }

  // Vérifier si les identifiants sont valides
  if (validCredentials.containsKey(email) &&
      validCredentials[email] == password) {
    final user = users[email];
    if (user != null) {
      return AuthResult.success(user);
    }
  }

  return AuthResult.failure('Email ou mot de passe incorrect');
}

/// Vérifie si un email a un format valide
bool isValidEmailFormat(String email) {
  if (email.isEmpty) return false;
  if (!email.contains('@')) return false;
  final parts = email.split('@');
  if (parts.length != 2) return false;
  if (parts[0].isEmpty || parts[1].isEmpty) return false;
  if (!parts[1].contains('.')) return false;
  return true;
}

void main() {
  group('AuthService Validation Logic', () {
    /// **Feature: wave-agent-simple, Property 1: Authentification avec identifiants valides**
    /// *For any* email et mot de passe valides dans la base, l'authentification doit réussir et retourner un utilisateur
    /// **Validates: Requirements 1.2**
    Glados2(any.validEmail, any.validPassword).test(
      'Property 1: Valid credentials should authenticate successfully',
      (email, password) {
        // Créer un utilisateur de test avec ces identifiants
        final testUser = User(
          id: 'user_123',
          email: email,
          name: 'Test User',
          createdAt: DateTime.now(),
        );

        final validCredentials = {email: password};
        final users = {email: testUser};

        final result = validateCredentials(
          email: email,
          password: password,
          validCredentials: validCredentials,
          users: users,
        );

        expect(result.success, isTrue,
            reason: 'Valid credentials should authenticate');
        expect(result.user, isNotNull,
            reason: 'Should return a user on success');
        expect(result.user!.email, equals(email),
            reason: 'Returned user should have the correct email');
        expect(result.error, isNull,
            reason: 'Should not have an error on success');
      },
    );

    /// **Feature: wave-agent-simple, Property 2: Authentification avec identifiants invalides**
    /// *For any* email ou mot de passe invalide, l'authentification doit échouer et retourner une erreur
    /// **Validates: Requirements 1.3**
    Glados2(any.validEmail, any.validPassword).test(
      'Property 2: Invalid credentials should fail authentication',
      (email, password) {
        // Créer des identifiants valides différents
        final validCredentials = {'other@email.com': 'otherpassword'};
        final users = <String, User>{};

        final result = validateCredentials(
          email: email,
          password: password,
          validCredentials: validCredentials,
          users: users,
        );

        expect(result.success, isFalse,
            reason: 'Invalid credentials should not authenticate');
        expect(result.user, isNull,
            reason: 'Should not return a user on failure');
        expect(result.error, isNotNull,
            reason: 'Should return an error message');
      },
    );

    Glados(any.invalidEmail).test(
      'Property 2b: Invalid email format should fail validation',
      (invalidEmail) {
        expect(isValidEmailFormat(invalidEmail), isFalse,
            reason: 'Invalid email format should be rejected');
      },
    );
  });

  group('AuthService Email Validation', () {
    Glados(any.validEmail).test(
      'Valid email format should pass validation',
      (email) {
        expect(isValidEmailFormat(email), isTrue,
            reason: 'Valid email should pass format validation');
      },
    );

    test('Empty email should fail validation', () {
      expect(isValidEmailFormat(''), isFalse);
    });

    test('Email without @ should fail validation', () {
      expect(isValidEmailFormat('invalidemail'), isFalse);
    });

    test('Email without domain should fail validation', () {
      expect(isValidEmailFormat('test@'), isFalse);
    });
  });

  group('AuthService State Management', () {
    test('Empty credentials should fail', () {
      final result = validateCredentials(
        email: '',
        password: '',
        validCredentials: {},
        users: {},
      );

      expect(result.success, isFalse);
      expect(result.error, equals('Email requis'));
    });

    test('Empty password should fail', () {
      final result = validateCredentials(
        email: 'test@test.com',
        password: '',
        validCredentials: {},
        users: {},
      );

      expect(result.success, isFalse);
      expect(result.error, equals('Mot de passe requis'));
    });

    test('Wrong password should fail', () {
      final testUser = User(
        id: 'user_123',
        email: 'test@test.com',
        name: 'Test User',
        createdAt: DateTime.now(),
      );

      final result = validateCredentials(
        email: 'test@test.com',
        password: 'wrongpassword',
        validCredentials: {'test@test.com': 'correctpassword'},
        users: {'test@test.com': testUser},
      );

      expect(result.success, isFalse);
      expect(result.error, equals('Email ou mot de passe incorrect'));
    });
  });
}
