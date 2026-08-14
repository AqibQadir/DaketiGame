class BackendConfig {
  BackendConfig._();

  /// Override at build/run time with:
  /// --dart-define=DAKETI_SERVER_URL=http://localhost:3006
  static const String serverUrl = String.fromEnvironment(
    'DAKETI_SERVER_URL',
    defaultValue: 'http://54.81.228.43:3006',
  );
}
