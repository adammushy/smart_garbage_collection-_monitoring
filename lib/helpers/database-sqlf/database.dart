import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DBHelper {
  static final DBHelper _instance = DBHelper._privateConstructor();

  factory DBHelper() {
    return _instance;
  }

  DBHelper._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'example.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
        CREATE TABLE record (
          id INTEGER PRIMARY KEY,
          recorededAt TEXT,
          description TEXT,
          reportedAt TEXT NULL,
          isReported INTEGER DEFAULT 0
        )
      ''');
      },
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<int> insertRecord(Map<String, dynamic> row) async {
    final db = await database;
    return db.insert('record', row);
  }

  Future<List<Map<String, dynamic>>> getAllRecords(int isReported) async {
    final db = await database;
    return await db
        .query('record', where: 'isReported = ?', whereArgs: [isReported]);
  }

  Future<int> deleteRecord(int id) async {
    final db = await database;
    return await db.delete('record', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> markRecordAsReported(int id) async {
    Database db = await database;

    await db.update(
        'record',
        {
          'reportedAt':
              DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
          'isReported': 1
        },
        where: 'id = ?',
        whereArgs: [id]);
  }
}
