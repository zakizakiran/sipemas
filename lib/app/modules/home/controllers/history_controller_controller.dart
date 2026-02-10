import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../data/models/laporan_darurat.dart';
import '../views/widgets/rating_dialog.dart';

class HistoryController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Observable list untuk menampung data riwayat
  var riwayatList = <LaporanDarurat>[].obs;
  var isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    // Panggil fungsi pemantau data
    listenToMyHistory();
  }

  // Use Case: Melihat daftar riwayat sendiri
  void listenToMyHistory() {
    String myId = _auth.currentUser?.uid ?? "";

    if (myId.isEmpty) {
      isLoading.value = false;
      return;
    }

    _firestore
        .collection('laporan_darurat')
        .where('pembuat_id', isEqualTo: myId) // Filter hanya punya saya
        // .orderBy('waktu', descending: true) // Dihapus untuk menghindari error Index Firebase
        .snapshots()
        .listen((snapshot) {
          var list = snapshot.docs.map((doc) {
            return LaporanDarurat.fromJson(doc.data());
          }).toList();

          // Sorting Client Side (Terbaru di atas)
          list.sort((a, b) => b.waktu.compareTo(a.waktu));

          riwayatList.value = list;
          isLoading.value = false;
        });
  }

  // Selesaikan Laporan dengan Feedback (Umpan Balik Sequence Hal. 35)
  void selesaikanLaporan(String idLaporan) {
    // Tampilkan BottomSheet Rating alih-alih Dialog
    Get.bottomSheet(
      RatingBottomSheet(idLaporan: idLaporan),
      isScrollControlled: true, // Agar bisa full height jika perlu
    );
  }

  // Use Case: Membatalkan laporan
  Future<void> batalkanLaporan(String idLaporan) async {
    try {
      await _firestore.collection('laporan_darurat').doc(idLaporan).update({
        'status_laporan': 'DIBATALKAN',
      });
      Get.snackbar("Sukses", "Laporan berhasil dibatalkan");
    } catch (e) {
      Get.snackbar("Error", "Gagal membatalkan laporan: $e");
    }
  }
}
