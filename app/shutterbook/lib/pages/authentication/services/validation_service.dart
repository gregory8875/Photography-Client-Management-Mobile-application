// Shutterbook — simple validation helpers
// Very small helpers for validating user input (passwords, emails, etc.).
class Validators {
  // Optionally, enforce: uppercase, numbers, symbols
  static String? validatePassword(String? password) {
    if (password == null || password.isEmpty) return 'Password is required';
    if (password.length < 6) return 'Password must be at least 6 characters';
    return null;
  }
}
