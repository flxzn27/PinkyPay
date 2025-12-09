import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/transaction_model.dart';

class TransactionService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ----------------------------------------------------------
  // 1. TOP UP
  // ----------------------------------------------------------
  Future<void> topUp(double amount, String bank) async {
    final userId = _supabase.auth.currentUser!.id;

    // Update saldo (Supabase Function)
    await _supabase.rpc('increment_balance', params: {
      'amount': amount,
      'row_id': userId,
    });

    // Simpan riwayat transaksi
    await _supabase.from('transactions').insert({
      'user_id': userId,
      'type': 'topup',
      'amount': amount,
      'description': 'Top Up via $bank',
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // ----------------------------------------------------------
  // 2. TRANSFER
  // ----------------------------------------------------------
  Future<void> transfer({
    required String recipientEmail,
    required double amount,
    required String note,
  }) async {
    final userId = _supabase.auth.currentUser!.id;

    // RPC untuk memproses transfer (update saldo kedua user)
    await _supabase.rpc('handle_transfer', params: {
      'recipient_email': recipientEmail,
      'transfer_amount': amount,
      'note': note,
    });

    // SIMPAN TRANSAKSI KE PENGIRIM
    await _supabase.from('transactions').insert({
      'user_id': userId,
      'type': 'payment',
      'amount': amount,
      'description': note,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // ----------------------------------------------------------
  // 3. SPLIT BILL (BAYAR/TALANGIN KE MERCHANT)
  // ----------------------------------------------------------
  Future<void> paySplitBill(double amount, String note) async {
    final userId = _supabase.auth.currentUser!.id;

    // Kurangi saldo (angka negatif) karena user menalangin full amount
    await _supabase.rpc('increment_balance', params: {
      'amount': -amount,
      'row_id': userId,
    });

    // Simpan transaksi
    await _supabase.from('transactions').insert({
      'user_id': userId,
      'type': 'split_bill',
      'amount': amount,
      'description': note,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // ----------------------------------------------------------
  // 4. GET TRANSACTIONS (AMAN DAN TERURUT)
  // ----------------------------------------------------------
  Future<List<TransactionModel>> getTransactions() async {
    final userId = _supabase.auth.currentUser!.id;

    final List<dynamic> response = await _supabase
        .from('transactions')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return response
        .map((json) => TransactionModel.fromJson(json))
        .toList();
  }

  // ----------------------------------------------------------
  // 5. CREATE SPLIT REQUEST (CATAT HUTANG TEMAN)
  // ----------------------------------------------------------
  Future<void> createSplitRequest({
    required String debtorId,
    required double amount,
    required String note,
  }) async {
    final payerId = _supabase.auth.currentUser!.id;
    
    // Insert ke tabel split_requests
    await _supabase.from('split_requests').insert({
      'payer_id': payerId,   // ID Kamu (Yang menalangin)
      'debtor_id': debtorId, // ID Teman (Yang berhutang)
      'amount': amount,
      'description': note,
      'status': 'pending',   // Status awal hutang
    });
  }

  // ----------------------------------------------------------
  // 6. AMBIL DAFTAR TAGIHAN MASUK (VERSI DEBUGGING)
  // ----------------------------------------------------------
  Future<List<Map<String, dynamic>>> getIncomingSplitRequests() async {
    final userId = _supabase.auth.currentUser!.id;
    
    // [DEBUG 1] Cek ID kita
    print("\n🔍 DEBUG START: Mencari tagihan untuk User ID: $userId");

    try {
      // [DEBUG 2] Cek Data Mentah (Tanpa Join, Tanpa Filter Status)
      // Ini untuk membuktikan apakah ada data sama sekali di database.
      final rawCheck = await _supabase
          .from('split_requests')
          .select()
          .eq('debtor_id', userId);
      
      print("🔍 DEBUG RAW DATA: Ditemukan ${rawCheck.length} baris data mentah.");
      
      if (rawCheck.isNotEmpty) {
        print("   -> Contoh data pertama: ${rawCheck.first}");
        print("   -> Status data pertama: ${rawCheck.first['status']}");
      } else {
        print("❌ DEBUG ERROR: Database KOSONG untuk debtor_id ini. Mungkin salah akun?");
        return [];
      }

      // [DEBUG 3] Jika data mentah ada, baru kita coba Join
      print("🔍 DEBUG JOIN: Mencoba mengambil data lengkap dengan relasi profiles...");
      
      final response = await _supabase
          .from('split_requests')
          .select('*, payer:profiles!payer_id(full_name, email, avatar_url)') 
          .eq('debtor_id', userId)
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      print("✅ DEBUG SUCCESS: Berhasil mengambil ${response.length} data lengkap.");
      return List<Map<String, dynamic>>.from(response);

    } catch (e) {
      print("🔥 DEBUG ERROR FATAL: Terjadi error saat request!");
      print("   -> Pesan Error: $e");
      return [];
    }
  }

  // ----------------------------------------------------------
  // [FINAL FIXED] 7. BAYAR HUTANG SPLIT BILL
  // ----------------------------------------------------------
  Future<void> repaySplitBill({
    required int requestId,
    required String payerId,
    required double amount,
    required String note,
  }) async {
    final myId = _supabase.auth.currentUser!.id;   
    await _supabase.rpc('repay_split_bill', params: {
      'request_id': requestId,
      'payer_id': payerId,
      'debtor_id': myId,
      'amount': amount,
      'note': note,
    });        
  }
}