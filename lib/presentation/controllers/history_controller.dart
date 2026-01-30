import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:open_filex/open_filex.dart';

import '../../data/models/processed_file.dart';
import '../../data/repositories/processed_file_repository.dart';
import '../../data/repositories/sqflite_processed_file_repository.dart';
import '../../services/scan_service.dart';

class HistoryController extends GetxController {
  HistoryController({
    required ProcessedFileRepository repository,
    required ScanService scanService,
  })  : _repository = repository,
        _scanService = scanService;

  final ProcessedFileRepository _repository;
  final ScanService _scanService;

  final items = <ProcessedFile>[].obs;
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final hasMore = true.obs;
  final searchQuery = ''.obs;
  final favoritesOnly = false.obs;
  final isScanning = false.obs;

  final ScrollController scrollController = ScrollController();
  Worker? _searchWorker;

  static const int _pageSize = 30;

  @override
  void onInit() {
    super.onInit();
    _searchWorker = debounce(
      searchQuery,
      (_) => refreshList(),
      time: const Duration(milliseconds: 350),
    );
    scrollController.addListener(_onScroll);
    loadInitial().then((_) => _refreshExistenceInBackground());
  }

  @override
  void onClose() {
    scrollController.dispose();
    _searchWorker?.dispose();
    super.onClose();
  }

  Future<void> loadInitial() async {
    isLoading.value = true;
    try {
      final result = await _repository.getFiles(
        query: searchQuery.value,
        favoritesOnly: favoritesOnly.value,
        limit: _pageSize,
        offset: 0,
      );
      items.assignAll(result);
      hasMore.value = result.length == _pageSize;
    } catch (error) {
      _showError('Failed to load history.');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshList({
    bool refreshExistence = false,
    bool showLoader = true,
  }) async {
    if (showLoader) {
      isLoading.value = true;
    }
    try {
      if (refreshExistence) {
        await _repository.refreshExistenceStatus(batchSize: 50);
      }
      final result = await _repository.getFiles(
        query: searchQuery.value,
        favoritesOnly: favoritesOnly.value,
        limit: _pageSize,
        offset: 0,
      );
      items.assignAll(result);
      hasMore.value = result.length == _pageSize;
    } catch (_) {
      _showError('Failed to refresh history.');
    } finally {
      if (showLoader) {
        isLoading.value = false;
      }
    }
  }

  Future<void> loadMore() async {
    if (isLoadingMore.value || !hasMore.value) {
      return;
    }
    isLoadingMore.value = true;
    try {
      final result = await _repository.getFiles(
        query: searchQuery.value,
        favoritesOnly: favoritesOnly.value,
        limit: _pageSize,
        offset: items.length,
      );
      items.addAll(result);
      hasMore.value = result.length == _pageSize;
    } catch (_) {
      _showError('Failed to load more files.');
    } finally {
      isLoadingMore.value = false;
    }
  }

  void setFavoritesOnly(bool value) {
    if (favoritesOnly.value == value) {
      return;
    }
    favoritesOnly.value = value;
    refreshList();
  }

  void setSearchQuery(String value) {
    searchQuery.value = value;
  }

  Future<void> toggleFavorite(ProcessedFile item) async {
    final index = items.indexWhere((entry) => entry.id == item.id);
    if (index == -1) {
      return;
    }
    final updated = item.copyWith(isFavorite: !item.isFavorite);
    if (favoritesOnly.value && !updated.isFavorite) {
      items.removeAt(index);
    } else {
      items[index] = updated;
    }
    try {
      await _repository.toggleFavorite(item.id, updated.isFavorite);
    } catch (_) {
      if (favoritesOnly.value && !updated.isFavorite) {
        items.insert(index, item);
      } else {
        items[index] = item;
      }
      _showError('Failed to update favorite.');
    }
  }

  Future<void> deleteFromHistory(ProcessedFile item) async {
    final index = items.indexWhere((entry) => entry.id == item.id);
    if (index == -1) {
      return;
    }
    items.removeAt(index);
    try {
      await _repository.deleteFromHistory(item.id);
    } catch (_) {
      items.insert(index, item);
      _showError('Failed to remove from history.');
    }
  }

  Future<void> deleteFromDiskAndHistory(ProcessedFile item) async {
    final index = items.indexWhere((entry) => entry.id == item.id);
    if (index == -1) {
      return;
    }
    items.removeAt(index);
    try {
      await _repository.deleteFromDiskAndHistory(item.id);
    } on ProcessedFileDeleteException catch (error) {
      _showWarning(
        'Removed from history, but failed to delete ${error.failedPaths.length} file(s).',
      );
    } catch (_) {
      items.insert(index, item);
      _showError('Failed to delete file.');
    }
  }

  Future<void> openFile(ProcessedFile item) async {
    if (!item.existsOnDisk) {
      _showWarning('File is missing on disk.');
      return;
    }
    await OpenFilex.open(item.primaryPath);
    try {
      await _repository.upsertProcessedFile(
        item.copyWith(lastOpenedAt: DateTime.now()),
      );
    } catch (_) {
      // Ignore update failures for open action.
    }
  }

  Future<void> scanAndAdd() async {
    if (isScanning.value) {
      return;
    }
    isScanning.value = true;
    try {
      final result = await _scanService.scanAndSave();
      if (result == null) {
        return;
      }
      await _repository.upsertProcessedFile(result);
      await loadInitial();
    } catch (error) {
      _showError('Scan failed. Please try again.');
    } finally {
      isScanning.value = false;
    }
  }

  void _onScroll() {
    if (!scrollController.hasClients) {
      return;
    }
    final position = scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 200) {
      loadMore();
    }
  }

  Future<void> _refreshExistenceInBackground() async {
    try {
      await refreshList(refreshExistence: true, showLoader: false);
    } catch (_) {
      // Best-effort refresh.
    }
  }

  void _showError(String message) {
    if (Get.isSnackbarOpen) {
      return;
    }
    Get.snackbar('Error', message, snackPosition: SnackPosition.BOTTOM);
  }

  void _showWarning(String message) {
    if (Get.isSnackbarOpen) {
      return;
    }
    Get.snackbar('Notice', message, snackPosition: SnackPosition.BOTTOM);
  }
}
