import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class CustomWebViewController extends GetxController {
  late InAppWebViewController webViewController;
  var progress = 0.0.obs;
  var isLoading = true.obs;
  var isOffline = false.obs;

  @override
  void onInit() {
    super.onInit();
    checkConnectivity();
    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> result) {
      isOffline.value = result.contains(ConnectivityResult.none);
    });
  }

  Future<void> checkConnectivity() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    isOffline.value = connectivityResult.contains(ConnectivityResult.none);
  }

  void onProgressChanged(int progressValue) {
    progress.value = progressValue / 100;
    if (progressValue == 100) {
      isLoading.value = false;
    } else {
      isLoading.value = true;
    }
  }

  void reload() {
    webViewController.reload();
  }
}
