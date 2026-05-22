import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:local_auth/local_auth.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_config.dart';
import '../../webview/controller/webview_controller.dart';
import '../../main/controller/main_controller.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _version = "1.1.0+12";
  bool _biometricsEnabled = AppConfig.enableBiometrics;
  final LocalAuthentication auth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _version = "${info.version}+${info.buildNumber}";
    });
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw Exception("Could not launch $urlString");
      }
    } catch (_) {
      Get.snackbar(
        "Link Error",
        "Could not open this page inside a browser.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF161616),
        colorText: Colors.white,
        borderColor: Colors.redAccent,
        borderWidth: 1,
        margin: const EdgeInsets.all(16),
      );
    }
  }

  Future<void> _toggleBiometrics(bool value) async {
    if (value) {
      final bool canAuthenticateWithBiometrics = await auth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await auth.isDeviceSupported();

      if (canAuthenticate) {
        try {
          final bool didAuthenticate = await auth.authenticate(
            localizedReason: 'Please authenticate to enable biometric login',
            persistAcrossBackgrounding: true,
            biometricOnly: true,
          );
          if (didAuthenticate) {
            setState(() => _biometricsEnabled = true);
            Get.snackbar(
              "Success",
              "Biometric login enabled",
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: const Color(0xFF161616),
              colorText: Colors.white,
              borderColor: const Color(0xFFFF7B2E),
              borderWidth: 1,
              margin: const EdgeInsets.all(16),
            );
          }
        } on LocalAuthException catch (e) {
          Get.snackbar(
            "Authentication Error",
            e.description ?? "Failed to authenticate",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: const Color(0xFF161616),
            colorText: Colors.white,
            borderColor: Colors.redAccent,
            borderWidth: 1,
            margin: const EdgeInsets.all(16),
          );
        } catch (e) {
          Get.snackbar(
            "Error",
            "Biometric authentication failed",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: const Color(0xFF161616),
            colorText: Colors.white,
            borderColor: Colors.redAccent,
            borderWidth: 1,
            margin: const EdgeInsets.all(16),
          );
        }
      } else {
        Get.snackbar(
          "Not Supported",
          "Biometrics not available on this device",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF161616),
          colorText: Colors.white,
          borderColor: Colors.grey,
          borderWidth: 1,
          margin: const EdgeInsets.all(16),
        );
      }
    } else {
      setState(() => _biometricsEnabled = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Sleek premium dark theme background
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () {
            final MainController mainController = Get.find<MainController>();
            mainController.changePage(0); // Switch tab back to Home Page
          },
        ),
        title: const Text(
          "Settings",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: Colors.white.withValues(alpha: 0.08),
            height: 0.5,
          ),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          const SizedBox(height: 20),
          _buildSectionHeader("Preferences"),
          _buildSettingItem(
            icon: Icons.notifications_active_outlined,
            title: "Push Notifications",
            trailing: Switch(
              value: AppConfig.enablePushNotifications,
              onChanged: (val) {},
              activeColor: const Color(0xFFFF7B2E),
              activeTrackColor: const Color(0xFFFF7B2E).withValues(alpha: 0.3),
              inactiveThumbColor: Colors.grey[400],
              inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          _buildSettingItem(
            icon: Icons.fingerprint_rounded,
            title: "Biometric Login",
            trailing: Switch(
              value: _biometricsEnabled,
              onChanged: (val) => _toggleBiometrics(val),
              activeColor: const Color(0xFFFF7B2E),
              activeTrackColor: const Color(0xFFFF7B2E).withValues(alpha: 0.3),
              inactiveThumbColor: Colors.grey[400],
              inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          const SizedBox(height: 15),
          _buildSectionHeader("App Info"),
          _buildSettingItem(
            icon: Icons.info_outline_rounded,
            title: "Version",
            trailing: Text(
              _version,
              style: TextStyle(
                color: Colors.grey[400],
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            onTap: () {},
          ),
          _buildSettingItem(
            icon: Icons.share_rounded,
            title: "Share App",
            onTap: () {
              Share.share("Check out ${AppConfig.appName}!");
            },
          ),
          _buildSettingItem(
            icon: Icons.star_border_rounded,
            title: "Rate Us",
            onTap: () {
              Get.snackbar(
                "Feedback Received",
                "Thank you for rating BetMakini app!",
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: const Color(0xFF161616),
                colorText: Colors.white,
                borderColor: const Color(0xFFFF7B2E),
                borderWidth: 1,
                margin: const EdgeInsets.all(16),
              );
            },
          ),
          const SizedBox(height: 15),
          _buildSectionHeader("Support"),
          _buildSettingItem(
            icon: Icons.help_outline_rounded,
            title: "Help & Support",
            onTap: () => _launchUrl("https://valley100.carrd.co"),
          ),
          _buildSettingItem(
            icon: Icons.delete_outline_rounded,
            title: "Clear App Cache",
            onTap: () {
              Get.defaultDialog(
                title: "Clear Cache",
                titleStyle: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                middleText: "This will clear all saved web data. Continue?",
                middleTextStyle: TextStyle(
                  color: Colors.grey[300],
                  fontSize: 14,
                ),
                backgroundColor: const Color(0xFF161616),
                textConfirm: "Clear",
                textCancel: "Cancel",
                confirmTextColor: Colors.white,
                cancelTextColor: const Color(0xFFFF7B2E),
                buttonColor: const Color(0xFFFF7B2E),
                radius: 20,
                onConfirm: () async {
                  Get.back();
                  // Clear cookies globally using webview_flutter
                  await WebViewCookieManager().clearCookies();
                  // Also clear cache if the controller is available
                  try {
                    final CustomWebViewController webController = Get.find<CustomWebViewController>();
                    await webController.webViewController.clearCache();
                  } catch (e) {
                    // Controller not initialized yet, that's fine
                  }
                  Get.snackbar(
                    "Success",
                    "Cache cleared successfully",
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: const Color(0xFF161616),
                    colorText: Colors.white,
                    borderColor: const Color(0xFFFF7B2E),
                    borderWidth: 1,
                    margin: const EdgeInsets.all(16),
                  );
                },
              );
            },
          ),
          _buildSettingItem(
            icon: Icons.privacy_tip_outlined,
            title: "Privacy Policy",
            onTap: () => _launchUrl("https://betimakini.butax.co.tz"),
          ),
          const SizedBox(height: 40),
          Center(
            child: Text(
              "© 2026 ${AppConfig.appName}",
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 100), // Space for bottom bar
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Color(0xFFFF7B2E), // Brand orange
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05),
          width: 0.8,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFFF7B2E).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: const Color(0xFFFF7B2E),
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: trailing ??
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.grey[600],
              size: 22,
            ),
        onTap: onTap,
      ),
    );
  }
}
