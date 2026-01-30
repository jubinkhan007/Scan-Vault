import 'package:simplest_document_scanner/simplest_document_scanner.dart';

import '../data/models/processed_file.dart';
import 'scan_storage.dart';

class ScanService {
  ScanService({ScanStorage? storage}) : _storage = storage ?? ScanStorage();

  final ScanStorage _storage;

  Future<ProcessedFile?> scanAndSave({String? originalPdfPath}) async {
    final options = DocumentScannerOptions(
      returnJpegs: true,
      returnPdf: true,
      allowGalleryImport: true,
      maxPages: 24,
      jpegQuality: 0.9,
      android: const AndroidScannerOptions(
        scannerMode: DocumentScannerMode.full,
      ),
      ios: const IosScannerOptions(enforceMaxPageLimit: true),
    );

    final result = await SimplestDocumentScanner.scanDocuments(
      options: options,
    );
    if (result == null) {
      return null;
    }

    final processed = await _storage.saveScan(
      result,
      originalPdfPath: originalPdfPath,
      options: options,
    );
    if (processed.primaryPath.isEmpty) {
      return null;
    }
    return processed;
  }
}
