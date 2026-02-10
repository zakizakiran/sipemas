import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../routes/app_pages.dart';

class HomeController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final userName = Rx<String?>('');
  final userEmail = Rx<String?>('');

  var tabIndex = 0.obs;

  @override
  void onInit() {
    super.onInit();
    loadUserData();
  }

  void changeTabIndex(int index) {
    tabIndex.value = index;
  }

  void loadUserData() {
    final user = _auth.currentUser;
    userName.value = user?.displayName ?? 'User';
    userEmail.value = user?.email ?? '';
  }

  Future<void> logout() async {
    try {
      await _auth.signOut();
      Get.snackbar(
        'Sukses',
        'Logout berhasil',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      Get.offAllNamed(Routes.LOGIN);
    } catch (e) {
      Get.snackbar(
        'Error',
        'Gagal logout: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}
