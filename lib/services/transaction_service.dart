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
  // 3. SPLIT BILL
  // ----------------------------------------------------------
  Future<void> paySplitBill(double amount, String note) async {
    final userId = _supabase.auth.currentUser!.id;

    // Kurangi saldo (angka negatif)
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
}
