import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/models/processed_file.dart';
import '../controllers/history_controller.dart';
import '../utils/formatters.dart';

class FileDetailsView extends StatefulWidget {
  const FileDetailsView({super.key, required this.item});

  final ProcessedFile item;

  @override
  State<FileDetailsView> createState() => _FileDetailsViewState();
}

class _FileDetailsViewState extends State<FileDetailsView> {
  late Future<_FileInfo> _infoFuture;

  @override
  void initState() {
    super.initState();
    _infoFuture = _loadInfo();
  }

  Future<_FileInfo> _loadInfo() async {
    try {
      final stat = await FileStat.stat(widget.item.primaryPath);
      final exists = stat.type != FileSystemEntityType.notFound;
      return _FileInfo(
        exists: exists,
        modified: stat.modified,
        changed: stat.changed,
        size: stat.size,
      );
    } catch (_) {
      return const _FileInfo(exists: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HistoryController>();
    final item = widget.item;

    return Scaffold(
      appBar: AppBar(
        title: const Text('File Details'),
      ),
      body: FutureBuilder<_FileInfo>(
        future: _infoFuture,
        builder: (context, snapshot) {
          final info = snapshot.data ?? const _FileInfo(exists: false);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                item.displayName,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              _detailTile('Full path', item.primaryPath, selectable: true),
              if (item.originalPdfPath != null)
                _detailTile(
                  'Original PDF',
                  item.originalPdfPath!,
                  selectable: true,
                ),
              _detailTile(
                'Type',
                ProcessedFileFormatters.formatType(item.type),
              ),
              _detailTile(
                'Size',
                ProcessedFileFormatters.formatBytes(
                  item.fileSizeBytes ?? info.size,
                ),
              ),
              _detailTile(
                'History added',
                ProcessedFileFormatters.formatDate(item.createdAt),
              ),
              _detailTile(
                'History updated',
                ProcessedFileFormatters.formatDate(item.updatedAt),
              ),
              _detailTile(
                'Last opened',
                ProcessedFileFormatters.formatDate(item.lastOpenedAt),
              ),
              _detailTile(
                'File modified',
                ProcessedFileFormatters.formatDate(info.modified),
              ),
              _detailTile(
                'File changed',
                ProcessedFileFormatters.formatDate(info.changed),
              ),
              _detailTile('Outputs', '${item.outputPaths.length} file(s)'),
              _detailTile(
                'Exists on disk',
                (info.exists && item.existsOnDisk) ? 'Yes' : 'Missing',
              ),
              if (item.extra != null && item.extra!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Scanner metadata',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                ...item.extra!.entries.map(
                  (entry) => _detailTile(
                    entry.key,
                    entry.value.toString(),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: item.existsOnDisk ? () => controller.openFile(item) : null,
                icon: const Icon(Icons.open_in_new),
                label: const Text('Open file'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () async {
                  await controller.deleteFromDiskAndHistory(item);
                  if (mounted) {
                    Get.back();
                  }
                },
                icon: const Icon(Icons.delete),
                label: const Text('Delete file'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () async {
                  await controller.deleteFromHistory(item);
                  if (mounted) {
                    Get.back();
                  }
                },
                child: const Text('Remove from history'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _detailTile(String label, String value, {bool selectable = false}) {
    final content = selectable
        ? SelectableText(value)
        : Text(value, maxLines: 2, overflow: TextOverflow.ellipsis);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: content),
        ],
      ),
    );
  }
}

class _FileInfo {
  const _FileInfo({
    required this.exists,
    this.modified,
    this.changed,
    this.size,
  });

  final bool exists;
  final DateTime? modified;
  final DateTime? changed;
  final int? size;
}
