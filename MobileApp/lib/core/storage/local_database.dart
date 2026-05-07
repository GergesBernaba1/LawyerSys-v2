import 'dart:convert';

import 'package:path/path.dart';
import 'package:qadaya_lawyersys/core/sync/sync_queue_item.dart';
import 'package:sqflite/sqflite.dart';

class LocalDatabase {

  LocalDatabase._();
  static final LocalDatabase instance = LocalDatabase._();
  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    final path = join(await getDatabasesPath(), 'lawyersys.db');
    _db = await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
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

    await db.execute('''
      CREATE TABLE calendar_events(
        eventId TEXT PRIMARY KEY,
        data TEXT,
        fromDate TEXT,
        toDate TEXT,
        lastSyncedAt TEXT
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS calendar_events(
          eventId TEXT PRIMARY KEY,
          data TEXT,
          fromDate TEXT,
          toDate TEXT,
          lastSyncedAt TEXT
        )
      ''');
    }
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

  Future<void> upsertCustomer(String customerId, Map<String, dynamic> customerJson, {String? tenantId}) async {
    final db = await database;
    await db.insert(
      'customers',
      {
        'customerId': customerId,
        'data': jsonEncode(customerJson),
        'tenantId': tenantId,
        'lastSyncedAt': DateTime.now().toIso8601String(),
        'isDirty': 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getCustomers({String? tenantId, int limit = 50, int offset = 0}) async {
    final db = await database;
    final where = tenantId != null ? 'tenantId = ?' : null;
    final whereArgs = tenantId != null ? [tenantId] : null;
    return db.query('customers', where: where, whereArgs: whereArgs, limit: limit, offset: offset, orderBy: 'lastSyncedAt DESC');
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

  Future<void> deleteEmployee(String employeeId) async {
    final db = await database;
    await db.delete(
      'employees',
      where: 'employeeId = ?',
      whereArgs: [employeeId],
    );
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

  Future<void> upsertDocument(String documentId, Map<String, dynamic> documentJson, {String? tenantId, bool isDownloaded = false}) async {
    final db = await database;
    await db.insert(
      'documents',
      {
        'documentId': documentId,
        'data': jsonEncode(documentJson),
        'tenantId': tenantId,
        'isDownloaded': isDownloaded ? 1 : 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getDocuments({String? tenantId, int limit = 100, int offset = 0}) async {
    final db = await database;
    final where = tenantId != null ? 'tenantId = ?' : null;
    final whereArgs = tenantId != null ? [tenantId] : null;
    return db.query('documents', where: where, whereArgs: whereArgs, limit: limit, offset: offset, orderBy: 'documentId DESC');
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

  Future<void> updateSyncQueueRetryCount(String id, int retryCount) async {
    final db = await database;
    await db.update(
      'sync_queue',
      {'retryCount': retryCount},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> upsertSyncMetrics(String metricId, DateTime lastSyncAt, int attempted, int succeeded, int failed, int canceled) async {
    final db = await database;
    await db.insert(
      'sync_metrics',
      {
        'metricId': metricId,
        'lastSyncAt': lastSyncAt.toIso8601String(),
        'attempted': attempted,
        'succeeded': succeeded,
        'failed': failed,
        'canceled': canceled,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> getSyncMetrics(String metricId) async {
    final db = await database;
    final rows = await db.query('sync_metrics', where: 'metricId = ?', whereArgs: [metricId]);
    if (rows.isEmpty) return null;
    return rows.first;
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
            ),)
        .toList();
  }

  Future<void> removeSyncQueueItem(String id) async {
    final db = await database;
    await db.delete('sync_queue', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> getSyncQueueSize() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM sync_queue');
    return Sqflite.firstIntValue(result) ?? 0;
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
    await db.delete('calendar_events');
    await db.delete('sync_queue');
    await db.delete('sync_activity');
    await db.delete('sync_metrics');
  }

  Future<void> upsertCalendarEvent(
      String eventId, Map<String, dynamic> eventJson,
      {String? fromDate, String? toDate,}) async {
    final db = await database;
    await db.insert(
      'calendar_events',
      {
        'eventId': eventId,
        'data': jsonEncode(eventJson),
        'fromDate': fromDate,
        'toDate': toDate,
        'lastSyncedAt': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getCalendarEvents(
      {String? fromDate, String? toDate, int limit = 200,}) async {
    final db = await database;
    if (fromDate != null && toDate != null) {
      // Return events that overlap the requested range
      return db.rawQuery(
        '''
SELECT * FROM calendar_events
           WHERE (fromDate IS NULL OR fromDate <= ?)
             AND (toDate IS NULL OR toDate >= ?)
           ORDER BY lastSyncedAt DESC
           LIMIT ?''',
        [toDate, fromDate, limit],
      );
    }
    return db.query('calendar_events',
        orderBy: 'lastSyncedAt DESC', limit: limit,);
  }
}
