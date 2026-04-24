String? validateStrongPassword(String? value) {
  final password = value ?? '';

  if (password.isEmpty) {
    return "Password can't be empty";
  }

  final hasUppercase = RegExp(r'[A-Z]').hasMatch(password);
  final hasLowercase = RegExp(r'[a-z]').hasMatch(password);
  final hasNumber = RegExp(r'\d').hasMatch(password);
  final hasSpecialChar = RegExp(
    r'[!@#$%^&*(),.?":{}|<>_\-\\/\[\];\`~+=]',
  ).hasMatch(password);

  if (password.length < 8 ||
      !hasUppercase ||
      !hasLowercase ||
      !hasNumber ||
      !hasSpecialChar) {
    return 'Password must have at least 8 characters, an uppercase, a lowercase, a number, and a special character';
  }

  return null;
}
