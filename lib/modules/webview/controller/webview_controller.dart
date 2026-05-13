import 'dart:async';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../core/constants/app_config.dart';

class CustomWebViewController extends GetxController {
  late InAppWebViewController webViewController;
  var progress = 0.0.obs;
  var isLoading = true.obs;
  var isOffline = false.obs;
  Timer? _loadingTimeout;

  @override
  void onInit() {
    super.onInit();
    checkConnectivity();
    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> result) {
      isOffline.value = result.contains(ConnectivityResult.none);
    });
  }

  @override
  void onClose() {
    _loadingTimeout?.cancel();
    super.onClose();
  }

  Future<void> checkConnectivity() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    isOffline.value = connectivityResult.contains(ConnectivityResult.none);
  }

  void onProgressChanged(int progressValue) {
    progress.value = progressValue / 100;
    // Show content when it's mostly loaded (80%+) to avoid getting stuck on slow scripts
    if (progressValue >= 80) {
      isLoading.value = false;
      _loadingTimeout?.cancel();
    }
  }

  void onLoadStart() {
    // Only show loading shimmer if we are starting a fresh load
    if (progress.value < 0.1) {
      isLoading.value = true;
    }
    _startLoadingTimeout();
  }

  void onLoadStop() {
    isLoading.value = false;
    _loadingTimeout?.cancel();
  }

  void onReceivedError() {
    isLoading.value = false;
    _loadingTimeout?.cancel();
  }

  void _startLoadingTimeout() {
    _loadingTimeout?.cancel();
    // Reduced timeout to 2 seconds for ultra-fast response
    _loadingTimeout = Timer(const Duration(seconds: 2), () {
      if (isLoading.value) {
        isLoading.value = false;
      }
    });
  }

  void reload() {
    progress.value = 0.0; // Reset progress to allow shimmer to show again
    isLoading.value = true;
    // Explicitly load the base URL again to ensure it is found
    webViewController.loadUrl(urlRequest: URLRequest(url: WebUri(AppConfig.baseUrl)));
  }
}

