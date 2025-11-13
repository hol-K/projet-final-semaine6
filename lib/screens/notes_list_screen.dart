import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/note.dart';
import 'add_edit_note_screens.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';
import 'login_screens.dart';


class NotesListScreen extends StatefulWidget {
  final String username;
  
  const NotesListScreen({super.key, required this.username});

  @override
  State<NotesListScreen> createState() => _NotesListScreenState();
}

class _NotesListScreenState extends State<NotesListScreen> {
  // Instance du DatabaseHelper
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  
  // Liste des notes (vide au début)
  List<Note> _notes = [];
  
  // Variable pour afficher un indicateur de chargement
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Charger les notes depuis la base au démarrage
    _loadNotes();
  }

  // Fonction pour charger les notes depuis SQLite
  Future<void> _loadNotes() async {
    setState(() {
      _isLoading = true; // Afficher le spinner
    });
    
    try {
      // Récupérer toutes les notes de la base
      List<Note> notes = await _databaseHelper.getNotes();
      
      setState(() {
        _notes = notes;
        _isLoading = false;
      });
      
      print('${notes.length} note(s) chargée(s) depuis la base');
    } catch (e) {
      print(' Erreur lors du chargement des notes: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Fonction pour supprimer une note
  Future<void> _deleteNote(int? id) async {
    if (id == null) return;
    
    try {
      // Supprimer de la base
      await _databaseHelper.deleteNote(id);
      
      // Recharger la liste
      await _loadNotes();
      
      // Afficher un message de confirmation
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Note supprimée avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print(' Erreur lors de la suppression: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Barre du haut
      appBar: AppBar(
  title: Text('Mes Notes (${_notes.length})'),
  actions: [
    // Bouton mode sombre
    Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return IconButton(
          icon: Icon(
            themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
          ),
          onPressed: () {
            themeProvider.toggleTheme();
          },
          tooltip: themeProvider.isDarkMode ? 'Mode clair' : 'Mode sombre',
        );
      },
    ),
    // Bouton pour recharger les notes
    IconButton(
      icon: const Icon(Icons.refresh),
      onPressed: _loadNotes,
      tooltip: 'Actualiser',
    ),
    // Bouton de déconnexion
    IconButton(
      icon: const Icon(Icons.logout),
      onPressed: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      },
      tooltip: 'Déconnexion',
    ),
  ],
),
      
      // Corps de l'écran
      body: _isLoading
          ? _buildLoadingState()  // Afficher le spinner pendant le chargement
          : _notes.isEmpty
              ? _buildEmptyState()   // Si pas de notes
              : _buildNotesList(),   // Si des notes existent
      
      // Bouton flottant pour ajouter une note
      // Bouton flottant pour ajouter une note
floatingActionButton: FloatingActionButton(
  onPressed: () async {
    // Navigation vers l'écran d'ajout
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddEditNoteScreen(),
      ),
    );
    
    // Si une note a été ajoutée, recharger la liste
    if (result == true) {
      _loadNotes();
    }
  },
  child: const Icon(Icons.add),
  tooltip: 'Ajouter une note',
),
    );
  }

  // Widget pour l'état de chargement
  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Chargement des notes...'),
        ],
      ),
    );
  }

  // Widget pour l'état vide (pas de notes)
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.note_add_outlined,
            size: 100,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune note pour le moment',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Appuyez sur + pour créer votre première note',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  // Widget pour afficher la liste des notes
  Widget _buildNotesList() {
    return RefreshIndicator(
      onRefresh: _loadNotes, // Tire vers le bas pour recharger
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _notes.length,
        itemBuilder: (context, index) {
          final note = _notes[index];
          return _buildNoteCard(note);
        },
      ),
    );
  }

  // Widget pour une carte de note
  Widget _buildNoteCard(Note note) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () async {
        // Navigation vers l'écran d'édition
        final result = await Navigator.push(
          context,
        MaterialPageRoute(
           builder: (context) => AddEditNoteScreen(note: note),
         ),
        ); 
  // Si la note a été modifiée, recharger la liste
          if (result == true) {
               _loadNotes();
            }
          },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Titre de la note
              Text(
                note.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 8),
              
              // Aperçu du contenu (2 premières lignes)
              Text(
                note.content,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 12),
              
              // Date et actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Icône et date
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(note.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  
                  // Bouton de suppression
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      color: Colors.red[400],
                    ),
                    onPressed: () {
                      _showDeleteDialog(note);
                    },
                    tooltip: 'Supprimer',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Formater la date
  String _formatDate(DateTime date) {
    DateTime now = DateTime.now();
    
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return 'Aujourd\'hui ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  // Dialogue de confirmation de suppression
  void _showDeleteDialog(Note note) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la note ?'),
        content: Text('Voulez-vous vraiment supprimer "${note.title}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteNote(note.id);
            },
            child: Text(
              'Supprimer',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

}