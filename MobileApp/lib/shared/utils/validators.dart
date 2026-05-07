class Validators {
  static bool isValidEmail(String value) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+').hasMatch(value);
  }

  static bool isValidPhone(String value) {
    return RegExp(r'^[0-9]+$').hasMatch(value);
  }
}
