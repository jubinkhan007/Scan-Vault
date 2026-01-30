import 'package:intl/intl.dart';

import '../../data/models/processed_file.dart';

class ProcessedFileFormatters {
  static final DateFormat _dateFormat = DateFormat('yMMMd • HH:mm');

  static String formatBytes(int? bytes) {
    if (bytes == null || bytes <= 0) {
      return 'Unknown size';
    }
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    double value = bytes.toDouble();
    var unitIndex = 0;
    while (value >= 1024 && unitIndex < units.length - 1) {
      value /= 1024;
      unitIndex++;
    }
    final decimals = value >= 10 || unitIndex == 0 ? 0 : 1;
    return '${value.toStringAsFixed(decimals)} ${units[unitIndex]}';
  }

  static String formatDate(DateTime? dateTime) {
    if (dateTime == null) {
      return '—';
    }
    return _dateFormat.format(dateTime);
  }

  static String formatType(ProcessedFileType type) {
    switch (type) {
      case ProcessedFileType.pdf:
        return 'PDF';
      case ProcessedFileType.image:
        return 'Image';
      case ProcessedFileType.unknown:
        return 'Unknown';
    }
  }
}
