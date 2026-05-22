import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../webview/controller/webview_controller.dart';

class MainController extends GetxController {
  var currentIndex = 0.obs;
  var isBottomBarVisible = true.obs;

  // Bidirectional page-to-index mapping helpers
  String indexToPage(int index) {
    switch (index) {
      case 0:
        return "home";
      case 1:
        return "betslips";
      case 2:
        return "subscription";
      case 3:
        return "account";
      default:
        return "home";
    }
  }

  int pageToIndex(String page) {
    switch (page) {
      case "home":
        return 0;
      case "betslips":
        return 1;
      case "subscription":
        return 2;
      case "account":
        return 3;
      default:
        return 0;
    }
  }

  void changePage(int index) {
    currentIndex.value = index;
    
    // If navigating to a WebView-controlled page (0-3), send the state update to React
    if (index >= 0 && index <= 3) {
      try {
        final webViewController = Get.find<CustomWebViewController>();
        final pageName = indexToPage(index);
        webViewController.webViewController.runJavaScript(
          "if (typeof window !== 'undefined' && window.setActivePageFromNative) { window.setActivePageFromNative('$pageName'); }"
        );
      } catch (e) {
        debugPrint("Error executing JS page update: $e");
      }
    }
  }

  void setBottomBarVisibility(bool visible) {
    isBottomBarVisible.value = visible;
  }
}

