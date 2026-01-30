import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/processed_file.dart';
import '../sources/processed_file_database.dart';
import 'processed_file_repository.dart';

class ProcessedFileDeleteException implements Exception {
  ProcessedFileDeleteException(this.failedPaths);

  final List<String> failedPaths;

  @override
  String toString() =>
      'ProcessedFileDeleteException(failedPaths: $failedPaths)';
}

class SqfliteProcessedFileRepository implements ProcessedFileRepository {
  SqfliteProcessedFileRepository(this._db);

  final Database _db;

  @override
  Future<void> upsertProcessedFile(ProcessedFile item) async {
    final normalizedPrimaryPath = _normalizePath(item.primaryPath);
    final fileMeta = await _buildFileMeta(normalizedPrimaryPath);
    final displayName = item.displayName.isNotEmpty
        ? item.displayName
        : p.basename(normalizedPrimaryPath);
    final detectedType = item.type == ProcessedFileType.unknown
        ? _detectTypeFromPath(normalizedPrimaryPath)
        : item.type;
    final now = DateTime.now();

    final existing = await _findDuplicate(
      normalizedPrimaryPath,
      fileMeta.fingerprint,
    );

    if (existing != null) {
      final mergedOutputs = <String>{
        ...existing.outputPaths,
        ...item.outputPaths,
      };
      final merged = existing.copyWith(
        displayName: displayName,
        originalPdfPath: item.originalPdfPath ?? existing.originalPdfPath,
        outputPaths: mergedOutputs.toList(),
        primaryPath: normalizedPrimaryPath,
        type: detectedType == ProcessedFileType.unknown
            ? existing.type
            : detectedType,
        fileSizeBytes: item.fileSizeBytes ?? fileMeta.size ?? existing.fileSizeBytes,
        updatedAt: now,
        lastOpenedAt: item.lastOpenedAt ?? existing.lastOpenedAt,
        checksumOrFingerprint: item.checksumOrFingerprint ?? fileMeta.fingerprint,
        existsOnDisk: fileMeta.exists ?? existing.existsOnDisk,
        extra: _mergeExtra(existing.extra, item.extra),
      );
      await _db.update(
        ProcessedFileDatabase.tableName,
        merged.toDbMap(),
        where: 'id = ?',
        whereArgs: [existing.id],
      );
      return;
    }

    final fresh = item.copyWith(
      displayName: displayName,
      primaryPath: normalizedPrimaryPath,
      type: detectedType,
      fileSizeBytes: item.fileSizeBytes ?? fileMeta.size,
      createdAt: item.createdAt,
      updatedAt: now,
      checksumOrFingerprint: item.checksumOrFingerprint ?? fileMeta.fingerprint,
      existsOnDisk: fileMeta.exists ?? item.existsOnDisk,
    );

    await _db.insert(
      ProcessedFileDatabase.tableName,
      fresh.toDbMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<List<ProcessedFile>> getFiles({
    String? query,
    bool favoritesOnly = false,
    int limit = 30,
    int offset = 0,
  }) async {
    final whereParts = <String>[];
    final whereArgs = <Object?>[];

    final normalizedQuery = query?.trim().toLowerCase();
    if (normalizedQuery != null && normalizedQuery.isNotEmpty) {
      whereParts.add('normalized_name LIKE ?');
      whereArgs.add('%$normalizedQuery%');
    }
    if (favoritesOnly) {
      whereParts.add('is_favorite = 1');
    }

    final rows = await _db.query(
      ProcessedFileDatabase.tableName,
      where: whereParts.isEmpty ? null : whereParts.join(' AND '),
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'created_at DESC',
      limit: limit,
      offset: offset,
    );

    return rows.map(ProcessedFile.fromDbMap).toList();
  }

  @override
  Future<ProcessedFile?> getById(String id) async {
    final rows = await _db.query(
      ProcessedFileDatabase.tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return ProcessedFile.fromDbMap(rows.first);
  }

  @override
  Future<void> toggleFavorite(String id, bool isFavorite) async {
    await _db.update(
      ProcessedFileDatabase.tableName,
      {
        'is_favorite': isFavorite ? 1 : 0,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> deleteFromHistory(String id) async {
    await _db.delete(
      ProcessedFileDatabase.tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> deleteFromDiskAndHistory(String id) async {
    final item = await getById(id);
    if (item == null) {
      return;
    }
    final failedPaths = <String>[];
    final allPaths = <String>{item.primaryPath, ...item.outputPaths}
        .where((path) => path.isNotEmpty)
        .toList();

    for (final path in allPaths) {
      try {
        final file = File(path);
        final exists = await file.exists();
        if (exists) {
          await file.delete();
        }
      } catch (_) {
        failedPaths.add(path);
      }
    }

    await deleteFromHistory(id);

    if (failedPaths.isNotEmpty) {
      throw ProcessedFileDeleteException(failedPaths);
    }
  }

  @override
  Future<void> refreshExistenceStatus({int batchSize = 50}) async {
    var offset = 0;
    while (true) {
      final rows = await _db.query(
        ProcessedFileDatabase.tableName,
        columns: ['id', 'primary_path', 'exists_on_disk'],
        limit: batchSize,
        offset: offset,
      );
      if (rows.isEmpty) {
        break;
      }
      for (final row in rows) {
        final id = row['id'] as String;
        final primaryPath = row['primary_path'] as String;
        final currentExists = (row['exists_on_disk'] as int? ?? 0) == 1;
        final exists = await _safeExists(primaryPath);
        if (exists != currentExists) {
          await _db.update(
            ProcessedFileDatabase.tableName,
            {
              'exists_on_disk': exists ? 1 : 0,
              'updated_at': DateTime.now().millisecondsSinceEpoch,
            },
            where: 'id = ?',
            whereArgs: [id],
          );
        }
      }
      offset += rows.length;
    }
  }

  Future<ProcessedFile?> _findDuplicate(
    String normalizedPrimaryPath,
    String? fingerprint,
  ) async {
    final where = <String>['primary_path = ?'];
    final args = <Object?>[normalizedPrimaryPath];
    if (fingerprint != null && fingerprint.isNotEmpty) {
      where.add('checksum = ?');
      args.add(fingerprint);
    }

    final rows = await _db.query(
      ProcessedFileDatabase.tableName,
      where: where.join(' OR '),
      whereArgs: args,
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return ProcessedFile.fromDbMap(rows.first);
  }

  Future<_FileMeta> _buildFileMeta(String primaryPath) async {
    try {
      final stat = await FileStat.stat(primaryPath);
      if (stat.type == FileSystemEntityType.notFound) {
        return const _FileMeta(exists: false);
      }
      final fingerprint =
          '$primaryPath|${stat.size}|${stat.modified.millisecondsSinceEpoch}';
      return _FileMeta(
        exists: true,
        size: stat.size,
        fingerprint: fingerprint,
      );
    } catch (_) {
      return const _FileMeta(exists: false);
    }
  }

  String _normalizePath(String path) {
    final absolute = File(path).absolute.path;
    return p.normalize(absolute);
  }

  ProcessedFileType _detectTypeFromPath(String path) {
    final extension = p.extension(path).toLowerCase();
    switch (extension) {
      case '.pdf':
        return ProcessedFileType.pdf;
      case '.png':
      case '.jpg':
      case '.jpeg':
      case '.heic':
      case '.webp':
        return ProcessedFileType.image;
      default:
        return ProcessedFileType.unknown;
    }
  }

  Future<bool> _safeExists(String path) async {
    try {
      return await File(path).exists();
    } catch (_) {
      return false;
    }
  }

  Map<String, dynamic>? _mergeExtra(
    Map<String, dynamic>? existing,
    Map<String, dynamic>? incoming,
  ) {
    if (existing == null && incoming == null) {
      return null;
    }
    return {
      ...?existing,
      ...?incoming,
    };
  }
}

class _FileMeta {
  const _FileMeta({this.exists, this.size, this.fingerprint});

  final bool? exists;
  final int? size;
  final String? fingerprint;
}
