import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sipermas/app/modules/home/controllers/emergency_controller_controller.dart';
import 'package:sipermas/app/modules/home/views/tabs_view.dart';
import '../controllers/home_controller.dart';

class HomeView extends GetView<HomeController> {
  // Inject EmergencyController (Bisa juga via Binding)
  final EmergencyController emergencyC = Get.put(EmergencyController());

  HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // 1. Cek Mode Countdown (Prioritas Tertinggi)
      if (emergencyC.isCountingDown.value) {
        return Scaffold(
          backgroundColor: Colors.black,
          body: _buildCountdownOverlay(),
        );
      }

      // 2. Tampilan Normal dengan Bottom Navigation
      return Scaffold(
        backgroundColor: Colors.grey[50], // Background lebih clean
        body: IndexedStack(
          index: controller.tabIndex.value,
          children: [_buildHomeTab(), PetaTab(), RiwayatTab(), ProfilTab()],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: controller.tabIndex.value,
          onTap: controller.changeTabIndex,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.redAccent,
          unselectedItemColor: Colors.grey,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: 'Beranda',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.map_rounded),
              label: 'Peta',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history_rounded),
              label: 'Riwayat',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              label: 'Profil',
            ),
          ],
        ),
      );
    });
  }

  Widget _buildHomeTab() {
    return SafeArea(
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildStatusCard(),
                    const SizedBox(height: 50),
                    _buildSOSButton(),
                    const SizedBox(height: 30),
                    Text(
                      "Tekan tombol 3 detik untuk bantuan darurat",
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
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
          // Avatar Profile
          Obx(
            () => CircleAvatar(
              radius: 28,
              backgroundColor: Colors.blueAccent.shade100,
              child:
                  controller.userName.value == null ||
                      controller.userName.value!.isEmpty
                  ? const Icon(Icons.person, color: Colors.white, size: 30)
                  : Text(
                      (controller.userName.value?[0] ?? "U").toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Selamat Datang,",
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                // Nama User
                Obx(
                  () => Text(
                    controller.userName.value ?? "User",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          // Tombol Logout
          Container(
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: controller.logout,
              icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
              tooltip: "Logout",
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            "Status Keamanan",
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          const SizedBox(height: 8),
          Obx(
            () => Text(
              emergencyC.statusTampilan.value,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: emergencyC.statusTampilan.value.contains("Siaga")
                    ? Colors.green
                    : Colors.orange,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSOSButton() {
    return GestureDetector(
      onTap: () {
        emergencyC.prosesVerifikasiDarurat();
      },
      child: Container(
        width: 220,
        height: 220,
        decoration: BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.4),
              blurRadius: 30,
              spreadRadius: 10,
            ),
            BoxShadow(
              color: Colors.red.withOpacity(0.2),
              blurRadius: 50,
              spreadRadius: 20,
            ),
          ],
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.red.shade400, Colors.red.shade700],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.warning_amber_rounded, color: Colors.white, size: 50),
            Text(
              "SOS",
              style: TextStyle(
                color: Colors.white,
                fontSize: 48,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountdownOverlay() {
    return Container(
      color: Colors.black,
      width: double.infinity,
      height: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.timer_outlined, color: Colors.redAccent, size: 60),
          const SizedBox(height: 30),
          const Text(
            "Mengirim Sinyal Dalam...",
            style: TextStyle(color: Colors.white70, fontSize: 20),
          ),
          const SizedBox(height: 20),
          Text(
            "${emergencyC.countdownValue.value}",
            style: const TextStyle(
              color: Colors.red,
              fontSize: 100,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 60),
          ElevatedButton.icon(
            onPressed: () {
              emergencyC.tekanTombolBatal();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            icon: const Icon(Icons.close),
            label: const Text(
              "BATALKAN",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
