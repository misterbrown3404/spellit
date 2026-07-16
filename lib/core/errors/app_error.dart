enum AppErrorCategory {
  authentication,
  firebase,
  network,
  permission,
  parsing,
  validation,
  platform,
  unknown,
}

class AppError implements Exception {
  const AppError({
    required this.category,
    required this.userMessage,
    required this.developerMessage,
    this.code,
    this.cause,
    this.stackTrace,
    this.isRetryable = false,
  });

  final AppErrorCategory category;
  final String userMessage;
  final String developerMessage;
  final String? code;
  final Object? cause;
  final StackTrace? stackTrace;
  final bool isRetryable;

  @override
  String toString() {
    final codeText = code == null ? '' : ' [$code]';
    return 'AppError.$category$codeText: $developerMessage';
  }
}

