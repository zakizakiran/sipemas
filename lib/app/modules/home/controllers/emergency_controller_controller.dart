import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:vibration/vibration.dart';
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
    FlutterRingtonePlayer().stop();
    Vibration.cancel();
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

  // Instance Firestore
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  @override
  void onInit() {
    super.onInit();
    // Jalankan Listener saat aplikasi dibuka agar bisa menerima broadcast orang lain
    listenToBroadcasts();
  }

  @override
  void onClose() {
    FlutterRingtonePlayer().stop();
    Vibration.cancel();
    _timer?.cancel();
    super.onClose();
  }

  // --- FUNGSI 1: BROADCAST KE USER LAIN (PENGIRIM) ---
  void prosesKirimDarurat(String mode) async {
    // Beri feedback GETARAN SAJA untuk pengirim
    if (mode == "ALARM") {
      bool? hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator ?? false) {
        // Getar pola (tunggu 500ms, getar 1000ms, tunggu 500ms, getar 1000ms)
        Vibration.vibrate(pattern: [500, 1000, 500, 1000], repeat: 0);

        // Hentikan getaran otomatis setelah 10 detik
        Future.delayed(Duration(seconds: 10), () {
          Vibration.cancel();
        });
      }
    }

    statusTampilan.value = "Mengirim Bantuan...";

    try {
      Position position = await _determinePosition();
      String lokasi = "${position.latitude}, ${position.longitude}";

      // Ambil User ID dari Firebase Auth
      String myUserId = FirebaseAuth.instance.currentUser?.uid ?? "anonim";

      LaporanDarurat laporan = LaporanDarurat(
        idLaporan: DateTime.now().millisecondsSinceEpoch.toString(),
        pembuatId: myUserId, // <-- SET ID PEMBUAT DI SINI
        tipeKejadian: "SOS",
        statusLaporan: "AKTIF",
        waktu: DateTime.now(),
        lokasiGPS: lokasi,
        modeAlarm: mode,
      );

      // Simpan ke Firestore
      await firestore
          .collection('laporan_darurat')
          .doc(laporan.idLaporan)
          .set(laporan.toJson());

      // Jangan tampilkan dialog peringatan untuk diri sendiri
      // Cukup tampilkan status di UI
      statusTampilan.value = "Bantuan Sedang Dikirim";
      Get.snackbar("DARURAT", "Sinyal SOS Terkirim! Menunggu bantuan...");
    } catch (e) {
      Get.snackbar("Error", "Gagal broadcast: $e");
      statusTampilan.value = "Gagal Kirim";
    }
  }

  // --- FUNGSI 2: TERIMA BROADCAST DARI USER LAIN (PENERIMA) ---
  void listenToBroadcasts() {
    String myUserId = FirebaseAuth.instance.currentUser?.uid ?? "";

    firestore
        .collection('laporan_darurat')
        .where('status_laporan', isEqualTo: 'AKTIF')
        .snapshots()
        .listen((snapshot) {
          for (var change in snapshot.docChanges) {
            // Hanya proses jika ada data BARU ditambahkan
            if (change.type == DocumentChangeType.added) {
              var data = change.doc.data() as Map<String, dynamic>;
              LaporanDarurat laporanBaru = LaporanDarurat.fromJson(data);

              // --- LOGIKA FILTER DISINI ---
              // Jika pembuat laporan adalah SAYA SENDIRI, abaikan/skip
              if (laporanBaru.pembuatId == myUserId) {
                print("Laporan sendiri terdeteksi, abaikan notifikasi.");
                continue;
              }

              // Jika bukan saya, tampilkan peringatan
              tampilkanNotifikasiLayar(laporanBaru);
            }
          }
        });
  }

  void tampilkanNotifikasiLayar(LaporanDarurat laporan) {
    // Mainkan alarm ketika menerima notifikasi darurat
    FlutterRingtonePlayer().playAlarm(
      looping: true,
      asAlarm: true,
      volume: 1.0,
    );

    Get.defaultDialog(
      title: "⚠️ PERINGATAN DARURAT ⚠️",
      titleStyle: TextStyle(
        color: Get.theme.colorScheme.error,
        fontWeight: FontWeight.bold,
      ),
      middleText:
          "Seseorang membutuhkan bantuan!\nLokasi: ${laporan.lokasiGPS}\nWaktu: ${laporan.waktu}",
      textConfirm: "LIHAT PETA",
      textCancel: "ABAIKAN",
      confirmTextColor: Get.theme.colorScheme.onPrimary,
      barrierDismissible: false,
      onConfirm: () {
        FlutterRingtonePlayer().stop();
        Get.back();
        // Arahkan ke Google Maps atau Menu Peta (Fitur Lihat Peta Kejadian)
        // Get.toNamed('/peta', arguments: laporan);
      },
      onCancel: () {
        FlutterRingtonePlayer().stop();
      },
    );
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
