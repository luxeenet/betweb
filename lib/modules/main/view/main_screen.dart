import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:ui';
import '../controller/main_controller.dart';
import '../../settings/view/settings_screen.dart';
import '../../webview/view/webview_screen.dart';

class MainScreen extends StatelessWidget {
  final MainController controller = Get.put(MainController());

  MainScreen({super.key});

  final List<Widget> pages = [
    WebViewScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, 
      backgroundColor: Colors.black, // Match professional dark theme
      body: Obx(() => IndexedStack(
            index: controller.currentIndex.value == 4 ? 1 : 0,
            children: pages,
          )),
      bottomNavigationBar: _buildGlassBottomBar(),
    );
  }

  Widget _buildGlassBottomBar() {
    return Obx(() {
      return AnimatedSlide(
        offset: controller.isBottomBarVisible.value ? Offset.zero : const Offset(0, 1.5),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: Container(
          margin: const EdgeInsets.only(bottom: 20, left: 16, right: 16),
          height: 70,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 20,
                offset: const Offset(0, 10),
              )
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: BottomNavigationBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                currentIndex: controller.currentIndex.value,
                onTap: controller.changePage,
                selectedItemColor: const Color(0xFFFF7B2E), // Premium orange to match web theme
                unselectedItemColor: Colors.grey[500],
                type: BottomNavigationBarType.fixed,
                showSelectedLabels: true,
                showUnselectedLabels: true,
                selectedLabelStyle: const TextStyle(
                  fontSize: 10, 
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 10, 
                  fontWeight: FontWeight.normal,
                ),
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home_rounded), 
                    label: "Home",
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.sports_soccer_rounded), 
                    label: "Betslips",
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.workspace_premium_rounded), 
                    label: "VIP",
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.person_rounded), 
                    label: "Account",
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.settings_rounded), 
                    label: "Settings",
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}

