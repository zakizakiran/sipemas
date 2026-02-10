import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sipermas/app/modules/home/controllers/emergency_controller_controller.dart';
import '../controllers/home_controller.dart';

class HomeView extends GetView<HomeController> {
  // Inject EmergencyController (Bisa juga via Binding)
  final EmergencyController emergencyC = Get.put(EmergencyController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('SIPERMAS - Home'), centerTitle: true),
      body: Center(
        child: Obx(() {
          // Visualisasi Timer / Countdown Overlay
          if (emergencyC.isCountingDown.value) {
            return _buildCountdownOverlay();
          }

          // Tampilan Normal (Tombol SOS Besar)
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                emergencyC.statusTampilan.value,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 50),

              // Tombol Darurat (Panic Button)
              GestureDetector(
                onTap: () {
                  // Trigger Sequence 1: tekanTombolDarurat -> prosesVerifikasi
                  emergencyC.prosesVerifikasiDarurat();
                },
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.5),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      "SOS",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Text(
                "Tekan tombol untuk bantuan darurat",
                style: TextStyle(color: Colors.grey),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildCountdownOverlay() {
    return Container(
      color: Colors.black87,
      width: double.infinity,
      height: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Mengirim Sinyal Dalam...",
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
          SizedBox(height: 20),
          Text(
            "${emergencyC.countdownValue.value}",
            style: TextStyle(
              color: Colors.red,
              fontSize: 80,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 50),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
            ),
            onPressed: () {
              // Trigger Sequence 6: tekanTombolBatal
              emergencyC.tekanTombolBatal();
            },
            child: Text(
              "BATALKAN",
              style: TextStyle(color: Colors.red, fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }
}
