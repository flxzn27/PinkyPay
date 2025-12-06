import 'package:flutter/material.dart';
import '../../config/colors.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pushNotif = true;
  bool _emailNotif = false;
  bool _promoNotif = true;
  bool _biometric = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.greyLight,
      appBar: AppBar(
        title: const Text("Settings", style: TextStyle(color: AppColors.darkPurple, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: AppColors.darkPurple),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Notifications", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  _buildSwitch("Push Notifications", "Receive alerts on this device", _pushNotif, (v) => setState(() => _pushNotif = v)),
                  _buildDivider(),
                  _buildSwitch("Email Notifications", "Receive summaries via email", _emailNotif, (v) => setState(() => _emailNotif = v)),
                  _buildDivider(),
                  _buildSwitch("Promo & Offers", "Get updates on new rewards", _promoNotif, (v) => setState(() => _promoNotif = v)),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            const Text("Security", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: _buildSwitch(
                "Biometric Login", 
                "FaceID / Fingerprint", 
                _biometric, 
                (v) {
                  setState(() => _biometric = v);
                  if(v) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Biometric Enabled! 👆")));
                }
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitch(String title, String subtitle, bool val, Function(bool) onChanged) {
    return SwitchListTile(
      value: val,
      onChanged: onChanged,
      activeColor: AppColors.primaryPink,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkPurple)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, thickness: 1, indent: 16, endIndent: 16);
  }
}