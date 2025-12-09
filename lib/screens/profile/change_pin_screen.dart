import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/colors.dart';

class ChangePinScreen extends StatefulWidget {
  const ChangePinScreen({super.key});

  @override
  State<ChangePinScreen> createState() => _ChangePinScreenState();
}

class _ChangePinScreenState extends State<ChangePinScreen> {
  final _oldPinController = TextEditingController();
  final _newPinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  final _supabase = Supabase.instance.client;
  bool _isLoading = false;

  Future<void> _savePin() async {
    // 1. Validasi Input
    if (_newPinController.text.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("PIN must be 6 digits")));
      return;
    }
    if (_newPinController.text != _confirmPinController.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("New PINs do not match")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      // 2. Ambil PIN Lama dari Database untuk verifikasi
      final data = await _supabase
          .from('profiles')
          .select('pin')
          .eq('id', user.id)
          .single();
      
      final currentDbPin = data['pin'] as String?;

      // Jika user sudah punya PIN, cek apakah PIN lama cocok
      if (currentDbPin != null && currentDbPin.isNotEmpty) {
        if (_oldPinController.text != currentDbPin) {
           if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Incorrect Current PIN ❌"), backgroundColor: Colors.red));
            setState(() => _isLoading = false);
           }
           return;
        }
      }

      // 3. Update PIN Baru ke Database
      await _supabase.from('profiles').update({
        'pin': _newPinController.text,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', user.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("PIN Changed Successfully! 🔒")));
        Navigator.pop(context);
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Change PIN", style: TextStyle(color: AppColors.darkPurple, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: AppColors.darkPurple),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text("Secure your account by updating your PIN regularly.", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 32),
            _buildPinField("Current PIN", _oldPinController),
            const SizedBox(height: 16),
            _buildPinField("New PIN (6 Digits)", _newPinController),
            const SizedBox(height: 16),
            _buildPinField("Confirm New PIN", _confirmPinController),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _savePin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.darkPurple,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Update PIN", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPinField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      obscureText: true,
      keyboardType: TextInputType.number,
      maxLength: 6,
      decoration: InputDecoration(
        labelText: label,
        counterText: "",
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryPink, width: 2),
        ),
      ),
    );
  }
}