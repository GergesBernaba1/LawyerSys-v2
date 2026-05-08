class ApiConstants {
  static const _apiRoot = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:5000',
  );

  static const baseUrl = '$_apiRoot/api';
  static const apiRoot = _apiRoot;

  // Authentication endpoints
  static const login = '/account/login';
  static const register = '/account/register';
  static const forgotPassword = '/account/request-password-reset';
  static const resetPassword = '/account/reset-password';
  static const refreshToken = '/account/refresh';

  // Dashboard and core endpoints
  static const dashboard = '/dashboard/analytics';

  // Employee endpoints
  static const employees = '/employees';
  static const employeeById = '/employees/{id}';

  // Account endpoints
  static const logout = '/account/logout';
  static const registerDeviceToken = '/account/register-device-token';
  static const unregisterDeviceToken = '/account/unregister-device-token';

  // Realtime / SignalR
  static const signalRHub = '/hubs/notifications';
}
