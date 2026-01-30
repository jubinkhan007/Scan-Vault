import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/history_controller.dart';
import '../screens/file_details_view.dart';
import '../widgets/processed_file_tile.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HistoryController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              onChanged: controller.setSearchQuery,
              decoration: const InputDecoration(
                hintText: 'Search files',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Obx(
              () => SegmentedButton<bool>(
                segments: const [
                  ButtonSegment<bool>(
                    value: false,
                    label: Text('All'),
                    icon: Icon(Icons.list_alt),
                  ),
                  ButtonSegment<bool>(
                    value: true,
                    label: Text('Favorites'),
                    icon: Icon(Icons.star),
                  ),
                ],
                selected: {controller.favoritesOnly.value},
                onSelectionChanged: (selection) {
                  controller.setFavoritesOnly(selection.first);
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Obx(
              () {
                if (controller.isLoading.value && controller.items.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (controller.items.isEmpty) {
                  return const Center(child: Text('No files yet.'));
                }
                return RefreshIndicator(
                  onRefresh: () =>
                      controller.refreshList(refreshExistence: true),
                  child: ListView.builder(
                    controller: controller.scrollController,
                    itemCount: controller.items.length +
                        (controller.isLoadingMore.value ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= controller.items.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final item = controller.items[index];
                      return ProcessedFileTile(
                        item: item,
                        onToggleFavorite: () => controller.toggleFavorite(item),
                        onOpen: () => controller.openFile(item),
                        onDetails: () => Get.to(
                          () => FileDetailsView(item: item),
                        ),
                        onDeleteFromHistory: () =>
                            controller.deleteFromHistory(item),
                        onDeleteFromDisk: () =>
                            controller.deleteFromDiskAndHistory(item),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Obx(
        () => FloatingActionButton.extended(
          onPressed: controller.isScanning.value
              ? null
              : controller.scanAndAdd,
          icon: controller.isScanning.value
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.document_scanner),
          label:
              Text(controller.isScanning.value ? 'Scanning' : 'Scan'),
        ),
      ),
    );
  }
}
