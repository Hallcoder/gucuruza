import 'package:sqflite/sqflite.dart';
import '../models/item.dart';
import '../models/sale.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = '$dbPath/gucuruza.db';

    return openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        cost_price REAL NOT NULL,
        selling_price REAL NOT NULL,
        selling_mode TEXT NOT NULL DEFAULT 'unit',
        unit_label TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE sales (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        item_id INTEGER NOT NULL,
        quantity REAL NOT NULL,
        total_price REAL NOT NULL,
        is_paid INTEGER NOT NULL DEFAULT 1,
        customer_name TEXT,
        notes TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (item_id) REFERENCES items (id)
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE sales ADD COLUMN notes TEXT');
    }
  }

  // --- Items CRUD ---

  Future<int> insertItem(Item item) async {
    final db = await database;
    return db.insert('items', item.toMap());
  }

  Future<List<Item>> getItems() async {
    final db = await database;
    final maps = await db.query('items', orderBy: 'name ASC');
    return maps.map((m) => Item.fromMap(m)).toList();
  }

  Future<int> updateItem(Item item) async {
    final db = await database;
    return db.update('items', item.toMap(), where: 'id = ?', whereArgs: [item.id]);
  }

  Future<int> deleteItem(int id) async {
    final db = await database;
    await db.delete('sales', where: 'item_id = ?', whereArgs: [id]);
    return db.delete('items', where: 'id = ?', whereArgs: [id]);
  }

  // --- Sales CRUD ---

  Future<int> insertSale(Sale sale) async {
    final db = await database;
    return db.insert('sales', sale.toMap());
  }

  Future<List<Sale>> getSales({bool? isPaid, DateTime? from, DateTime? to}) async {
    final db = await database;
    String query = '''
      SELECT sales.*, items.name as item_name
      FROM sales
      INNER JOIN items ON sales.item_id = items.id
    ''';
    final conditions = <String>[];
    final args = <dynamic>[];

    if (isPaid != null) {
      conditions.add('sales.is_paid = ?');
      args.add(isPaid ? 1 : 0);
    }
    if (from != null) {
      conditions.add('sales.created_at >= ?');
      args.add(from.toIso8601String());
    }
    if (to != null) {
      final endOfDay = DateTime(to.year, to.month, to.day, 23, 59, 59);
      conditions.add('sales.created_at <= ?');
      args.add(endOfDay.toIso8601String());
    }

    if (conditions.isNotEmpty) {
      query += ' WHERE ${conditions.join(' AND ')}';
    }

    query += ' ORDER BY sales.created_at DESC';

    final maps = await db.rawQuery(query, args);
    return maps.map((m) => Sale.fromMap(m)).toList();
  }

  Future<int> deleteSale(int saleId) async {
    final db = await database;
    return db.delete('sales', where: 'id = ?', whereArgs: [saleId]);
  }

  Future<int> markSaleAsPaid(int saleId) async {
    final db = await database;
    return db.update('sales', {'is_paid': 1}, where: 'id = ?', whereArgs: [saleId]);
  }

  Future<double> getTotalDebts() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(total_price), 0) as total FROM sales WHERE is_paid = 0',
    );
    return (result.first['total'] as num).toDouble();
  }

  Future<double> getTodaySales() async {
    final db = await database;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final result = await db.rawQuery(
      "SELECT COALESCE(SUM(total_price), 0) as total FROM sales WHERE created_at LIKE '$today%' AND is_paid = 1",
    );
    return (result.first['total'] as num).toDouble();
  }

  // --- Analytics ---

  Future<Map<String, double>> getProfitForRange(DateTime from, DateTime to) async {
    final db = await database;
    final fromStr = DateTime(from.year, from.month, from.day).toIso8601String();
    final toStr = DateTime(to.year, to.month, to.day, 23, 59, 59).toIso8601String();
    final result = await db.rawQuery('''
      SELECT
        COALESCE(SUM(s.total_price), 0) as revenue,
        COALESCE(SUM(i.cost_price * s.quantity), 0) as cost
      FROM sales s
      INNER JOIN items i ON s.item_id = i.id
      WHERE s.created_at >= ? AND s.created_at <= ?
      AND s.is_paid = 1
    ''', [fromStr, toStr]);
    return {
      'revenue': (result.first['revenue'] as num).toDouble(),
      'cost': (result.first['cost'] as num).toDouble(),
    };
  }

  Future<List<Map<String, dynamic>>> getDailyRevenue(int days) async {
    final db = await database;
    final from = DateTime.now().subtract(Duration(days: days));
    final fromStr = DateTime(from.year, from.month, from.day).toIso8601String();
    return db.rawQuery('''
      SELECT
        DATE(s.created_at) as date,
        COALESCE(SUM(s.total_price), 0) as revenue,
        COALESCE(SUM(i.cost_price * s.quantity), 0) as cost
      FROM sales s
      INNER JOIN items i ON s.item_id = i.id
      WHERE s.created_at >= ?
      AND s.is_paid = 1
      GROUP BY DATE(s.created_at)
      ORDER BY date ASC
    ''', [fromStr]);
  }

  Future<List<int>> getTopSellingItemIds({int limit = 10}) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT s.item_id
      FROM sales s
      GROUP BY s.item_id
      ORDER BY SUM(s.quantity) DESC
      LIMIT ?
    ''', [limit]);
    return result.map((r) => (r['item_id'] as num).toInt()).toList();
  }

  Future<List<Map<String, dynamic>>> getTopSellingItems({
    int limit = 5,
    required DateTime from,
    required DateTime to,
  }) async {
    final db = await database;
    final fromStr = DateTime(from.year, from.month, from.day).toIso8601String();
    final toStr = DateTime(to.year, to.month, to.day, 23, 59, 59).toIso8601String();
    return db.rawQuery('''
      SELECT
        i.name,
        SUM(s.quantity) as total_qty,
        SUM(s.total_price) as total_revenue
      FROM sales s
      INNER JOIN items i ON s.item_id = i.id
      WHERE s.is_paid = 1
      AND s.created_at >= ? AND s.created_at <= ?
      GROUP BY s.item_id
      ORDER BY total_qty DESC
      LIMIT ?
    ''', [fromStr, toStr, limit]);
  }
}
