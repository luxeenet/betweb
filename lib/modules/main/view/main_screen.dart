import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:ui';
import '../controller/main_controller.dart';
import '../../webview/view/webview_screen.dart';

class MainScreen extends StatelessWidget {
  final MainController controller = Get.put(MainController());

  MainScreen({super.key});

  final List<Widget> pages = [
    WebViewScreen(),
    const Center(child: Text("Notifications")),
    const Center(child: Text("Settings")),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, 
      body: Obx(() => IndexedStack(
            index: controller.currentIndex.value,
            children: pages,
          )),
      bottomNavigationBar: _buildGlassBottomBar(),
    );
  }

  Widget _buildGlassBottomBar() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Obx(() => BottomNavigationBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                currentIndex: controller.currentIndex.value,
                onTap: controller.changePage,
                selectedItemColor: Colors.blue,
                unselectedItemColor: Colors.grey,
                showSelectedLabels: false,
                showUnselectedLabels: false,
                items: const [
                  BottomNavigationBarItem(icon: Icon(Icons.home_max_rounded), label: "Home"),
                  BottomNavigationBarItem(icon: Icon(Icons.notifications_none_rounded), label: "Alerts"),
                  BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: "Settings"),
                ],
              )),
        ),
      ),
    );
  }
}
