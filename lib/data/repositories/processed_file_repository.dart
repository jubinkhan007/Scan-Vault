import '../models/processed_file.dart';

abstract class ProcessedFileRepository {
  Future<void> upsertProcessedFile(ProcessedFile item);
  Future<List<ProcessedFile>> getFiles({
    String? query,
    bool favoritesOnly = false,
    int limit = 30,
    int offset = 0,
  });
  Future<ProcessedFile?> getById(String id);
  Future<void> toggleFavorite(String id, bool isFavorite);
  Future<void> deleteFromHistory(String id);
  Future<void> deleteFromDiskAndHistory(String id);
  Future<void> refreshExistenceStatus({int batchSize = 50});
}
