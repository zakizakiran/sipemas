import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../../../data/models/laporan_darurat.dart';

class RewardController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Use Case: Sistem memverifikasi kehadiran via geofencing (Main Flow Step 1)
  Future<void> verifikasiKehadiranDanKlaimPoin(LaporanDarurat laporan) async {
    User? user = _auth.currentUser;
    if (user == null) {
      Get.snackbar("Gagal", "Anda harus login untuk mendapatkan poin.");
      return;
    }

    // Jangan beri poin ke pembuat laporan sendiri (Opsional, tergantung aturan)
    if (laporan.pembuatId == user.uid) {
      Get.snackbar("Info", "Anda tidak bisa klaim poin dari laporan sendiri.");
      return;
    }

    try {
      // 1. Dapatkan Lokasi Saya (Aktual)
      Position myPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // 2. Parse Lokasi Laporan
      List<String> latlong = laporan.lokasiGPS.split(',');
      double targetLat = double.parse(latlong[0].trim());
      double targetLng = double.parse(latlong[1].trim());

      // 3. Hitung Jarak (dalam Meter)
      double distanceInMeters = Geolocator.distanceBetween(
        myPosition.latitude,
        myPosition.longitude,
        targetLat,
        targetLng,
      );

      // Threshold Geofencing (Misal: Harus dalam radius 50 meter)
      double radiusThreshold = 50.0;

      if (distanceInMeters <= radiusThreshold) {
        // --- Main Flow Step 2: Sistem menambahkan poin ---
        await _tambahPoinKeUser(user.uid, 10); // +10 Poin per bantuan
        await _tambahHelperLaporan(
          laporan.idLaporan,
        ); // Tambahkan counter helper

        Get.back(); // Tutup Dialog
        Get.snackbar(
          "Verifikasi Berhasil!",
          "Anda berada di lokasi ($distanceInMeters m).\nPoin +10 ditambahkan ke akun Anda.",
          duration: const Duration(seconds: 4),
          backgroundColor: Get.theme.primaryColor.withOpacity(0.1),
        );

        // --- Main Flow Step 3: Update Leaderboard ---
        // (Otomatis terjadi karena data poin user diupdate)
      } else {
        // --- Extension 1.1: Verifikasi gagal (jarak tak sesuai) ---
        Get.snackbar(
          "Verifikasi Gagal",
          "Anda masih terlalu jauh dari lokasi kejadian.\nJarak: ${distanceInMeters.toStringAsFixed(1)} meter.\n(Radius wajib: $radiusThreshold m)",
          backgroundColor: Get.theme.colorScheme.error.withOpacity(0.1),
        );
      }
    } catch (e) {
      Get.snackbar("Error", "Gagal verifikasi lokasi: $e");
    }
  }

  Future<void> _tambahPoinKeUser(String uid, int poin) async {
    DocumentReference userRef = _firestore.collection('users').doc(uid);

    await _firestore.runTransaction((transaction) async {
      DocumentSnapshot snapshot = await transaction.get(userRef);

      if (!snapshot.exists) {
        // Buat data baru jika belum ada
        transaction.set(userRef, {'total_poin': poin});
      } else {
        int currentPoin =
            (snapshot.data() as Map<String, dynamic>)['total_poin'] ?? 0;
        transaction.update(userRef, {'total_poin': currentPoin + poin});
      }
    });
  }

  Future<void> _tambahHelperLaporan(String idLaporan) async {
    try {
      await _firestore.collection('laporan_darurat').doc(idLaporan).update({
        'jumlah_helper': FieldValue.increment(1),
      });
    } catch (e) {
      print("Gagal update helper: $e");
    }
  }
}
