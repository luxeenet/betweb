import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';
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
              initialUrlRequest: URLRequest(url: WebUri(AppConfig.baseUrl)),
              initialSettings: InAppWebViewSettings(
                userAgent: AppConfig.userAgent,
                javaScriptEnabled: true,
                mediaPlaybackRequiresUserGesture: false,
                allowsInlineMediaPlayback: true,
                useShouldOverrideUrlLoading: true,
                isFraudulentWebsiteWarningEnabled: true, 
                safeBrowsingEnabled: true,
              ),
              onWebViewCreated: (webController) {
                controller.webViewController = webController;
              },
              onProgressChanged: (webController, progress) {
                controller.onProgressChanged(progress);
              },
            ),
            if (controller.isLoading.value) _buildLoadingOverlay(),
          ],
        );
      }),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.white,
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Column(
          children: [
            Container(height: 2, color: Colors.blue), 
            Expanded(
              child: ListView.builder(
                itemCount: 10,
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Container(
                    height: 100, 
                    decoration: BoxDecoration(
                      color: Colors.white, 
                      borderRadius: BorderRadius.circular(12)
                    )
                  ),
                ),
              ),
            ),
          ],
        ),
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
          const Text("No Connection", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          const Text("Please check your internet settings.", style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () => controller.reload(),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
            child: const Text("Retry"),
          ),
        ],
      ),
    );
  }
}
