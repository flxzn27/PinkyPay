import 'dart:typed_data'; // PENTING: Untuk kompatibilitas Web & Mobile
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/colors.dart';
import '../../models/user_model.dart';

class EditProfileScreen extends StatefulWidget {
  final UserModel user;

  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  
  bool _isLoading = false;
  
  // Variable untuk menyimpan data gambar (Bytes)
  Uint8List? _imageBytes; 
  String? _imageExtension; 
  
  final _picker = ImagePicker();
  final _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _emailController = TextEditingController(text: widget.user.email);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  // --- 1. LOGIC PILIH FOTO (Universal) ---
  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70, // Kompresi gambar agar ringan
      );

      if (pickedFile != null) {
        // Baca file sebagai Bytes (aman untuk Web & Mobile)
        final bytes = await pickedFile.readAsBytes();
        final ext = pickedFile.name.split('.').last; 

        setState(() {
          _imageBytes = bytes;
          _imageExtension = ext;
        });
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  // --- 2. LOGIC UPLOAD & UPDATE ---
  Future<void> _updateProfile() async {
    setState(() => _isLoading = true);

    try {
      String? avatarUrl = widget.user.avatarUrl;
      final userId = widget.user.id;

      // A. Jika ada foto baru, Upload Binary ke Storage
      if (_imageBytes != null) {
        // Gunakan tanda '/' agar masuk ke folder user (Sesuai Policy RLS)
        final fileName = '$userId/${DateTime.now().millisecondsSinceEpoch}.${_imageExtension ?? 'jpg'}';
        
        try {
          // Gunakan uploadBinary (Metode paling stabil)
          await _supabase.storage.from('avatars').uploadBinary(
            fileName,
            _imageBytes!,
            fileOptions: const FileOptions(upsert: true),
          );
          
          // Ambil Public URL gambar yang baru diupload
          avatarUrl = _supabase.storage.from('avatars').getPublicUrl(fileName);
        } catch (storageError) {
          throw 'Gagal upload foto. Cek Policy Storage Supabase Anda: $storageError';
        }
      }

      // B. Update Data Profil ke Database
      final Map<String, dynamic> updates = {
        // HANYA update 'full_name'. Jangan kirim 'name' jika tidak ada kolomnya.
        'full_name': _nameController.text.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Hanya masukkan avatar_url jika ada perubahan
      if (avatarUrl != null && avatarUrl.isNotEmpty) {
        updates['avatar_url'] = avatarUrl;
      }

      await _supabase.from('profiles').update(updates).eq('id', userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully! ✅')),
        );
        Navigator.pop(context, true); // Kembali & Refresh halaman sebelumnya
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
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
        title: const Text("Edit Profile", style: TextStyle(color: AppColors.darkPurple, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: AppColors.darkPurple),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // --- FOTO PROFIL ---
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.greyLight, width: 4),
                    ),
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: AppColors.lightPeach,
                      // Logic Tampilan:
                      // 1. Prioritas Bytes (Gambar baru dipilih)
                      // 2. URL (Gambar lama dari DB)
                      backgroundImage: _imageBytes != null
                          ? MemoryImage(_imageBytes!) as ImageProvider
                          : (widget.user.avatarUrl.isNotEmpty
                              ? NetworkImage(widget.user.avatarUrl)
                              : null),
                      child: (_imageBytes == null && widget.user.avatarUrl.isEmpty)
                          ? Text(
                              widget.user.name.isNotEmpty ? widget.user.name[0].toUpperCase() : '?',
                              style: const TextStyle(fontSize: 40, color: AppColors.primaryPink, fontWeight: FontWeight.bold),
                            )
                          : null,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryPink,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            const Text("Change Picture", style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 32),
            
            // --- FORM INPUT ---
            _buildTextField("Full Name", _nameController, false),
            const SizedBox(height: 16),
            _buildTextField("Email Address", _emailController, true), // Read Only
            
            const SizedBox(height: 40),
            
            // --- TOMBOL SAVE ---
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _updateProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPink,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                ),
                child: _isLoading 
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                    : const Text("Save Changes", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, bool readOnly) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          readOnly: readOnly,
          style: TextStyle(color: readOnly ? Colors.grey : AppColors.darkPurple, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            filled: true,
            fillColor: readOnly ? Colors.grey[100] : AppColors.greyLight,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            suffixIcon: readOnly ? const Icon(Icons.lock_outline, size: 18, color: Colors.grey) : null,
          ),
        ),
      ],
    );
  }
}