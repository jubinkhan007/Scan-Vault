import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class ProcessedFileDatabase {
  static const tableName = 'processed_files';

  static Future<Database> open({DatabaseFactory? factory}) async {
    final directory = await getApplicationDocumentsDirectory();
    final path = p.join(directory.path, 'scan_vault.db');
    return _openWithPath(path, factory: factory);
  }

  static Future<Database> openWithPath(
    String path, {
    DatabaseFactory? factory,
  }) {
    return _openWithPath(path, factory: factory);
  }

  static Future<Database> _openWithPath(
    String path, {
    DatabaseFactory? factory,
  }) async {
    final dbFactory = factory ?? databaseFactory;
    return dbFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE $tableName (
              id TEXT PRIMARY KEY,
              display_name TEXT NOT NULL,
              original_pdf_path TEXT,
              output_paths TEXT NOT NULL,
              primary_path TEXT NOT NULL,
              type INTEGER NOT NULL,
              file_size_bytes INTEGER,
              created_at INTEGER NOT NULL,
              updated_at INTEGER NOT NULL,
              is_favorite INTEGER NOT NULL,
              last_opened_at INTEGER,
              checksum TEXT,
              exists_on_disk INTEGER NOT NULL,
              extra TEXT,
              normalized_name TEXT NOT NULL
            )
          ''');
          await db.execute(
            'CREATE INDEX idx_processed_files_name '
            'ON $tableName(normalized_name)',
          );
          await db.execute(
            'CREATE INDEX idx_processed_files_favorite '
            'ON $tableName(is_favorite)',
          );
          await db.execute(
            'CREATE INDEX idx_processed_files_created '
            'ON $tableName(created_at)',
          );
          await db.execute(
            'CREATE INDEX idx_processed_files_checksum '
            'ON $tableName(checksum)',
          );
          await db.execute(
            'CREATE INDEX idx_processed_files_primary '
            'ON $tableName(primary_path)',
          );
        },
      ),
    );
  }
}
