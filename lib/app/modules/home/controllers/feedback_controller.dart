import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FeedbackController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Method sesuai Sequence Diagram: kirimUmpanBalik()
  Future<void> kirimUmpanBalik(
    String idLaporan,
    double rating,
    String komentar,
  ) async {
    try {
      // 1. Simpan Data Feedback ke Koleksi Baru
      await _firestore.collection('ulasan').add({
        'id_laporan': idLaporan,
        'rating': rating,
        'komentar': komentar,
        'pengirim_id': FirebaseAuth.instance.currentUser?.uid,
        'waktu': DateTime.now(),
      });

      // 2. Update Status Laporan jadi SELESAI (Jika belum)
      await _firestore.collection('laporan_darurat').doc(idLaporan).update({
        'status_laporan': 'SELESAI',
      });

      // 3. (Opsional) Tambah Poin Reward ke Diri Sendiri/Penolong
      // Sesuai Use Case Reward & Komunitas

      Get.back(); // Tutup Dialog
      Get.snackbar("Terima Kasih", "Masukan Anda telah kami terima.");
    } catch (e) {
      Get.snackbar("Error", "Gagal mengirim ulasan: $e");
    }
  }
}
