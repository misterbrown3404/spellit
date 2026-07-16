import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final networkStatusServiceProvider = Provider<NetworkStatusService>((ref) {
  final service = NetworkStatusService();
  ref.onDispose(service.dispose);
  return service;
});

class NetworkStatusService {
  NetworkStatusService() {
    _subscription = Connectivity().onConnectivityChanged.listen(
      (results) => _updateConnectionState(_hasConnection(results)),
    );
    unawaited(initialize());
  }

  final _connectivity = Connectivity();
  final StreamController<bool> _controller = StreamController<bool>.broadcast();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  bool _connected = true;

  Stream<bool> get onStatusChanged => _controller.stream;
  bool get isConnected => _connected;

  Future<void> initialize() async {
    final results = await _connectivity.checkConnectivity();
    _updateConnectionState(_hasConnection(results));
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    await _controller.close();
  }

  void _updateConnectionState(bool connected) {
    if (_connected != connected) {
      _connected = connected;
      _controller.add(connected);
    }
  }

  bool _hasConnection(List<ConnectivityResult> results) {
    return results.any((result) => result != ConnectivityResult.none);
  }
}

class NetworkStatusOverlay extends ConsumerWidget {
  const NetworkStatusOverlay({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.watch(networkStatusServiceProvider);

    return StreamBuilder<bool>(
      stream: service.onStatusChanged,
      initialData: service.isConnected,
      builder: (context, snapshot) {
        final isConnected = snapshot.data ?? true;

        return Stack(
          children: [
            child,
            if (!isConnected)
              Positioned.fill(
                child: ColoredBox(
                  color: Colors.black.withValues(alpha: 0.72),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        elevation: 8,
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade50,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.wifi_off_rounded,
                                  size: 36,
                                  color: Color(0xffD97706),
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'No network connection',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xff111827),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Your connection is weak or unavailable. Please check your network and try again.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade700,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 18),
                              FilledButton.icon(
                                onPressed: () => service.initialize(),
                                icon: const Icon(Icons.refresh_rounded, size: 18),
                                label: const Text('Retry connection'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xffD97706),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
