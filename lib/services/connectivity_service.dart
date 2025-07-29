import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Uygulama genelinde internet bağlantısını dinler ve durumunu bildirir.
class ConnectivityService {
  // Singleton deseni
  ConnectivityService._();
  static final instance = ConnectivityService._();

  // Bağlantı durumunu tutan ve değişiklikleri bildiren ValueNotifier.
  final ValueNotifier<bool> isConnected = ValueNotifier(false);

  late StreamSubscription<ConnectivityResult> _subscription;

  /// Servisi başlatır, mevcut durumu kontrol eder ve değişiklikleri dinlemeye başlar.
  void initialize() {
    _subscription = Connectivity().onConnectivityChanged.listen(_updateConnectionStatus);
    checkConnection();
  }

  /// Mevcut anlık bağlantı durumunu kontrol eder.
  Future<void> checkConnection() async {
    final result = await Connectivity().checkConnectivity();
    _updateConnectionStatus(result);
  }

  /// Bağlantı durumu değiştiğinde ValueNotifier'ı günceller.
  void _updateConnectionStatus(ConnectivityResult result) {
    isConnected.value = result != ConnectivityResult.none;
  }

  /// Servis artık kullanılmayacağında StreamSubscription'ı kapatır.
  void dispose() {
    _subscription.cancel();
  }
}
