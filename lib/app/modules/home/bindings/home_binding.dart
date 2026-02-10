import 'package:get/get.dart';

import 'package:sipermas/app/modules/home/controllers/emergency_controller_controller.dart';

import '../controllers/home_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<EmergencyController>(() => EmergencyController());
    Get.lazyPut<HomeController>(() => HomeController());
  }
}
