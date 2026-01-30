import 'dart:convert';

enum ProcessedFileType {
  pdf,
  image,
  unknown,
}

ProcessedFileType processedFileTypeFromInt(int? value) {
  if (value == null) {
    return ProcessedFileType.unknown;
  }
  if (value < 0 || value >= ProcessedFileType.values.length) {
    return ProcessedFileType.unknown;
  }
  return ProcessedFileType.values[value];
}

class ProcessedFile {
  const ProcessedFile({
    required this.id,
    required this.displayName,
    required this.outputPaths,
    required this.primaryPath,
    required this.type,
    required this.createdAt,
    required this.updatedAt,
    required this.isFavorite,
    required this.existsOnDisk,
    this.originalPdfPath,
    this.fileSizeBytes,
    this.lastOpenedAt,
    this.checksumOrFingerprint,
    this.extra,
  });

  final String id;
  final String displayName;
  final String? originalPdfPath;
  final List<String> outputPaths;
  final String primaryPath;
  final ProcessedFileType type;
  final int? fileSizeBytes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isFavorite;
  final DateTime? lastOpenedAt;
  final String? checksumOrFingerprint;
  final bool existsOnDisk;
  final Map<String, dynamic>? extra;

  ProcessedFile copyWith({
    String? id,
    String? displayName,
    String? originalPdfPath,
    List<String>? outputPaths,
    String? primaryPath,
    ProcessedFileType? type,
    int? fileSizeBytes,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isFavorite,
    DateTime? lastOpenedAt,
    String? checksumOrFingerprint,
    bool? existsOnDisk,
    Map<String, dynamic>? extra,
  }) {
    return ProcessedFile(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      originalPdfPath: originalPdfPath ?? this.originalPdfPath,
      outputPaths: outputPaths ?? this.outputPaths,
      primaryPath: primaryPath ?? this.primaryPath,
      type: type ?? this.type,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isFavorite: isFavorite ?? this.isFavorite,
      lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
      checksumOrFingerprint: checksumOrFingerprint ?? this.checksumOrFingerprint,
      existsOnDisk: existsOnDisk ?? this.existsOnDisk,
      extra: extra ?? this.extra,
    );
  }

  Map<String, Object?> toDbMap() {
    return {
      'id': id,
      'display_name': displayName,
      'original_pdf_path': originalPdfPath,
      'output_paths': jsonEncode(outputPaths),
      'primary_path': primaryPath,
      'type': type.index,
      'file_size_bytes': fileSizeBytes,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
      'is_favorite': isFavorite ? 1 : 0,
      'last_opened_at': lastOpenedAt?.millisecondsSinceEpoch,
      'checksum': checksumOrFingerprint,
      'exists_on_disk': existsOnDisk ? 1 : 0,
      'extra': extra == null ? null : jsonEncode(extra),
      'normalized_name': displayName.toLowerCase(),
    };
  }

  static ProcessedFile fromDbMap(Map<String, Object?> map) {
    final outputPathsRaw = map['output_paths'] as String?;
    final extraRaw = map['extra'] as String?;
    return ProcessedFile(
      id: map['id'] as String,
      displayName: map['display_name'] as String,
      originalPdfPath: map['original_pdf_path'] as String?,
      outputPaths: outputPathsRaw == null
          ? const []
          : (jsonDecode(outputPathsRaw) as List<dynamic>)
              .whereType<String>()
              .toList(),
      primaryPath: map['primary_path'] as String,
      type: processedFileTypeFromInt(map['type'] as int?),
      fileSizeBytes: map['file_size_bytes'] as int?,
      createdAt:
          DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt:
          DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
      isFavorite: (map['is_favorite'] as int? ?? 0) == 1,
      lastOpenedAt: map['last_opened_at'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(map['last_opened_at'] as int),
      checksumOrFingerprint: map['checksum'] as String?,
      existsOnDisk: (map['exists_on_disk'] as int? ?? 0) == 1,
      extra: extraRaw == null
          ? null
          : (jsonDecode(extraRaw) as Map<String, dynamic>),
    );
  }
}
