import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:simplest_document_scanner/simplest_document_scanner.dart';
import 'package:uuid/uuid.dart';

import '../data/models/processed_file.dart';

class ScanStorage {
  ScanStorage({Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final Uuid _uuid;

  Future<ProcessedFile> saveScan(
    ScannedDocument document, {
    String? originalPdfPath,
    DocumentScannerOptions? options,
  }) async {
    final now = DateTime.now();
    final directory = await getApplicationDocumentsDirectory();
    final scanDir = Directory(p.join(directory.path, 'scans'));
    if (!await scanDir.exists()) {
      await scanDir.create(recursive: true);
    }

    final token = _uuid.v4();
    final baseName = 'scan_${now.millisecondsSinceEpoch}_$token';

    String? pdfPath;
    if (document.hasPdf && document.pdfBytes != null) {
      final file = File(p.join(scanDir.path, '$baseName.pdf'));
      await file.writeAsBytes(document.pdfBytes!, flush: true);
      pdfPath = file.path;
    }

    final imagePaths = <String>[];
    for (final page in document.pages) {
      final index = page.index + 1;
      final file = File(p.join(scanDir.path, '${baseName}_p$index.jpg'));
      await file.writeAsBytes(page.bytes, flush: true);
      imagePaths.add(file.path);
    }

    final outputPaths = <String>[];
    if (pdfPath != null) {
      outputPaths.add(pdfPath);
    }
    for (final path in imagePaths) {
      if (!outputPaths.contains(path)) {
        outputPaths.add(path);
      }
    }

    final primaryPath =
        pdfPath ?? (imagePaths.isNotEmpty ? imagePaths.first : '');
    final type = pdfPath != null
        ? ProcessedFileType.pdf
        : imagePaths.isNotEmpty
        ? ProcessedFileType.image
        : ProcessedFileType.unknown;

    final fileSize = await _safeFileSize(primaryPath);
    final existsOnDisk = await _safeExists(primaryPath);
    final fallbackName = 'scan_${now.millisecondsSinceEpoch}';

    return ProcessedFile(
      id: token,
      displayName: primaryPath.isNotEmpty
          ? p.basename(primaryPath)
          : fallbackName,
      originalPdfPath: originalPdfPath,
      outputPaths: outputPaths,
      primaryPath: primaryPath,
      type: type,
      fileSizeBytes: fileSize,
      createdAt: now,
      updatedAt: now,
      isFavorite: false,
      lastOpenedAt: null,
      checksumOrFingerprint: null,
      existsOnDisk: existsOnDisk,
      extra: _buildExtra(document, options),
    );
  }

  Map<String, dynamic> _buildExtra(
    ScannedDocument document,
    DocumentScannerOptions? options,
  ) {
    return {
      'scanner': 'simplest_document_scanner',
      'pageCount': document.pages.length,
      'hasPdf': document.hasPdf,
      if (options != null) ...{
        'maxPages': options.maxPages,
        'returnJpegs': options.returnJpegs,
        'returnPdf': options.returnPdf,
        'allowGalleryImport': options.allowGalleryImport,
      },
    };
  }

  Future<int?> _safeFileSize(String path) async {
    if (path.isEmpty) {
      return null;
    }
    try {
      return await File(path).length();
    } catch (_) {
      return null;
    }
  }

  Future<bool> _safeExists(String path) async {
    if (path.isEmpty) {
      return false;
    }
    try {
      return await File(path).exists();
    } catch (_) {
      return false;
    }
  }
}
