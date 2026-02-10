import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../login/views/login_view.dart';

class ProfileController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  var nama = "".obs;
  var email = "".obs;
  var totalPoin = 0.obs;
  var isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    loadUserProfile();
  }

  Future<void> loadUserProfile() async {
    User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      email.value = currentUser.email ?? "";

      try {
        // Ambil data detail dari koleksi 'users' (Pastikan saat register data ini dibuat)
        DocumentSnapshot userDoc = await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .get();

        if (userDoc.exists) {
          var data = userDoc.data() as Map<String, dynamic>;
          nama.value = data['nama'] ?? "Pengguna Sipermas";
          totalPoin.value = data['total_poin'] ?? 0;
        } else {
          // Fallback jika dokumen user belum ada
          nama.value = currentUser.displayName ?? "Pengguna Sipermas";
        }
      } catch (e) {
        print("Gagal ambil profil: $e");
      } finally {
        isLoading.value = false;
      }
    }
  }

  void logout() async {
    await _auth.signOut();
    Get.offAll(() => const LoginView());
  }
}
