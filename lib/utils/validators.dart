String? validateEmail(String? value) {
  final email = value?.trim() ?? '';
  if (email.isEmpty) return 'Enter your email';
  if (!email.contains('@') || !email.contains('.')) {
    return 'Enter a valid email';
  }
  return null;
}

String? validatePassword(String? value) {
  final password = value ?? '';
  if (password.isEmpty) return 'Enter your password';
  if (password.length < 6) {
    return 'Password must be at least 6 characters';
  }
  return null;
}

String? validateConfirmPassword(String? value, String password) {
  if (value != password) return 'Passwords do not match';
  return null;
}

String? validateHeightCm(String? value) {
  final raw = value?.trim() ?? '';
  if (raw.isEmpty) return 'Enter your height';
  final height = double.tryParse(raw);
  if (height == null) return 'Enter a valid number';
  if (height <= 0) return 'Height must be greater than 0';
  if (height > 300) return 'Height must be 300 cm or less';
  return null;
}

String? validateWeightKg(String? value) {
  final raw = value?.trim() ?? '';
  if (raw.isEmpty) return 'Enter your weight';
  final weight = double.tryParse(raw);
  if (weight == null) return 'Enter a valid number';
  if (weight <= 0) return 'Weight must be greater than 0';
  if (weight > 500) return 'Weight must be 500 kg or less';
  return null;
}
