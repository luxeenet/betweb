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
      bottomNavigationBar: _buildGlassBottomBar(context),
    );
  }

  Widget _buildGlassBottomBar(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    return Obx(() {
      return AnimatedSlide(
        offset: controller.isBottomBarVisible.value ? Offset.zero : const Offset(0, 1.5),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: Container(
          height: 65 + bottomPadding,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.92), // Solid premium glass
            border: Border(
              top: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 0.5),
            ),
          ),
          child: ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Padding(
                padding: EdgeInsets.only(bottom: bottomPadding),
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
                      label: "Subscription",
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
        ),
      );
    });
  }
}

