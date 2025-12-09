import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/colors.dart';
import '../../widgets/pinky_popup.dart';

class CreatePinScreen extends StatefulWidget {
  const CreatePinScreen({super.key});

  @override
  State<CreatePinScreen> createState() => _CreatePinScreenState();
}

class _CreatePinScreenState extends State<CreatePinScreen> {
  final _pinController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;
  
  // Variabel untuk visibilitas password (opsional, tapi bagus untuk UX)
  bool _obscurePin = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _pinController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _savePin() async {
    // 1. Validasi Input
    if (_pinController.text.length != 6) {
      PinkyPopUp.show(
        context, 
        type: PopUpType.warning, 
        title: "PIN Tidak Valid", 
        message: "PIN harus terdiri dari 6 digit angka."
      );
      return;
    }

    if (_pinController.text != _confirmController.text) {
      PinkyPopUp.show(
        context, 
        type: PopUpType.error, 
        title: "Tidak Cocok", 
        message: "PIN dan Konfirmasi PIN harus sama persis."
      );
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      
      // 2. Simpan ke Database Supabase
      // Pastikan kolom 'pin' sudah dibuat di tabel 'profiles' via SQL Editor
      await Supabase.instance.client
          .from('profiles')
          .update({'pin': _pinController.text}) 
          .eq('id', userId);

      if (mounted) {
        // 3. Feedback Sukses
        PinkyPopUp.show(
          context, 
          type: PopUpType.success, 
          title: "PIN Berhasil Dibuat!", 
          message: "Sekarang transaksimu jauh lebih aman.",
          btnText: "Lanjut Transaksi",
          onPressed: () {
            Navigator.pop(context); // Tutup Dialog
            Navigator.pop(context, true); // Kembali ke halaman sebelumnya dengan hasil 'true'
          }, 
        );
      }
    } catch (e) {
      if (mounted) {
        PinkyPopUp.show(
          context, 
          type: PopUpType.error, 
          title: "Gagal Menyimpan", 
          message: "Terjadi kesalahan sistem. Coba lagi nanti ya."
        );
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
        title: const Text(
          "Buat PIN Transaksi", 
          style: TextStyle(color: AppColors.darkPurple, fontWeight: FontWeight.bold)
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.darkPurple),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
          child: Column(
            children: [
              // Ilustrasi / Icon Gembok
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primaryPink.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_outline_rounded, size: 60, color: AppColors.primaryPink),
              ),
              
              const SizedBox(height: 24),
              
              const Text(
                "Amankan Akunmu 🔐",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.darkPurple),
              ),
              const SizedBox(height: 8),
              const Text(
                "Buat 6 digit PIN untuk memverifikasi setiap transaksi keluar.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, height: 1.5),
              ),

              const SizedBox(height: 40),

              // Input PIN Baru
              _buildPinField(
                controller: _pinController,
                label: "PIN Baru",
                isObscure: _obscurePin,
                onToggleVisiblity: () => setState(() => _obscurePin = !_obscurePin),
              ),

              const SizedBox(height: 20),

              // Input Konfirmasi PIN
              _buildPinField(
                controller: _confirmController,
                label: "Konfirmasi PIN",
                isObscure: _obscureConfirm,
                onToggleVisiblity: () => setState(() => _obscureConfirm = !_obscureConfirm),
              ),

              const Spacer(),

              // Tombol Simpan
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _savePin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryPink,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _isLoading 
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                      : const Text("Simpan PIN", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPinField({
    required TextEditingController controller,
    required String label,
    required bool isObscure,
    required VoidCallback onToggleVisiblity,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkPurple),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FD),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            obscureText: isObscure,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24, 
              fontWeight: FontWeight.bold, 
              letterSpacing: 8, // Jarak antar angka biar kayak input PIN beneran
              color: AppColors.darkPurple
            ),
            decoration: InputDecoration(
              counterText: "", // Hilangkan counter '0/6'
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
              suffixIcon: IconButton(
                icon: Icon(
                  isObscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                  color: Colors.grey,
                ),
                onPressed: onToggleVisiblity,
              ),
            ),
          ),
        ),
      ],
    );
  }
}