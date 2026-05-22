import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user.dart';
import '../models/product.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('logiflow.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Users Table
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        phone TEXT,
        address TEXT,
        is_seller INTEGER NOT NULL
      )
    ''');

    // Products Table
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        qty INTEGER NOT NULL,
        price REAL NOT NULL,
        expiry_date TEXT NOT NULL,
        condition TEXT NOT NULL,
        is_producer INTEGER NOT NULL,
        address TEXT,
        waste_prevented_kg REAL DEFAULT 0.0,
        FOREIGN KEY(user_id) REFERENCES users(id)
      )
    ''');

    // Messages Table
    await db.execute('''
      CREATE TABLE messages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sender_id INTEGER NOT NULL,
        receiver_id INTEGER NOT NULL,
        message TEXT NOT NULL,
        timestamp TEXT NOT NULL
      )
    ''');

    // Seed initial data
    await _seedData(db);
  }

  Future<void> _seedData(Database db) async {
    // Seed Users
    await db.insert('users', {
      'name': 'Green Valley Farms',
      'email': 'farm@demo.com',
      'password': 'pass123',
      'phone': '555-0101',
      'address': '123 Rural Road',
      'is_seller': 1,
    });

    await db.insert('users', {
      'name': 'Urban Market',
      'email': 'market@demo.com',
      'password': 'pass123',
      'phone': '555-0202',
      'address': '45 Main St',
      'is_seller': 1,
    });

    await db.insert('users', {
      'name': 'Eco Consumer',
      'email': 'consumer@demo.com',
      'password': 'pass123',
      'phone': '555-9999',
      'address': '789 Oak Ave',
      'is_seller': 0,
    });

    // Seed some products
    final today = DateTime.now();
    await db.insert('products', {
      'user_id': 1,
      'name': 'Organic Milk',
      'qty': 50,
      'price': 3.50,
      'expiry_date': today.add(const Duration(days: 15)).toIso8601String(),
      'condition': 'Fresh',
      'is_producer': 1,
      'address': 'Farm Gate',
    });
  }

  // ==================== AUTH ====================
  Future<User?> loginUser(String email, String password) async {
    final db = await instance.database;
    final maps = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );

    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  Future<bool> registerUser(User user) async {
    final db = await instance.database;
    try {
      await db.insert('users', user.toMap());
      return true;
    } catch (e) {
      return false; // Email already exists
    }
  }

  // ==================== PRODUCTS ====================
  Future<List<Product>> getAllProducts() async {
    final db = await instance.database;
    final result = await db.query('products');
    return result.map((json) => Product.fromMap(json)).toList();
  }

  Future<List<Product>> getUserProducts(int userId) async {
    final db = await instance.database;
    final result = await db.query(
      'products',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    return result.map((json) => Product.fromMap(json)).toList();
  }

  Future<void> insertProduct(Product product) async {
    final db = await instance.database;
    await db.insert('products', product.toMap());
  }

  // ==================== MESSAGES ====================
  Future<void> sendMessage(int senderId, int receiverId, String message) async {
    final db = await instance.database;
    await db.insert('messages', {
      'sender_id': senderId,
      'receiver_id': receiverId,
      'message': message,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getMessages(int userA, int userB) async {
    final db = await instance.database;
    return await db.query(
      'messages',
      where: '(sender_id = ? AND receiver_id = ?) OR (sender_id = ? AND receiver_id = ?)',
      whereArgs: [userA, userB, userB, userA],
      orderBy: 'timestamp ASC',
    );
  }
}
