import 'package:get/get.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import '../../../data/models/laporan_darurat.dart';

import 'reward_controller.dart';

class MapsController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // Inject RewardController
  final RewardController rewardController = Get.put(RewardController());

  // Controller peta dari flutter_map
  final MapController mapController = MapController();

  // Marker di flutter_map adalah Widget, jadi kita simpan dalam List<Marker>
  var markers = <Marker>[].obs;

  // Lokasi User Saat Ini
  var currentLocation = Rx<LatLng?>(null);

  // --- TAMBAHAN 1: VARIABEL FILTER ---
  var filterKategori =
      "SEMUA".obs; // Pilihan: SEMUA, SOS, KEBAKARAN, KRIMINAL, MEDIS
  var filterJarakKm = 10.0.obs; // Default radius 10 KM

  // Simpan semua data mentah dari Firebase sebelum difilter
  List<LaporanDarurat> _allLaporanCached = [];

  // Lokasi awal (Default UNIKOM jika GPS belum dapat)
  final LatLng initialPosition = LatLng(-6.886864, 107.615254);

  @override
  void onInit() {
    super.onInit();
    _getCurrentLocation();
    listenToLaporanAktif();
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition();
        LatLng myPos = LatLng(position.latitude, position.longitude);
        currentLocation.value = myPos;

        mapController.move(myPos, 15.0);

        terapkanFilter();
      }
    } catch (e) {
      print("Gagal ambil lokasi: $e");
    }
  }

  void centerOnMe() {
    if (currentLocation.value != null) {
      mapController.move(currentLocation.value!, 16.0);
    } else {
      _getCurrentLocation();
    }
  }

  void listenToLaporanAktif() {
    _firestore
        .collection('laporan_darurat')
        .where('status_laporan', isEqualTo: 'AKTIF')
        .snapshots()
        .listen((snapshot) {
          _allLaporanCached = snapshot.docs.map((doc) {
            return LaporanDarurat.fromJson(doc.data());
          }).toList();

          terapkanFilter();
        });
  }

  void terapkanFilter() {
    List<Marker> newMarkers = [];
    LatLng? myPos = currentLocation.value;

    for (var laporan in _allLaporanCached) {
      // Parse Lokasi Laporan
      List<String> latlong = laporan.lokasiGPS.split(',');
      double lat = double.parse(latlong[0].trim());
      double lng = double.parse(latlong[1].trim());

      // FILTER 1: Kategori
      if (filterKategori.value != "SEMUA" &&
          laporan.tipeKejadian != filterKategori.value) {
        continue; // Skip jika kategori tidak cocok
      }

      // FILTER 2: Jarak (Jika lokasi saya tersedia)
      if (myPos != null) {
        double distMeters = Geolocator.distanceBetween(
          myPos.latitude,
          myPos.longitude,
          lat,
          lng,
        );
        double distKm = distMeters / 1000;

        if (distKm > filterJarakKm.value) {
          continue; // Skip jika di luar radius filter
        }
      }

      // Jika lolos filter, buat Marker
      newMarkers.add(
        Marker(
          point: LatLng(lat, lng),
          width: 80,
          height: 80,
          child: GestureDetector(
            onTap: () {
              // Tampilkan Modal/Dialog saat marker diklik
              tampilkanInfoMarker(laporan, lat, lng);
            },
            child: Column(
              children: [
                Icon(
                  Icons.location_on,
                  color: _getColorByTipe(laporan.tipeKejadian),
                  size: 40,
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [BoxShadow(blurRadius: 2)],
                  ),
                  child: Text(
                    laporan.tipeKejadian,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    markers.value = newMarkers;
  }

  // Helper warna marker
  Color _getColorByTipe(String tipe) {
    switch (tipe) {
      case 'KEBAKARAN':
        return Colors.orange;
      case 'MEDIS':
        return Colors.green;
      case 'KRIMINAL':
        return Colors.blueGrey;
      default:
        return Colors.red;
    }
  }

  // --- FUNGSI BARU: LAPOR HOAKS (Sesuai Dokumen Hal 19) ---
  void laporHoaks(String idLaporan) {
    Get.defaultDialog(
      title: "Lapor Hoaks?",
      middleText: "Apakah Anda yakin laporan ini palsu/tidak benar?",
      textConfirm: "Ya, Lapor",
      textCancel: "Batal",
      confirmTextColor: Colors.white, // Text color for default button
      buttonColor: Colors.red, // Button color for default button
      onConfirm: () async {
        Get.back(); // Tutup dialog konfirmasi
        Get.back(); // Tutup dialog marker

        try {
          // Tambahkan flag/counter report pada dokumen laporan
          await _firestore.collection('laporan_darurat').doc(idLaporan).update({
            'jumlah_laporan_palsu': FieldValue.increment(1),
            // Opsional: Jika laporan palsu > 5, otomatis set status DIBATALKAN
          });

          Get.snackbar(
            "Laporan Diterima",
            "Terima kasih telah menjaga komunitas aman.",
          );
        } catch (e) {
          Get.snackbar("Error", "Gagal melapor: $e");
        }
      },
    );
  }

  void tampilkanInfoMarker(LaporanDarurat laporan, double lat, double lng) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon Marker
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  color: Colors.redAccent,
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Text(
                laporan.tipeKejadian.toUpperCase(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // Content
              Text(
                "Waktu: ${laporan.waktu}\nStatus: ${laporan.statusLaporan}",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),

              // Action 1: Verifikasi / Klaim Poin
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    // Trigger Use Case Reward & Komunitas
                    rewardController.verifikasiKehadiranDanKlaimPoin(laporan);
                  },
                  icon: const Icon(
                    Icons.verified_user_rounded,
                    color: Colors.white,
                  ),
                  label: const Text(
                    "SAYA DI LOKASI (KLAIM POIN)",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Action 2: Navigasi
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  onPressed: () {
                    Get.back();
                    bukaGoogleMapsNavigasi(lat, lng);
                  },
                  icon: Icon(Icons.navigation_rounded, color: Colors.grey[700]),
                  label: Text(
                    "NAVIGASI GOOGLE MAPS",
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // --- TAMBAHAN: TOMBOL FLAG/HOAKS ---
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () {
                    // Panggil fungsi lapor hoaks
                    laporHoaks(laporan.idLaporan);
                  },
                  icon: const Icon(Icons.flag_rounded),
                  label: const Text("LAPORKAN PALSU (HOAKS)"),
                ),
              ),

              // Action 3: Tutup
              TextButton(
                onPressed: () => Get.back(),
                child: Text("Tutup", style: TextStyle(color: Colors.grey[500])),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> bukaGoogleMapsNavigasi(double lat, double lng) async {
    final Uri googleMapsUrl = Uri.parse("google.navigation:q=$lat,$lng&mode=d");
    if (!await launchUrl(googleMapsUrl)) {
      Get.snackbar("Error", "Tidak bisa membuka aplikasi peta");
    }
  }
}
