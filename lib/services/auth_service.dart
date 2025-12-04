import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  User? get currentUser => _supabase.auth.currentUser;

  // LOGIN
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    // Setelah login, pastikan profile ada (auto-heal)
    final user = response.user;
    if (user != null) {
      final profile = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (profile == null) {
        // Buat profile jika hilang
        await _supabase.from('profiles').insert({
          'id': user.id,
          'email': email,
          'full_name': 'New User',
          'balance': 0,
          'avatar_url': '',
        });
      }
    }

    return response;
  }

  // REGISTER
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    // Aktifkan autoConfirm biar langsung punya user.id
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': fullName,
      },
    );

    // Tunggu sampai Supabase memberi user.id
    final user = response.user;

    if (user != null) {
      await _supabase.from('profiles').insert({
        'id': user.id,
        'email': email,
        'full_name': fullName,
        'balance': 0,
        'avatar_url': '',
      });
    }

    return response;
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}
