import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../sync/sync_queue_item.dart';

class LocalDatabase {
  static final LocalDatabase instance = LocalDatabase._();
  Database? _db;

  LocalDatabase._();

  Future<Database> get database async {
    if (_db != null) return _db!;
    final path = join(await getDatabasesPath(), 'lawyersys.db');
    _db = await openDatabase(path, version: 1, onCreate: _onCreate);
    return _db!;
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE cases(
        caseId TEXT PRIMARY KEY,
        data TEXT,
        tenantId TEXT,
        lastSyncedAt TEXT,
        isDirty INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE customers(
        customerId TEXT PRIMARY KEY,
        data TEXT,
        tenantId TEXT,
        lastSyncedAt TEXT,
        isDirty INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE hearings(
        hearingId TEXT PRIMARY KEY,
        data TEXT,
        tenantId TEXT,
        lastSyncedAt TEXT,
        isDirty INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE documents(
        documentId TEXT PRIMARY KEY,
        data TEXT,
        tenantId TEXT,
        lastSyncedAt TEXT,
        isDownloaded INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE notifications(
        notificationId TEXT PRIMARY KEY,
        data TEXT,
        tenantId TEXT,
        isRead INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE dashboard(
        dashboardKey TEXT PRIMARY KEY,
        data TEXT,
        tenantId TEXT,
        lastSyncedAt TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE employees(
        employeeId TEXT PRIMARY KEY,
        data TEXT,
        tenantId TEXT,
        lastSyncedAt TEXT,
        isDirty INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE sync_queue(
        id TEXT PRIMARY KEY,
        operationType TEXT,
        entityType TEXT,
        entityId TEXT,
        payload TEXT,
        retryCount INTEGER DEFAULT 0,
        createdAt TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE sync_metrics(
        metricId TEXT PRIMARY KEY,
        lastSyncAt TEXT,
        attempted INTEGER,
        succeeded INTEGER,
        failed INTEGER,
        canceled INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE sync_activity(
        id TEXT PRIMARY KEY,
        queueId TEXT,
        entityType TEXT,
        operationType TEXT,
        status TEXT,
        message TEXT,
        occurredAt TEXT
      )
    ''');
  }

  Future<void> upsertCase(String caseId, Map<String, dynamic> caseJson, {String? tenantId, bool isDirty = false}) async {
    final db = await database;
    await db.insert(
      'cases',
      {
        'caseId': caseId,
        'data': jsonEncode(caseJson),
        'tenantId': tenantId,
        'lastSyncedAt': DateTime.now().toIso8601String(),
        'isDirty': isDirty ? 1 : 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteCase(String caseId) async {
    final db = await database;
    await db.delete('cases', where: 'caseId = ?', whereArgs: [caseId]);
  }

  Future<List<Map<String, dynamic>>> getCases({String? tenantId, int limit = 20, int offset = 0}) async {
    final db = await database;
    final where = tenantId != null ? 'tenantId = ?' : null;
    final whereArgs = tenantId != null ? [tenantId] : null;
    return db.query('cases', where: where, whereArgs: whereArgs, limit: limit, offset: offset, orderBy: 'lastSyncedAt DESC');
  }

  Future<void> upsertHearing(String hearingId, Map<String, dynamic> hearingJson, {String? tenantId, bool isDirty = false}) async {
    final db = await database;
    await db.insert(
      'hearings',
      {
        'hearingId': hearingId,
        'data': jsonEncode(hearingJson),
        'tenantId': tenantId,
        'lastSyncedAt': DateTime.now().toIso8601String(),
        'isDirty': isDirty ? 1 : 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteHearing(String hearingId) async {
    final db = await database;
    await db.delete('hearings', where: 'hearingId = ?', whereArgs: [hearingId]);
  }

  Future<List<Map<String, dynamic>>> getHearings({String? tenantId, int limit = 20, int offset = 0}) async {
    final db = await database;
    final where = tenantId != null ? 'tenantId = ?' : null;
    final whereArgs = tenantId != null ? [tenantId] : null;
    return db.query('hearings', where: where, whereArgs: whereArgs, limit: limit, offset: offset, orderBy: 'lastSyncedAt DESC');
  }

  Future<void> upsertDashboard(String key, Map<String, dynamic> summaryJson, {String? tenantId}) async {
    final db = await database;
    await db.insert(
      'dashboard',
      {
        'dashboardKey': key,
        'data': jsonEncode(summaryJson),
        'tenantId': tenantId,
        'lastSyncedAt': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getDashboard(String key, {String? tenantId}) async {
    final db = await database;
    final where = 'dashboardKey = ?${tenantId != null ? ' AND tenantId = ?' : ''}';
    final whereArgs = tenantId != null ? [key, tenantId] : [key];
    return db.query('dashboard', where: where, whereArgs: whereArgs);
  }

  Future<void> upsertEmployee(String employeeId, Map<String, dynamic> employeeJson, {String? tenantId, bool isDirty = false}) async {
    final db = await database;
    await db.insert(
      'employees',
      {
        'employeeId': employeeId,
        'data': jsonEncode(employeeJson),
        'tenantId': tenantId,
        'lastSyncedAt': DateTime.now().toIso8601String(),
        'isDirty': isDirty ? 1 : 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getEmployees({String? tenantId, int limit = 20, int offset = 0}) async {
    final db = await database;
    final where = tenantId != null ? 'tenantId = ?' : null;
    final whereArgs = tenantId != null ? [tenantId] : null;
    return db.query('employees', where: where, whereArgs: whereArgs, limit: limit, offset: offset, orderBy: 'lastSyncedAt DESC');
  }

  Future<void> upsertNotification(String notificationId, Map<String, dynamic> notificationJson, {String? tenantId, bool isRead = false}) async {
    final db = await database;
    await db.insert(
      'notifications',
      {
        'notificationId': notificationId,
        'data': jsonEncode(notificationJson),
        'tenantId': tenantId,
        'isRead': isRead ? 1 : 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getNotifications({String? tenantId, int limit = 100, int offset = 0}) async {
    final db = await database;
    final where = tenantId != null ? 'tenantId = ?' : null;
    final whereArgs = tenantId != null ? [tenantId] : null;
    return db.query('notifications', where: where, whereArgs: whereArgs, limit: limit, offset: offset, orderBy: 'notificationId DESC');
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    final db = await database;
    await db.update('notifications', {'isRead': 1}, where: 'notificationId = ?', whereArgs: [notificationId]);
  }

  Future<void> addSyncQueueItem(SyncQueueItem item) async {
    final db = await database;
    await db.insert(
      'sync_queue',
      {
        'id': item.id,
        'operationType': item.operationType,
        'entityType': item.entityType,
        'entityId': item.entityId,
        'payload': jsonEncode(item.payload),
        'retryCount': item.retryCount,
        'createdAt': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> addSyncActivity(
    String id,
    String queueId,
    String entityType,
    String operationType,
    String status,
    String message,
  ) async {
    final db = await database;
    await db.insert(
      'sync_activity',
      {
        'id': id,
        'queueId': queueId,
        'entityType': entityType,
        'operationType': operationType,
        'status': status,
        'message': message,
        'occurredAt': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getSyncActivity({int limit = 50}) async {
    final db = await database;
    return db.query('sync_activity', orderBy: 'occurredAt DESC', limit: limit);
  }

  Future<List<SyncQueueItem>> getSyncQueueItems() async {
    final db = await database;
    final rows = await db.query('sync_queue', orderBy: 'createdAt ASC');
    return rows
        .map((row) => SyncQueueItem(
              id: row['id'] as String,
              operationType: row['operationType'] as String,
              entityType: row['entityType'] as String,
              entityId: row['entityId'] as String,
              payload: jsonDecode(row['payload'] as String) as Map<String, dynamic>,
              retryCount: row['retryCount'] is int ? row['retryCount'] as int : int.tryParse(row['retryCount']?.toString() ?? '0') ?? 0,
            ))
        .toList();
  }

  Future<void> removeSyncQueueItem(String id) async {
    final db = await database;
    await db.delete('sync_queue', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearSyncQueue() async {
    final db = await database;
    await db.delete('sync_queue');
  }

  Future<void> clearAllNotifications() async {
    final db = await database;
    await db.delete('notifications');
  }

  Future<void> clearAll() async {
    final db = await database;
    await db.delete('cases');
    await db.delete('customers');
    await db.delete('hearings');
    await db.delete('documents');
    await db.delete('notifications');
    await db.delete('dashboard');
    await db.delete('employees');
  }
}


