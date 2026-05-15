import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_config.dart';
import '../controller/webview_controller.dart';

class WebViewScreen extends StatelessWidget {
  final CustomWebViewController controller = Get.put(CustomWebViewController());

  WebViewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        if (controller.isOffline.value) {
          return _buildOfflineView();
        }
        return Stack(
          children: [
            InAppWebView(
              initialUrlRequest: URLRequest(
                url: WebUri("https://betmakini.com"),
              ),
              pullToRefreshController: controller.pullToRefreshController,
              initialSettings: InAppWebViewSettings(
                userAgent: AppConfig.userAgent,
                javaScriptEnabled: true,
                mediaPlaybackRequiresUserGesture: false,
                allowsInlineMediaPlayback: true,
                useShouldOverrideUrlLoading: true,
                isFraudulentWebsiteWarningEnabled: false,
                safeBrowsingEnabled: false,
                supportZoom: false,
                displayZoomControls: false,
                builtInZoomControls: false,
                useWideViewPort: true,
                loadWithOverviewMode: true,
                domStorageEnabled: true,
                databaseEnabled: true,
                cacheEnabled: true,
                allowFileAccessFromFileURLs: true,
                allowUniversalAccessFromFileURLs: true,
                allowsBackForwardNavigationGestures: true,
                transparentBackground: true,
              ),
              onWebViewCreated: (webController) {
                controller.webViewController = webController;
              },
              onLoadStart: (webController, url) {
                controller.onLoadStart();
              },
              onLoadStop: (webController, url) {
                controller.onLoadStop();
              },
              onReceivedError: (webController, request, error) {
                controller.onReceivedError();
                Get.snackbar("Network Error", error.description, 
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.red.withValues(alpha: 0.7),
                  colorText: Colors.white);
              },
              onReceivedHttpError: (webController, request, response) {
                controller.onReceivedError();
                Get.snackbar("Server Error", "HTTP ${response.statusCode}", 
                  snackPosition: SnackPosition.BOTTOM);
              },
              onProgressChanged: (webController, progress) {
                controller.onProgressChanged(progress);
              },
              onReceivedServerTrustAuthRequest: (webController, challenge) async {
                return ServerTrustAuthResponse(action: ServerTrustAuthResponseAction.PROCEED);
              },
            ),
            // Shimmer loading removed as requested
          ],
        );
      }),
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
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
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
