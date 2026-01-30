import 'dart:io';

import 'package:flutter/material.dart';

import '../../data/models/processed_file.dart';
import '../utils/formatters.dart';

enum _MenuAction {
  open,
  details,
  deleteFile,
  removeHistory,
}

class ProcessedFileTile extends StatelessWidget {
  const ProcessedFileTile({
    super.key,
    required this.item,
    required this.onToggleFavorite,
    required this.onOpen,
    required this.onDetails,
    required this.onDeleteFromHistory,
    required this.onDeleteFromDisk,
  });

  final ProcessedFile item;
  final VoidCallback onToggleFavorite;
  final VoidCallback onOpen;
  final VoidCallback onDetails;
  final VoidCallback onDeleteFromHistory;
  final VoidCallback onDeleteFromDisk;

  @override
  Widget build(BuildContext context) {
    final subtitle = _buildSubtitle(context);
    return ListTile(
      leading: _buildLeading(),
      title: Text(item.displayName, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: subtitle,
      onTap: onDetails,
      trailing: Wrap(
        spacing: 4,
        children: [
          IconButton(
            icon: Icon(
              item.isFavorite ? Icons.star : Icons.star_border,
              color: item.isFavorite
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
            onPressed: onToggleFavorite,
          ),
          PopupMenuButton<_MenuAction>(
            onSelected: (value) {
              switch (value) {
                case _MenuAction.open:
                  onOpen();
                  break;
                case _MenuAction.details:
                  onDetails();
                  break;
                case _MenuAction.deleteFile:
                  onDeleteFromDisk();
                  break;
                case _MenuAction.removeHistory:
                  onDeleteFromHistory();
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: _MenuAction.open,
                enabled: item.existsOnDisk,
                child: const Text('Open'),
              ),
              const PopupMenuItem(
                value: _MenuAction.details,
                child: Text('Details'),
              ),
              const PopupMenuItem(
                value: _MenuAction.deleteFile,
                child: Text('Delete file'),
              ),
              const PopupMenuItem(
                value: _MenuAction.removeHistory,
                child: Text('Remove from history'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLeading() {
    if (item.type == ProcessedFileType.image && item.existsOnDisk) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          File(item.primaryPath),
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallbackIcon(),
        ),
      );
    }
    return _fallbackIcon();
  }

  Widget _fallbackIcon() {
    final icon = item.type == ProcessedFileType.pdf
        ? Icons.picture_as_pdf
        : item.type == ProcessedFileType.image
            ? Icons.image
            : Icons.insert_drive_file;
    return CircleAvatar(
      backgroundColor: Colors.grey.shade200,
      child: Icon(icon, color: Colors.grey.shade700),
    );
  }

  Widget _buildSubtitle(BuildContext context) {
    final subtitleText =
        '${ProcessedFileFormatters.formatDate(item.createdAt)} • '
        '${ProcessedFileFormatters.formatBytes(item.fileSizeBytes)} • '
        '${ProcessedFileFormatters.formatType(item.type)}';
    if (!item.existsOnDisk) {
      return Wrap(
        spacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(subtitleText),
          Chip(
            label: const Text('Missing'),
            visualDensity: VisualDensity.compact,
            backgroundColor: Theme.of(context).colorScheme.errorContainer,
            labelStyle: TextStyle(
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
          ),
        ],
      );
    }
    return Text(subtitleText);
  }
}
