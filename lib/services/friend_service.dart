import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../models/friend_model.dart';

class FriendService {
  final _supabase = Supabase.instance.client;

  /// 1. Cari User berdasarkan Email (untuk Add Friend)
  Future<List<UserModel>> searchUsers(String emailQuery) async {
    final myId = _supabase.auth.currentUser!.id;

    // Cari di tabel profiles yang email-nya mirip query
    final response = await _supabase
        .from('profiles')
        .select()
        .ilike('email', '%$emailQuery%') // Case insensitive search
        .neq('id', myId); // Jangan tampilkan diri sendiri

    return (response as List).map((e) => UserModel.fromJson(e)).toList();
  }

  /// 2. Kirim Permintaan Pertemanan
  Future<void> sendFriendRequest(String targetUserId) async {
    final myId = _supabase.auth.currentUser!.id;

    // Cek apakah sudah ada request sebelumnya (pending/accepted)
    // Supaya tidak double request jika constraint database belum jalan
    final check = await _supabase.from('friendships').select().or(
        'and(user_id_1.eq.$myId, user_id_2.eq.$targetUserId), and(user_id_1.eq.$targetUserId, user_id_2.eq.$myId)');

    if ((check as List).isNotEmpty) {
      throw "Permintaan pertemanan sudah ada atau kalian sudah berteman.";
    }

    // Insert request baru
    await _supabase.from('friendships').insert({
      'user_id_1': myId,
      'user_id_2': targetUserId,
      'status': 'pending',
    });
  }

  /// 3. Ambil Daftar Teman Saya (Status: Accepted)
  Future<List<FriendModel>> getMyFriends() async {
    final myId = _supabase.auth.currentUser!.id;

    // Kita ambil data friendship di mana kita sebagai user_1 ATAU user_2
    // DAN statusnya sudah 'accepted'
    // Syntax `sender:profiles!user_id_1(*)` artinya: join tabel profiles via kolom user_id_1, beri nama 'sender'
    final response = await _supabase
        .from('friendships')
        .select('*, sender:profiles!user_id_1(*), receiver:profiles!user_id_2(*)')
        .or('user_id_1.eq.$myId, user_id_2.eq.$myId')
        .eq('status', 'accepted');

    return (response as List).map((e) => FriendModel.fromJson(e)).toList();
  }

  /// 4. Ambil Request Masuk (Incoming Requests)
  Future<List<FriendModel>> getIncomingRequests() async {
    final myId = _supabase.auth.currentUser!.id;

    // Request masuk berarti: user_id_2 adalah SAYA, dan status 'pending'
    final response = await _supabase
        .from('friendships')
        .select('*, sender:profiles!user_id_1(*)') // Kita cuma butuh info pengirim
        .eq('user_id_2', myId)
        .eq('status', 'pending');

    return (response as List).map((e) => FriendModel.fromJson(e)).toList();
  }

  /// 5. Terima Pertemanan
  Future<void> acceptRequest(String friendshipId) async {
    await _supabase
        .from('friendships')
        .update({'status': 'accepted'})
        .eq('id', friendshipId);
  }

  /// 6. Tolak / Hapus Teman
  Future<void> deleteFriendship(String friendshipId) async {
    await _supabase
        .from('friendships')
        .delete()
        .eq('id', friendshipId);
  }
}