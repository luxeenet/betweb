import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:get/get.dart';
import '../controller/webview_controller.dart';
import '../../main/controller/main_controller.dart';

class WebViewScreen extends StatelessWidget {
  final CustomWebViewController controller = Get.put(CustomWebViewController());

  WebViewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final MainController mainController = Get.find<MainController>();

    return Scaffold(
      backgroundColor: Colors.black, // Match professional theme
      body: SafeArea(
        bottom: false,
        child: Obx(() {
          if (controller.isOffline.value) {
            return _buildOfflineView();
          }

          final bool showBottomBar = mainController.isBottomBarVisible.value;
          final double bottomPadding = showBottomBar ? (65.0 + MediaQuery.paddingOf(context).bottom) : 0.0;

          return Stack(
            children: [
              Padding(
                padding: EdgeInsets.only(bottom: bottomPadding),
                child: RefreshIndicator(
                  onRefresh: () async {
                    controller.reload();
                  },
                  child: WebViewWidget(
                    controller: controller.webViewController,
                  ),
                ),
              ),
              if (controller.isLoading.value)
                const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFFFF7B2E), // Brand orange color
                  ),
                ),
              if (controller.isLoading.value)
                 Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: LinearProgressIndicator(
                    value: controller.progress.value,
                    backgroundColor: Colors.transparent,
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF7B2E)),
                  ),
                ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildOfflineView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 80, color: Colors.grey),
          const SizedBox(height: 20),
          const Text(
            "No Connection",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 10),
          const Text(
            "Please check your internet settings.",
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () => controller.reload(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF7B2E),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text("Retry"),
          ),
        ],
      ),
    );
  }
}
