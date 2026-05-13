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
              initialUrlRequest: URLRequest(url: WebUri("https://betmakini.com")),
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
              ),
              onWebViewCreated: (webController) {
                controller.webViewController = webController;
                // Explicitly ensure the URL is loaded upon creation to avoid silent failures
                webController.loadUrl(urlRequest: URLRequest(url: WebUri("https://betmakini.com")));
              },
              onLoadStart: (webController, url) {
                controller.onLoadStart();
              },
              onLoadStop: (webController, url) {
                controller.onLoadStop();
              },
              onReceivedError: (webController, request, error) {
                controller.onReceivedError();
              },
              onReceivedHttpError: (webController, request, response) {
                controller.onReceivedError();
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
        baseColor: Colors.grey[200]!,
        highlightColor: Colors.white,
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  width: 180,
                  height: 35,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 6,
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Container(
                    height: 110,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
            ],
          ),
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
