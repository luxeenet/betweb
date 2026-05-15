import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../../../core/constants/app_config.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _version = "1.0.5+7";
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

  Future<void> _toggleBiometrics(bool value) async {
    if (value) {
      final bool canAuthenticateWithBiometrics = await auth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await auth.isDeviceSupported();
      
      if (canAuthenticate) {
        try {
          final bool didAuthenticate = await auth.authenticate(
            localizedReason: 'Please authenticate to enable biometric login',
            persistAcrossBackgrounding: true,
            biometricOnly: true,
          );
          if (didAuthenticate) {
            setState(() => _biometricsEnabled = true);
            Get.snackbar("Success", "Biometric login enabled", 
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.green.withValues(alpha: 0.8),
              colorText: Colors.white);
          }
        } on LocalAuthException catch (e) {
          Get.snackbar("Authentication Error", e.description ?? "Failed to authenticate",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red.withValues(alpha: 0.8),
            colorText: Colors.white);
        } catch (e) {
          Get.snackbar("Error", "Biometric authentication failed",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red.withValues(alpha: 0.8),
            colorText: Colors.white);
        }
      } else {
        Get.snackbar("Not Supported", "Biometrics not available on this device",
          snackPosition: SnackPosition.BOTTOM);
      }
    } else {
      setState(() => _biometricsEnabled = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 20),
          _buildSectionHeader("Preferences"),
          _buildSettingItem(
            icon: Icons.notifications_active_outlined,
            title: "Push Notifications",
            trailing: Switch(
              value: AppConfig.enablePushNotifications,
              onChanged: (val) {},
              activeColor: Colors.blue,
            ),
          ),
          _buildSettingItem(
            icon: Icons.fingerprint_rounded,
            title: "Biometric Login",
            trailing: Switch(
              value: _biometricsEnabled,
              onChanged: (val) => _toggleBiometrics(val),
              activeColor: Colors.blue,
            ),
          ),
          const Divider(indent: 20, endIndent: 20),
          _buildSectionHeader("App info"),
          _buildSettingItem(
            icon: Icons.info_outline_rounded,
            title: "Version",
            trailing: Text(_version, style: const TextStyle(color: Colors.grey)),
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
            onTap: () {},
          ),
          const Divider(indent: 20, endIndent: 20),
          _buildSectionHeader("Support"),
          _buildSettingItem(
            icon: Icons.help_outline_rounded,
            title: "Help & Support",
            onTap: () {},
          ),
          _buildSettingItem(
            icon: Icons.delete_outline_rounded,
            title: "Clear App Cache",
            onTap: () {
              Get.defaultDialog(
                title: "Clear Cache",
                middleText: "This will clear all saved web data. Continue?",
                textConfirm: "Clear",
                textCancel: "Cancel",
                confirmTextColor: Colors.white,
                onConfirm: () async {
                  Get.back();
                  // Note: In a real app, you'd access the InAppWebViewController
                  // For now, we show a success message as a native feature demonstration
                  await InAppWebViewController.clearAllCache();
                  Get.snackbar("Success", "Cache cleared successfully",
                    snackPosition: SnackPosition.BOTTOM);
                }
              );
            },
          ),
          _buildSettingItem(
            icon: Icons.privacy_tip_outlined,
            title: "Privacy Policy",
            onTap: () {},
          ),
          const SizedBox(height: 40),
          Center(
            child: Text(
              "© 2026 ${AppConfig.appName}",
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
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
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
          letterSpacing: 1.2,
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
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(title, style: const TextStyle(fontSize: 16)),
      trailing: trailing ?? const Icon(Icons.chevron_right_rounded, color: Colors.grey),
      onTap: onTap,
    );
  }
}
