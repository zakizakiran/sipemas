import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LeaderboardController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // List user dengan poin tertinggi
  var topUsers = <Map<String, dynamic>>[].obs;
  var isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    fetchLeaderboard();
  }

  void fetchLeaderboard() {
    isLoading.value = true;

    // Listen realtime updates
    _firestore
        .collection('users')
        .orderBy('total_poin', descending: true)
        .limit(20) // Menampilkan top 20
        .snapshots()
        .listen(
          (snapshot) {
            topUsers.value = snapshot.docs.map((doc) {
              var data = doc.data();
              // Tambahkan ID dokumen jika perlu referensi balik
              // data['id'] = doc.id;
              return data;
            }).toList();

            isLoading.value = false;
          },
          onError: (error) {
            print("Error fetching leaderboard: $error");
            isLoading.value = false;
          },
        );
  }
}
