import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_map/flutter_map.dart'; // Import flutter_map
import 'package:intl/intl.dart';
import 'package:sipermas/app/modules/home/controllers/map_controller_controller.dart';
import 'package:sipermas/app/modules/home/controllers/history_controller_controller.dart';
import 'package:sipermas/app/modules/home/controllers/profile_controller.dart';
import '../../../data/models/laporan_darurat.dart';

class PetaTab extends StatelessWidget {
  final MapsController controller = Get.put(MapsController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. PETA (Layer Bawah)
          Obx(
            () => FlutterMap(
              mapController: controller.mapController,
              options: MapOptions(
                initialCenter: controller.initialPosition, // Lokasi Awal
                initialZoom: 15.0,
              ),
              children: [
                // Layer Tile
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.sipermas.app',
                ),

                // Layer Marker
                MarkerLayer(markers: controller.markers.value),

                // Layer Lokasi Saya (Blue Dot)
                if (controller.currentLocation.value != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: controller.currentLocation.value!,
                        width: 60,
                        height: 60,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.2),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.blue, width: 2),
                          ),
                          child: Center(
                            child: Container(
                              width: 15,
                              height: 15,
                              decoration: BoxDecoration(
                                color: Colors.blueAccent,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                RichAttributionWidget(
                  attributions: [
                    TextSourceAttribution(
                      'OpenStreetMap contributors',
                      onTap: () {},
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 2. FILTER BAR (Layer Atas) - Digunakan untuk memfilter kategori dan jarak
          Positioned(
            top: 50, // Di bawah status bar
            left: 20,
            right: 20,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // Filter Kategori (Dropdown)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Obx(
                      () => DropdownButton<String>(
                        value: controller.filterKategori.value,
                        underline: const SizedBox(),
                        icon: const Icon(Icons.keyboard_arrow_down_rounded),
                        style: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        items:
                            [
                              "SEMUA",
                              "SOS",
                              "KEBAKARAN",
                              "KRIMINAL",
                              "MEDIS",
                            ].map((String val) {
                              return DropdownMenuItem(
                                value: val,
                                child: Text(val),
                              );
                            }).toList(),
                        onChanged: (newVal) {
                          if (newVal != null) {
                            controller.filterKategori.value = newVal;
                            controller.terapkanFilter(); // Refresh marker
                          }
                        },
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  // Filter Jarak (Dropdown)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.radar_rounded,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 8),
                        Obx(
                          () => DropdownButton<double>(
                            value: controller.filterJarakKm.value,
                            underline: const SizedBox(),
                            icon: const Icon(Icons.keyboard_arrow_down_rounded),
                            style: const TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            items: [1.0, 5.0, 10.0, 25.0, 50.0].map((
                              double val,
                            ) {
                              return DropdownMenuItem(
                                value: val,
                                child: Text("${val.toInt()} KM"),
                              );
                            }).toList(),
                            onChanged: (newVal) {
                              if (newVal != null) {
                                controller.filterJarakKm.value = newVal;
                                controller.terapkanFilter(); // Refresh marker
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Tombol Center Location
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              onPressed: controller.centerOnMe,
              backgroundColor: Colors.white,
              child: Icon(Icons.my_location, color: Colors.blue),
            ),
          ),

          // HAPUS Panel Info Lama karena tertutup filter
        ],
      ),
    );
  }
}

// Tab 3: Riwayat
class RiwayatTab extends StatelessWidget {
  const RiwayatTab({super.key});

  @override
  Widget build(BuildContext context) {
    // Inject Controller
    final HistoryController controller = Get.put(HistoryController());

    return Scaffold(
      backgroundColor: Colors.grey[50], // Background
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(25),
                  bottomRight: Radius.circular(25),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orangeAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.history_rounded,
                      color: Colors.orangeAccent,
                    ),
                  ),
                  const SizedBox(width: 15),
                  const Text(
                    "Riwayat Laporan",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (controller.riwayatList.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.history_edu_outlined,
                          size: 80,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Belum ada riwayat laporan",
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // List Riwayat
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: controller.riwayatList.length,
                  itemBuilder: (context, index) {
                    var laporan = controller.riwayatList[index];
                    return _buildHistoryCard(laporan, controller);
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(
    LaporanDarurat laporan,
    HistoryController controller,
  ) {
    // Tentukan Warna Status
    Color statusColor = Colors.grey;
    IconData statusIcon = Icons.info_outline;

    switch (laporan.statusLaporan) {
      case 'AKTIF':
        statusColor = Colors.redAccent;
        statusIcon = Icons.warning_amber_rounded;
        break;
      case 'SELESAI':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle_outline;
        break;
      case 'DIBATALKAN':
        statusColor = Colors.orange;
        statusIcon = Icons.cancel_outlined;
        break;
    }

    // Tentukan Icon & Warna Berdasar Tipe Kejadian
    IconData categoryIcon;
    Color categoryColor;

    switch (laporan.tipeKejadian) {
      case 'KEBAKARAN':
        categoryIcon = Icons.local_fire_department_rounded;
        categoryColor = Colors.orange;
        break;
      case 'KRIMINAL':
        categoryIcon = Icons.local_police_rounded;
        categoryColor = Colors.blueGrey;
        break;
      case 'MEDIS':
        categoryIcon = Icons.medical_services_rounded;
        categoryColor = Colors.green;
        break;
      default:
        categoryIcon = Icons.warning_amber_rounded;
        categoryColor = Colors.redAccent;
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
        ),
        child: Column(
          children: [
            // Header Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.05),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(statusIcon, color: statusColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    laporan.statusLaporan,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    DateFormat('dd MMM HH:mm').format(laporan.waktu),
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: categoryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          categoryIcon,
                          color: categoryColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            laporan.tipeKejadian,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "Lokasi: ${laporan.lokasiGPS}",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Tombol Aksi jika masih AKTIF
                  if (laporan.statusLaporan == 'AKTIF') ...[
                    const Divider(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: BorderSide(
                                color: Colors.redAccent.shade100,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () {
                              controller.batalkanLaporan(laporan.idLaporan);
                            },
                            child: const Text(
                              "Batalkan",
                              style: TextStyle(
                                color: Colors.redAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () {
                              controller.selesaikanLaporan(laporan.idLaporan);
                            },
                            child: const Text(
                              "Selesai & Nilai",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Tab 4: Profil
class ProfilTab extends StatelessWidget {
  final ProfileController controller = Get.put(ProfileController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            // Header Custom
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(25),
                  bottomRight: Radius.circular(25),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.purpleAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      color: Colors.purpleAccent,
                    ),
                  ),
                  const SizedBox(width: 15),
                  const Text(
                    "Profil Saya",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }

                return RefreshIndicator(
                  onRefresh: controller.loadUserProfile,
                  color: Colors.purpleAccent,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const SizedBox(height: 10),
                        // Avatar
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.white,
                            child: CircleAvatar(
                              radius: 55,
                              backgroundColor: Colors.purpleAccent.shade100,
                              child: const Icon(
                                Icons.person,
                                size: 60,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          controller.nama.value,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          controller.email.value,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 30),

                        // Card Poin
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.orange.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                            border: Border.all(
                              color: Colors.orange.withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.stars_rounded,
                                  color: Colors.orange,
                                  size: 32,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Total Poin Penolong",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    "${controller.totalPoin.value} pts",
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange[800],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 40),

                        // Logout Button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: controller.logout,
                            icon: const Icon(Icons.logout_rounded),
                            label: const Text(
                              "Keluar Akun",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
