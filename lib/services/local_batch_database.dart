import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/local_batch_data.dart';

/// Local database service for storing batch data for offline OCR processing
class LocalBatchDatabase {
  static final LocalBatchDatabase _instance = LocalBatchDatabase._internal();
  factory LocalBatchDatabase() => _instance;
  LocalBatchDatabase._internal();

  Database? _database;

  /// Initialize the database
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'batch_data.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create sessions table
    await db.execute('''
      CREATE TABLE sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id TEXT UNIQUE NOT NULL,
        total_batches INTEGER NOT NULL,
        downloaded_at TEXT NOT NULL,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Create batches table
    await db.execute('''
      CREATE TABLE batches (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id TEXT NOT NULL,
        batch_number TEXT NOT NULL,
        expiry_date TEXT,
        item_name TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (session_id) REFERENCES sessions (session_id) ON DELETE CASCADE,
        UNIQUE(session_id, batch_number)
      )
    ''');

    // Create indexes for faster searches
    await db.execute('''
      CREATE INDEX idx_batches_session_id ON batches (session_id)
    ''');
    
    await db.execute('''
      CREATE INDEX idx_batches_batch_number ON batches (batch_number)
    ''');
  }

  /// Store session batch data
  Future<void> storeSessionData(SessionBatchData sessionData) async {
    final db = await database;
    
    await db.transaction((txn) async {
      // Clear existing data for this session
      await txn.delete('batches', where: 'session_id = ?', whereArgs: [sessionData.sessionId]);
      await txn.delete('sessions', where: 'session_id = ?', whereArgs: [sessionData.sessionId]);
      
      // Insert session record
      await txn.insert('sessions', {
        'session_id': sessionData.sessionId,
        'total_batches': sessionData.totalBatches,
        'downloaded_at': sessionData.downloadedAt.toIso8601String(),
      });
      
      // Insert batch records
      for (final batch in sessionData.batches.values) {
        await txn.insert('batches', {
          'session_id': sessionData.sessionId,
          'batch_number': batch.batchNumber,
          'expiry_date': batch.expiryDate,
          'item_name': batch.itemName,
        });
      }
    });
    
    print('📂 LOCAL_DB: Stored ${sessionData.batches.length} batches for session ${sessionData.sessionId}');
  }

  /// Get session batch data
  Future<SessionBatchData?> getSessionData(String sessionId) async {
    final db = await database;
    
    // Get session info
    final sessionQuery = await db.query(
      'sessions',
      where: 'session_id = ?',
      whereArgs: [sessionId],
    );
    
    if (sessionQuery.isEmpty) return null;
    
    final sessionInfo = sessionQuery.first;
    
    // Get batches for this session
    final batchQuery = await db.query(
      'batches',
      where: 'session_id = ?',
      whereArgs: [sessionId],
    );
    
    final Map<String, LocalBatchData> batches = {};
    for (final row in batchQuery) {
      final batch = LocalBatchData(
        batchNumber: row['batch_number'] as String,
        expiryDate: row['expiry_date'] as String?,
        itemName: row['item_name'] as String?,
      );
      batches[batch.batchNumber] = batch;
    }
    
    return SessionBatchData(
      sessionId: sessionId,
      batches: batches,
      downloadedAt: DateTime.parse(sessionInfo['downloaded_at'] as String),
      totalBatches: sessionInfo['total_batches'] as int,
    );
  }

  /// Check if session data exists
  Future<bool> hasSessionData(String sessionId) async {
    final db = await database;
    final result = await db.query(
      'sessions',
      where: 'session_id = ?',
      whereArgs: [sessionId],
    );
    return result.isNotEmpty;
  }

  /// Get all batches for a session (for search)
  Future<Map<String, LocalBatchData>> getBatchesForSession(String sessionId) async {
    final sessionData = await getSessionData(sessionId);
    return sessionData?.batches ?? {};
  }

  /// Clear session data
  Future<void> clearSession(String sessionId) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('batches', where: 'session_id = ?', whereArgs: [sessionId]);
      await txn.delete('sessions', where: 'session_id = ?', whereArgs: [sessionId]);
    });
    print('🗑️ LOCAL_DB: Cleared session data for $sessionId');
  }

  /// Clear all data (for app reset)
  Future<void> clearAllData() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('batches');
      await txn.delete('sessions');
    });
    print('🗑️ LOCAL_DB: Cleared all session data');
  }

  /// Get database stats
  Future<Map<String, int>> getStats() async {
    final db = await database;
    
    final sessionCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM sessions')
    ) ?? 0;
    
    final batchCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM batches')
    ) ?? 0;
    
    return {
      'sessions': sessionCount,
      'batches': batchCount,
    };
  }

  /// Close database connection
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
