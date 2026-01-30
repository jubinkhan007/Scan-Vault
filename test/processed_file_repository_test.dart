import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:scan_vault/data/models/processed_file.dart';
import 'package:scan_vault/data/repositories/sqflite_processed_file_repository.dart';
import 'package:scan_vault/data/sources/processed_file_database.dart';

void main() {
  late Database db;
  late SqfliteProcessedFileRepository repository;
  late Directory tempDir;

  setUpAll(() {
    sqfliteFfiInit();
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('scan_vault_test');
    db = await ProcessedFileDatabase.openWithPath(
      p.join(tempDir.path, 'test.db'),
      factory: databaseFactoryFfi,
    );
    repository = SqfliteProcessedFileRepository(db);
  });

  tearDown(() async {
    await db.close();
    await tempDir.delete(recursive: true);
  });

  test('upsert prevents duplicates', () async {
    final file = File(p.join(tempDir.path, 'sample.pdf'));
    await file.writeAsBytes(List<int>.filled(12, 1));
    final now = DateTime.now();
    final first = ProcessedFile(
      id: 'file-1',
      displayName: 'sample.pdf',
      originalPdfPath: null,
      outputPaths: [file.path],
      primaryPath: file.path,
      type: ProcessedFileType.pdf,
      fileSizeBytes: null,
      createdAt: now,
      updatedAt: now,
      isFavorite: false,
      lastOpenedAt: null,
      checksumOrFingerprint: null,
      existsOnDisk: true,
      extra: null,
    );

    await repository.upsertProcessedFile(first);

    final second = first.copyWith(
      id: 'file-2',
      outputPaths: [file.path, 'extra.jpg'],
    );
    await repository.upsertProcessedFile(second);

    final items = await repository.getFiles();
    expect(items.length, 1);
    expect(items.first.outputPaths.toSet().length, 2);
  });

  test('toggle favorite persists', () async {
    final file = File(p.join(tempDir.path, 'favorite.pdf'));
    await file.writeAsBytes(List<int>.filled(8, 2));
    final now = DateTime.now();
    final item = ProcessedFile(
      id: 'fav-1',
      displayName: 'favorite.pdf',
      originalPdfPath: null,
      outputPaths: [file.path],
      primaryPath: file.path,
      type: ProcessedFileType.pdf,
      fileSizeBytes: null,
      createdAt: now,
      updatedAt: now,
      isFavorite: false,
      lastOpenedAt: null,
      checksumOrFingerprint: null,
      existsOnDisk: true,
      extra: null,
    );

    await repository.upsertProcessedFile(item);
    await repository.toggleFavorite(item.id, true);

    final stored = await repository.getById(item.id);
    expect(stored?.isFavorite, true);
  });

  test('deleteFromHistory removes item', () async {
    final file = File(p.join(tempDir.path, 'delete.pdf'));
    await file.writeAsBytes(List<int>.filled(4, 3));
    final now = DateTime.now();
    final item = ProcessedFile(
      id: 'delete-1',
      displayName: 'delete.pdf',
      originalPdfPath: null,
      outputPaths: [file.path],
      primaryPath: file.path,
      type: ProcessedFileType.pdf,
      fileSizeBytes: null,
      createdAt: now,
      updatedAt: now,
      isFavorite: false,
      lastOpenedAt: null,
      checksumOrFingerprint: null,
      existsOnDisk: true,
      extra: null,
    );

    await repository.upsertProcessedFile(item);
    await repository.deleteFromHistory(item.id);

    final stored = await repository.getById(item.id);
    expect(stored, isNull);
  });

  test('missing file detection does not throw', () async {
    final now = DateTime.now();
    final missingPath = p.join(tempDir.path, 'missing.pdf');
    final item = ProcessedFile(
      id: 'missing-1',
      displayName: 'missing.pdf',
      originalPdfPath: null,
      outputPaths: [missingPath],
      primaryPath: missingPath,
      type: ProcessedFileType.pdf,
      fileSizeBytes: null,
      createdAt: now,
      updatedAt: now,
      isFavorite: false,
      lastOpenedAt: null,
      checksumOrFingerprint: null,
      existsOnDisk: true,
      extra: null,
    );

    await repository.upsertProcessedFile(item);
    await repository.refreshExistenceStatus(batchSize: 10);

    final stored = await repository.getById(item.id);
    expect(stored?.existsOnDisk, false);
  });
}
