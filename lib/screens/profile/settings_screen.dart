import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:local_auth/local_auth.dart'; // [1] Import ini
import '../../config/colors.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _supabase = Supabase.instance.client;
  // [2] Inisialisasi Local Auth
  final LocalAuthentication _localAuth = LocalAuthentication();
  
  bool _isLoading = true;
  bool _pushNotif = true;
  bool _emailNotif = false;
  bool _promoNotif = true;
  bool _biometric = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    // ... (Kode _loadSettings SAMA SEPERTI SEBELUMNYA) ...
    // Copy paste saja logika _loadSettings kamu yang tadi
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final data = await _supabase
          .from('profiles')
          .select('notification_push, notification_email, biometric_enabled')
          .eq('id', userId)
          .single();

      if (mounted) {
        setState(() {
          _pushNotif = data['notification_push'] ?? true;
          _emailNotif = data['notification_email'] ?? false;
          _biometric = data['biometric_enabled'] ?? false;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateSetting(String column, bool value) async {
    // ... (Kode _updateSetting SAMA SEPERTI SEBELUMNYA) ...
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;
      await _supabase.from('profiles').update({column: value}).eq('id', userId);
    } catch (e) {
      debugPrint("Error updating $column: $e");
    }
  }

  // [3] LOGIKA BARU: Cek Biometrik sebelum mengaktifkan
  Future<void> _toggleBiometric(bool value) async {
    // Jika User ingin MEMATIKAN (Value = false), langsung matikan saja
    if (!value) {
      setState(() => _biometric = false);
      _updateSetting('biometric_enabled', false);
      return;
    }

    // Jika User ingin MENYALAKAN (Value = true), Scan dulu!
    try {
      // Cek apakah HP support biometrik
      final bool canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final bool isDeviceSupported = await _localAuth.isDeviceSupported();

      if (!canCheckBiometrics || !isDeviceSupported) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Perangkat ini tidak mendukung Biometric ❌")),
          );
        }
        return;
      }

      // Lakukan Scanning
      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Scan sidik jari/wajah untuk mengaktifkan fitur ini',
        options: const AuthenticationOptions(
          biometricOnly: true, // Paksa pakai Biometric (bukan PIN HP)
          stickyAuth: true,
        ),
      );

      // Jika Scan Berhasil
      if (didAuthenticate) {
        setState(() => _biometric = true);
        await _updateSetting('biometric_enabled', true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Biometric Activated! 👆✅")),
          );
        }
      } else {
        // Jika Scan Gagal/Dibatalkan user
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Gagal verifikasi biometrik ❌")),
          );
        }
      }
    } catch (e) {
      debugPrint("Error Biometric: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Terjadi kesalahan sistem")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ... (AppBar & Body Structure SAMA) ...
      backgroundColor: AppColors.greyLight,
      appBar: AppBar(
        title: const Text("Settings", style: TextStyle(color: AppColors.darkPurple, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: AppColors.darkPurple),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppColors.primaryPink))
        : SingleChildScrollView(
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
                      _buildSwitch("Push Notifications", "Receive alerts on this device", _pushNotif, (v) {
                        setState(() => _pushNotif = v);
                        _updateSetting('notification_push', v);
                      }),
                      _buildDivider(),
                      _buildSwitch("Email Notifications", "Receive summaries via email", _emailNotif, (v) {
                        setState(() => _emailNotif = v);
                        _updateSetting('notification_email', v);
                      }),
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
                    // [4] PANGGIL FUNGSI _toggleBiometric DI SINI
                    _toggleBiometric, 
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