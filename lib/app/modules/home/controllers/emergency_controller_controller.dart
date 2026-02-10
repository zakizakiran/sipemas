import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../../../data/models/laporan_darurat.dart';

class EmergencyController extends GetxController {
  // State untuk UI
  var isCountingDown = false.obs;
  var countdownValue = 3.obs;
  var statusTampilan = "Siaga".obs; // Default status
  Timer? _timer;

  // --- IMPLEMENTASI SEQUENCE ANTI FALSE ALARM (Hal. 34) ---

  // Pesan 2: prosesVerifikasiDarurat
  void prosesVerifikasiDarurat() {
    // Pesan 3: cekModeAlarm (Asumsi default TRUE/ALARM KERAS)
    bool isHardAlarm = true;

    if (isHardAlarm) {
      // Pesan 4: Tampilkan Countdown (3 Detik)
      startCountdown();
    } else {
      // Bypass jika mode senyap
      prosesKirimDarurat("SENYAP");
    }
  }

  void startCountdown() {
    isCountingDown.value = true;
    countdownValue.value = 3;
    statusTampilan.value = "Menunggu Verifikasi...";

    // Pesan 5: visualisasiTimer (dilakukan via Reactive Variable countdownValue di UI)
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (countdownValue.value > 1) {
        countdownValue.value--;
      } else {
        // Countdown selesai
        timer.cancel();
        isCountingDown.value = false;
        // Pesan 10: validasiFalseAlarm & Pesan 17: verifikasiSukses
        prosesKirimDarurat("ALARM");
      }
    });
  }

  // Pesan 6: tekanTombolBatal
  void tekanTombolBatal() {
    if (_timer != null) {
      _timer!.cancel();
    }
    // Pesan 7: batalkanProses
    batalkanProses();
  }

  // Pesan 7: batalkanProses
  void batalkanProses() {
    isCountingDown.value = false;
    // Pesan 8: statusDibatalkan
    statusTampilan.value = "Alarm Dibatalkan";
    // Pesan 9: tampilkanPesan
    Get.snackbar("Info", "Alarm Dibatalkan");

    // Reset status ke Siaga setelah beberapa detik
    Future.delayed(Duration(seconds: 2), () => statusTampilan.value = "Siaga");
  }

  // --- IMPLEMENTASI SEQUENCE KIRIM DARURAT (Hal. 28) ---

  // Pesan 3: prosesKirimDarurat
  void prosesKirimDarurat(String mode) async {
    // Pesan 19: tampilkanStatus("Mengirim Bantuan")
    statusTampilan.value = "Mengirim Bantuan...";

    try {
      // Pesan 4: ambilLokasiRealTime
      Position position = await _determinePosition();
      String lokasi = "${position.latitude}, ${position.longitude}";

      // Pesan 5: <<create>> LaporanDarurat
      LaporanDarurat laporan = LaporanDarurat(
        idLaporan: DateTime.now().millisecondsSinceEpoch.toString(), // Pesan 11
        tipeKejadian: "SOS",
        statusLaporan: "AKTIF", // Pesan 9
        waktu: DateTime.now(), // Pesan 8
        lokasiGPS: lokasi, // Pesan 7
        modeAlarm: mode, // Pesan 6
      );

      // Simulasi kirim ke API/Backend
      await Future.delayed(Duration(seconds: 2));

      // Pesan 12: broadcastNotifikasi
      broadcastNotifikasi();

      // Pesan 13: suksesTerkirim
      Get.snackbar(
        "DARURAT",
        "Sinyal SOS Terkirim! Lokasi: $lokasi",
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: Duration(seconds: 5),
      );
      statusTampilan.value = "Bantuan Sedang Dikirim";
    } catch (e) {
      // Error handling GPS
      String errorMsg = "Gagal mendapatkan lokasi";
      if (e.toString().contains('disabled')) {
        errorMsg = "GPS tidak aktif. Silakan aktifkan GPS";
      } else if (e.toString().contains('denied')) {
        errorMsg = "Izin lokasi ditolak. Silakan berikan izin";
      }

      Get.snackbar(
        "Error",
        errorMsg,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        duration: Duration(seconds: 4),
      );
      statusTampilan.value = "Gagal Kirim";

      // Reset status setelah 2 detik
      Future.delayed(Duration(seconds: 2), () {
        statusTampilan.value = "Siaga";
      });
    }
  }

  void broadcastNotifikasi() {
    print("Broadcasting notification to nearby users...");
  }

  // Fungsi Helper untuk GPS (Sesuai dokumentasi Geolocator)
  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      Get.snackbar(
        "GPS Nonaktif",
        "Silakan aktifkan GPS di pengaturan perangkat",
        snackPosition: SnackPosition.BOTTOM,
        duration: Duration(seconds: 3),
      );
      return Future.error('Location services are disabled.');
    }

    // Check permission status
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      // Request permission
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        Get.snackbar(
          "Izin Ditolak",
          "Aplikasi memerlukan izin lokasi untuk mengirim sinyal darurat",
          snackPosition: SnackPosition.BOTTOM,
          duration: Duration(seconds: 3),
        );
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      Get.snackbar(
        "Izin Ditolak Permanen",
        "Silakan aktifkan izin lokasi di pengaturan aplikasi",
        snackPosition: SnackPosition.BOTTOM,
        duration: Duration(seconds: 4),
      );
      return Future.error('Location permissions are permanently denied.');
    }

    // Get current position
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }
}
