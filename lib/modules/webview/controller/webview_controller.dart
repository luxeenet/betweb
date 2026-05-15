import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../core/constants/app_config.dart';

class CustomWebViewController extends GetxController {
  late InAppWebViewController webViewController;
  PullToRefreshController? pullToRefreshController;
  
  var progress = 0.0.obs;
  var isLoading = true.obs;
  var isOffline = false.obs;
  Timer? _loadingTimeout;

  @override
  void onInit() {
    super.onInit();
    checkConnectivity();
    
    // Initialize Pull to Refresh for a native feel
    pullToRefreshController = PullToRefreshController(
      settings: PullToRefreshSettings(
        color: Colors.blue,
      ),
      onRefresh: () async {
        if (isOffline.value) {
          checkConnectivity();
        }
        webViewController.reload();
      },
    );

    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> result) {
      isOffline.value = result.contains(ConnectivityResult.none);
      if (!isOffline.value && isLoading.value) {
        reload();
      }
    });

    // Global Safety: Ensure loading state is dismissed after 8 seconds of app launch no matter what
    // Increased slightly to allow for slow connections, but still prevents infinite loops.
    Future.delayed(const Duration(seconds: 8), () {
      if (isLoading.value) {
        isLoading.value = false;
        _loadingTimeout?.cancel();
      }
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
    
    // Dismiss loading when content is mostly ready (75%+) or fully ready
    if (progressValue >= 75) {
      if (isLoading.value) {
        isLoading.value = false;
        _loadingTimeout?.cancel();
      }
    }
  }

  void onLoadStart() {
    // Only update loading state if we are starting a fresh load
    if (progress.value < 0.1) {
      isLoading.value = true;
    }
    _startLoadingTimeout();
  }

  void onLoadStop() {
    isLoading.value = false;
    pullToRefreshController?.endRefreshing();
    _loadingTimeout?.cancel();
  }

  void onReceivedError() {
    isLoading.value = false;
    pullToRefreshController?.endRefreshing();
    _loadingTimeout?.cancel();
  }

  void _startLoadingTimeout() {
    // Standard 5-second timeout for individual page loads
    _loadingTimeout?.cancel(); 
    _loadingTimeout = Timer(const Duration(seconds: 5), () {
      if (isLoading.value) {
        isLoading.value = false;
      }
    });
  }

  void reload() {
    progress.value = 0.0;
    isLoading.value = true;
    webViewController.reload();
  }
}

