import 'package:flutter/material.dart';

import '../errors/app_error.dart';
import '../errors/error_classifier.dart';

/// Consistent full-area loading indicator with an optional label.
class AppLoadingView extends StatelessWidget {
  const AppLoadingView({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }
}

/// Consistent error state with a safe, user-facing message and optional retry.
///
/// Pass any thrown [error]; it is normalized through [ErrorClassifier] so users
/// only ever see a friendly message, never raw exception text.
class AppErrorView extends StatelessWidget {
  const AppErrorView({
    super.key,
    this.error,
    this.message,
    this.onRetry,
    this.icon = Icons.error_outline_rounded,
  });

  final Object? error;
  final String? message;
  final VoidCallback? onRetry;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final resolvedMessage = message ??
        (error == null
            ? 'Something went wrong. Please try again.'
            : ErrorClassifier.classify(error!).userMessage);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text(
              resolvedMessage,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Try again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Consistent empty state for lists/streams that resolved with no data.
class AppEmptyView extends StatelessWidget {
  const AppEmptyView({
    super.key,
    required this.message,
    this.icon = Icons.inbox_rounded,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 56,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Convenience for turning an [AppError] category into a display message.
extension AppErrorDisplay on AppError {
  String get displayMessage => userMessage;
}
