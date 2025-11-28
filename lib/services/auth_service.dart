import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  // Instance client Supabase
  final SupabaseClient _supabase = Supabase.instance.client;

  // Cek user yang sedang login
  User? get currentUser => _supabase.auth.currentUser;

  // Fungsi Login Email & Password
  Future<AuthResponse> signIn({required String email, required String password}) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // Fungsi Register (Sign Up)
  // Sekalian buat data Profile (Nama & Saldo 0)
  Future<AuthResponse> signUp({
    required String email, 
    required String password,
    required String fullName,
  }) async {
    // 1. Daftar Akun Auth
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
    );

    // 2. Jika sukses, buat data Profile
    if (response.user != null) {
      await _supabase.from('profiles').insert({
        'id': response.user!.id, // ID Profile = ID User Auth
        'email': email,
        'full_name': fullName,
        'balance': 0, // Saldo awal 0
        'avatar_url': '',
      });
    }

    return response;
  }

  // Fungsi Logout
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}