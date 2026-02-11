import 'package:hive_flutter/hive_flutter.dart';

class HiveService {
  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox('walletBox');
    await Hive.openBox('database');
  }

  static Box getWalletBox() => Hive.box('walletBox');
  static Box getDatabaseBox() => Hive.box('database');
}

