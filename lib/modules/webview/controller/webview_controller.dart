import 'dart:async';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

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
    if (progressValue == 100) {
      isLoading.value = false;
      _loadingTimeout?.cancel();
    }
  }

  void onLoadStart() {
    isLoading.value = true;
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
    _loadingTimeout = Timer(const Duration(seconds: 15), () {
      if (isLoading.value) {
        isLoading.value = false;
      }
    });
  }

  void reload() {
    isLoading.value = true;
    webViewController.reload();
  }
}

