import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'data/repositories/processed_file_repository.dart';
import 'data/repositories/sqflite_processed_file_repository.dart';
import 'data/sources/processed_file_database.dart';
import 'presentation/controllers/history_controller.dart';
import 'presentation/screens/history_screen.dart';
import 'services/scan_service.dart';
import 'services/scan_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final database = await ProcessedFileDatabase.open();
  Get.put<ProcessedFileRepository>(
    SqfliteProcessedFileRepository(database),
    permanent: true,
  );
  Get.put<ScanService>(
    ScanService(storage: ScanStorage()),
    permanent: true,
  );
  Get.lazyPut<HistoryController>(
    () => HistoryController(
      repository: Get.find<ProcessedFileRepository>(),
      scanService: Get.find<ScanService>(),
    ),
    fenix: true,
  );

  runApp(const ScanVaultApp());
}

class ScanVaultApp extends StatelessWidget {
  const ScanVaultApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Scan Vault',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      home: const HistoryScreen(),
    );
  }
}
