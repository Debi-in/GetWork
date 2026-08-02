import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: const [
          ListTile(leading: Icon(Icons.palette_outlined), title: Text('Theme')),
          ListTile(leading: Icon(Icons.language), title: Text('Language')),
          ListTile(leading: Icon(Icons.info_outline), title: Text('About')),
          ListTile(leading: Icon(Icons.privacy_tip_outlined), title: Text('Privacy Policy')),
        ],
      ),
    );
  }
}
