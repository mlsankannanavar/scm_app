import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/local_batch_data.dart';

/// Local SQLite database service for storing batch data and capture records
class LocalBatchDatabaseService {
  static final LocalBatchDatabaseService _instance = LocalBatchDatabaseService._internal();
  factory LocalBatchDatabaseService() => _instance;
  LocalBatchDatabaseService._internal();

  Database? _database;

  /// Initialize the local database
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'batchmate_local.db');
    
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // Create batch_sessions table
        await db.execute('''
          CREATE TABLE batch_sessions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            session_id TEXT NOT NULL,
            batch_data TEXT NOT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');
        
        // Create capture_records table
        await db.execute('''
          CREATE TABLE capture_records (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            session_id TEXT NOT NULL,
            batch_number TEXT NOT NULL,
            quantity TEXT NOT NULL,
            capture_id TEXT NOT NULL,
            confidence REAL,
            created_at TEXT NOT NULL
          )
        ''');
        
        print('🗄️ LOCAL_DB: Database tables created successfully');
      },
    );
  }

  /// Store batch data for a session
  Future<void> storeBatchDataForSession(String sessionId, List<LocalBatchData> batches) async {
    final db = await database;
    final batchJson = jsonEncode(batches.map((b) => b.toJson()).toList());
    final now = DateTime.now().toIso8601String();
    
    await db.insert(
      'batch_sessions',
      {
        'session_id': sessionId,
        'batch_data': batchJson,
        'created_at': now,
        'updated_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    
    print('🗄️ LOCAL_DB: Stored ${batches.length} batches for session: $sessionId');
  }

  /// Get batch data for a session
  Future<List<LocalBatchData>> getBatchesForSession(String sessionId) async {
    final db = await database;
    final result = await db.query(
      'batch_sessions',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'updated_at DESC',
      limit: 1,
    );
    
    if (result.isEmpty) {
      print('🗄️ LOCAL_DB: No batch data found for session: $sessionId');
      return [];
    }
    
    final batchData = result.first['batch_data'] as String;
    final List<dynamic> batchJson = jsonDecode(batchData);
    final batches = batchJson.map((json) => LocalBatchData.fromJson(json)).toList();
    
    print('🗄️ LOCAL_DB: Retrieved ${batches.length} batches for session: $sessionId');
    return batches;
  }

  /// Store a capture record
  Future<void> storeCaptureRecord(
    String sessionId, 
    String batchNumber, 
    String quantity, 
    String captureId, {
    double? confidence,
  }) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    
    await db.insert(
      'capture_records',
      {
        'session_id': sessionId,
        'batch_number': batchNumber,
        'quantity': quantity,
        'capture_id': captureId,
        'confidence': confidence,
        'created_at': now,
      },
    );
    
    print('🗄️ LOCAL_DB: Stored capture record: $captureId for batch: $batchNumber');
  }

  /// Get capture records for a session
  Future<List<Map<String, dynamic>>> getCaptureRecordsForSession(String sessionId) async {
    final db = await database;
    final result = await db.query(
      'capture_records',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'created_at DESC',
    );
    
    print('🗄️ LOCAL_DB: Retrieved ${result.length} capture records for session: $sessionId');
    return result;
  }

  /// Clear old session data (keep only last 10 sessions)
  Future<void> cleanupOldSessions() async {
    final db = await database;
    
    // Keep only the 10 most recent sessions
    await db.execute('''
      DELETE FROM batch_sessions 
      WHERE id NOT IN (
        SELECT id FROM batch_sessions 
        ORDER BY updated_at DESC 
        LIMIT 10
      )
    ''');
    
    // Keep only capture records from the last 30 days
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30)).toIso8601String();
    await db.delete(
      'capture_records',
      where: 'created_at < ?',
      whereArgs: [thirtyDaysAgo],
    );
    
    print('🗄️ LOCAL_DB: Cleaned up old session data');
  }

  /// Get database statistics
  Future<Map<String, int>> getDatabaseStats() async {
    final db = await database;
    
    final sessionsCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM batch_sessions')
    ) ?? 0;
    
    final capturesCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM capture_records')
    ) ?? 0;
    
    return {
      'sessions': sessionsCount,
      'captures': capturesCount,
    };
  }

  /// Close the database
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
