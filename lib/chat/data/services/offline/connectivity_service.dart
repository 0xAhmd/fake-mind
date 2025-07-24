import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  bool _isOnline = false;
  bool get isOnline => _isOnline;

  final StreamController<bool> _connectivityController =
      StreamController<bool>.broadcast();
  Stream<bool> get connectivityStream => _connectivityController.stream;

  ConnectivityService() {
    _initConnectivity();
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _updateConnectionStatus,
    );
  }

  Future<void> _initConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      await _updateConnectionStatus(result);
    } catch (e) {
      print('Could not check connectivity status: $e');
    }
  }

  Future<void> _updateConnectionStatus(ConnectivityResult result) async {
    final bool wasOnline = _isOnline;
    _isOnline = result != ConnectivityResult.none;

    if (wasOnline != _isOnline) {
      _connectivityController.add(_isOnline);
      print('Connectivity changed: ${_isOnline ? "Online" : "Offline"}');
    }
  }

  Future<bool> hasConnection() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return result != ConnectivityResult.none;
    } catch (e) {
      return false;
    }
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    _connectivityController.close();
  }
}
