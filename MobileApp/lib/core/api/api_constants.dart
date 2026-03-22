class ApiConstants {
  static const baseUrl = 'https://qadayaapi.naqreo.com/api';

  // Authentication endpoints
  static const login = '/auth/login';
  static const register = '/auth/register';
  static const forgotPassword = '/auth/forgot-password';
  static const resetPassword = '/auth/reset-password';
  static const refreshToken = '/auth/refresh';

  // Dashboard and core endpoints
  static const dashboard = '/dashboard/summary';

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
