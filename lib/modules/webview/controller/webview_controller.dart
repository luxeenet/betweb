import 'package:flutter/material.dart';
import 'dart:async';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:get/get.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../core/constants/app_config.dart';

class CustomWebViewController extends GetxController {
  late final WebViewController webViewController;
  
  var progress = 0.0.obs;
  var isLoading = true.obs;
  var isOffline = false.obs;
  Timer? _loadingTimeout;

  @override
  void onInit() {
    super.onInit();
    _initializeController();
    checkConnectivity();
    
    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> result) {
      isOffline.value = result.contains(ConnectivityResult.none);
      if (!isOffline.value && isLoading.value) {
        reload();
      }
    });

    // Global Safety Timeout
    Future.delayed(const Duration(seconds: 8), () {
      if (isLoading.value) {
        isLoading.value = false;
        _loadingTimeout?.cancel();
      }
    });
  }

  void _initializeController() {
    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    webViewController = WebViewController.fromPlatformCreationParams(params);

    webViewController
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progressValue) {
            onProgressChanged(progressValue);
          },
          onPageStarted: (String url) {
            onLoadStart();
          },
          onPageFinished: (String url) {
            onLoadStop();
          },
          onWebResourceError: (WebResourceError error) {
            onReceivedError();
          },
          onNavigationRequest: (NavigationRequest request) {
            return NavigationDecision.navigate;
          },
        ),
      )
      ..setUserAgent(AppConfig.userAgent)
      ..loadRequest(Uri.parse(AppConfig.baseUrl));

    // Platform-specific optimizations
    if (webViewController.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(true);
      (webViewController.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    } else if (webViewController.platform is WebKitWebViewController) {
      final webKitController = webViewController.platform as WebKitWebViewController;
      webKitController.setInspectable(true);
      // allowsLinkPreview is typically true by default or handled via other means in webview_flutter
    }
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
    if (progressValue >= 75) {
      if (isLoading.value) {
        isLoading.value = false;
        _loadingTimeout?.cancel();
      }
    }
  }

  void onLoadStart() {
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
