import 'package:get/get.dart';

import 'package:sipermas/app/modules/home/controllers/emergency_controller.dart';
import 'package:sipermas/app/modules/home/controllers/history_controller_controller.dart';
import 'package:sipermas/app/modules/home/controllers/map_controller_controller.dart';

import '../controllers/home_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HistoryController>(() => HistoryController());
    Get.lazyPut<MapsController>(() => MapsController());
    Get.lazyPut<EmergencyController>(() => EmergencyController());
    Get.lazyPut<HomeController>(() => HomeController());
  }
}
