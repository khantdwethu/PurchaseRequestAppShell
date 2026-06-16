import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  ConnectivityService({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      _connectivity.onConnectivityChanged;

  Future<bool> hasConnection() async {
    try {
      final List<ConnectivityResult> results = await _connectivity
          .checkConnectivity();
      return hasUsableConnection(results);
    } catch (_) {
      return true;
    }
  }

  bool hasUsableConnection(List<ConnectivityResult> results) {
    return results.any((ConnectivityResult result) {
      return result != ConnectivityResult.none;
    });
  }
}
