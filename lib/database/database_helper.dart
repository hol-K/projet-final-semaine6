import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/note.dart';
import '../models/user.dart';

class DatabaseHelper {
  
  // Singleton Pattern
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();
  
  // Variables
  static Database? _database;
  static const String _databaseName = 'notes.db';
  static const int _databaseVersion = 1;
  static const String tableNotes = 'notes';
  static const String columnId = 'id';
  static const String columnTitle = 'title';
  static const String columnContent = 'content';
  static const String columnCreatedAt = 'createdAt';
  static const String columnUpdatedAt = 'updatedAt';

  // Ajoutez après les colonnes de notes
  static const String tableUsers = 'users';
  static const String columnUserId = 'id';
  static const String columnFirstName = 'firstName';
  static const String columnLastName = 'lastName';
  static const String columnUsername = 'username';
  static const String columnPassword = 'password';
  static const String columnUserCreatedAt = 'createdAt';

  // Getter de la base
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }
  
  // Initialisation
  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    print(' Chemin de la base : $path');
    
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }
  
  // Création de la table
  Future<void> _onCreate(Database db, int version) async {
  // Table notes
  await db.execute('''
    CREATE TABLE $tableNotes (
      $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
      $columnTitle TEXT NOT NULL,
      $columnContent TEXT NOT NULL,
      $columnCreatedAt TEXT NOT NULL,
      $columnUpdatedAt TEXT NOT NULL
    )
  ''');
  
  // Table users
  await db.execute('''
    CREATE TABLE $tableUsers (
      $columnUserId INTEGER PRIMARY KEY AUTOINCREMENT,
      $columnFirstName TEXT NOT NULL,
      $columnLastName TEXT NOT NULL,
      $columnUsername TEXT NOT NULL UNIQUE,
      $columnPassword TEXT NOT NULL,
      $columnUserCreatedAt TEXT NOT NULL
    )
  ''');
  
  print(' Tables créées');
}
  
  // CRUD - Insérer une note
  Future<int> insertNote(Note note) async {
    Database db = await database;
    int id = await db.insert(
      tableNotes,
      note.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    print(' Note insérée avec ID: $id');
    return id;
  }
  
  // CRUD - Récupérer toutes les notes
  Future<List<Note>> getNotes() async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      tableNotes,
      orderBy: '$columnUpdatedAt DESC',
    );
    
    List<Note> notes = maps.map((map) => Note.fromMap(map)).toList();
    print(' ${notes.length} note(s) récupérée(s)');
    return notes;
  }
  
  // CRUD - Récupérer une note par ID
  Future<Note?> getNoteById(int id) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      tableNotes,
      where: '$columnId = ?',
      whereArgs: [id],
      limit: 1,
    );
    
    if (maps.isNotEmpty) {
      print(' Note trouvée avec ID: $id');
      return Note.fromMap(maps.first);
    }
    
    print(' Aucune note trouvée avec ID: $id');
    return null;
  }
  
  // CRUD - Mettre à jour une note
  Future<int> updateNote(Note note) async {
    Database db = await database;
    int count = await db.update(
      tableNotes,
      note.toMap(),
      where: '$columnId = ?',
      whereArgs: [note.id],
    );
    print(' Note mise à jour (ID: ${note.id})');
    return count;
  }
  
  // CRUD - Supprimer une note
  Future<int> deleteNote(int id) async {
    Database db = await database;
    int count = await db.delete(
      tableNotes,
      where: '$columnId = ?',
      whereArgs: [id],
    );
    print(' Note supprimée (ID: $id)');
    return count;
  }
  
  // Supprimer toutes les notes
  Future<int> deleteAllNotes() async {
    Database db = await database;
    int count = await db.delete(tableNotes);
    print('Toutes les notes supprimées ($count notes)');
    return count;
  }
  
  // Compter les notes
  Future<int> getNotesCount() async {
    Database db = await database;
    var result = await db.rawQuery('SELECT COUNT(*) FROM $tableNotes');
    int? count = Sqflite.firstIntValue(result);
    print('Nombre de notes: $count');
    return count ?? 0;
  }
  
  // Rechercher des notes
  Future<List<Note>> searchNotes(String keyword) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      tableNotes,
      where: '$columnTitle LIKE ? OR $columnContent LIKE ?',
      whereArgs: ['%$keyword%', '%$keyword%'],
      orderBy: '$columnUpdatedAt DESC',
    );
    
    List<Note> notes = maps.map((map) => Note.fromMap(map)).toList();
    print(' ${notes.length} note(s) trouvée(s) pour "$keyword"');
    return notes;
  }
  
  // Vérifier si la base existe
  Future<bool> databaseExists() async {
    String path = join(await getDatabasesPath(), _databaseName);
    return await databaseFactory.databaseExists(path);
  }
  
  // Fermer la base
  Future<void> closeDatabase() async {
    Database db = await database;
    await db.close();
    _database = null;
    print(' Base de données fermée');
  }
  
  // Supprimer la base complètement
  Future<void> deleteDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    if (_database != null) {
      await closeDatabase();
    }
    await databaseFactory.deleteDatabase(path);
    print(' Base de données supprimée complètement');
  }
  
  // Statistiques
  Future<Map<String, dynamic>> getStatistics() async {
    Database db = await database;
    int totalNotes = await getNotesCount();
    
    var recentResult = await db.query(
      tableNotes,
      columns: [columnUpdatedAt],
      orderBy: '$columnUpdatedAt DESC',
      limit: 1,
    );
    
    var oldestResult = await db.query(
      tableNotes,
      columns: [columnCreatedAt],
      orderBy: '$columnCreatedAt ASC',
      limit: 1,
    );
    
    return {
      'totalNotes': totalNotes,
      'lastUpdate': recentResult.isNotEmpty 
          ? DateTime.parse(recentResult.first[columnUpdatedAt] as String)
          : null,
      'firstNote': oldestResult.isNotEmpty
          ? DateTime.parse(oldestResult.first[columnCreatedAt] as String)
          : null,
    };
  }

   // Inscription
Future<int> registerUser(User user) async {
  Database db = await database;
  
  // Vérifier si le username existe déjà
  var existing = await db.query(
    tableUsers,
    where: '$columnUsername = ?',
    whereArgs: [user.username],
  );
  
  if (existing.isNotEmpty) {
    throw Exception('Ce nom d\'utilisateur existe déjà');
  }
  
  int id = await db.insert(tableUsers, user.toMap());
  print('Utilisateur inscrit avec ID: $id');
  return id;
}

// Connexion
Future<User?> loginUser(String username, String password) async {
  Database db = await database;
  
  var result = await db.query(
    tableUsers,
    where: '$columnUsername = ? AND $columnPassword = ?',
    whereArgs: [username, password],
    limit: 1,
  );
  
  if (result.isNotEmpty) {
    print('Connexion réussie pour: $username');
    return User.fromMap(result.first);
  }
  
  print('Identifiants incorrects');
  return null;
}

// Vérifier si un username existe
Future<bool> usernameExists(String username) async {
  Database db = await database;
  var result = await db.query(
    tableUsers,
    where: '$columnUsername = ?',
    whereArgs: [username],
  );
  return result.isNotEmpty;}
}