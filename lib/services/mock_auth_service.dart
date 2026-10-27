/// In-memory authentication for the UI prototype; accounts reset on app restart.
class MockAuthService {
  MockAuthService._();

  static final Map<String, String> _accounts = {
    'professor@eduturmas.com': 'Demo1234',
  };

  static bool signIn(String email, String password) {
    return _accounts[email.trim().toLowerCase()] == password;
  }

  /// Returns an error message when registration cannot be completed.
  static String? register(String email, String password) {
    final normalizedEmail = email.trim().toLowerCase();
    if (_accounts.containsKey(normalizedEmail)) {
      return 'Já existe uma conta com esse e-mail.';
    }
    _accounts[normalizedEmail] = password;
    return null;
  }
}
