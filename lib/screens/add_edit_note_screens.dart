import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/note.dart';

class AddEditNoteScreen extends StatefulWidget {
  final Note? note; // null = mode ajout, non-null = mode édition
  
  const AddEditNoteScreen({super.key, this.note});

  @override
  State<AddEditNoteScreen> createState() => _AddEditNoteScreenState();
}

class _AddEditNoteScreenState extends State<AddEditNoteScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  
  bool _isLoading = false;
  bool get _isEditMode => widget.note != null;

  @override
  void initState() {
    super.initState();
    
    // Initialiser les contrôleurs
    _titleController = TextEditingController(
      text: widget.note?.title ?? '',
    );
    _contentController = TextEditingController(
      text: widget.note?.content ?? '',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  // Sauvegarder la note
  Future<void> _saveNote() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (_isEditMode) {
        // Mode édition : mettre à jour la note existante
        Note updatedNote = Note(
          id: widget.note!.id,
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          createdAt: widget.note!.createdAt,
          updatedAt: DateTime.now(),
        );
        
        await _databaseHelper.updateNote(updatedNote);
        
        if (mounted) {
          Navigator.pop(context, true); // true = note modifiée
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Note mise à jour avec succès'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Mode ajout : créer une nouvelle note
        Note newNote = Note(
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
        await _databaseHelper.insertNote(newNote);
        
        if (mounted) {
          Navigator.pop(context, true); // true = note ajoutée
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Note créée avec succès'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      print('Erreur lors de la sauvegarde: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Annuler et revenir en arrière
  void _cancel() {
    // Vérifier s'il y a des modifications non sauvegardées
    bool hasChanges = false;
    
    if (_isEditMode) {
      hasChanges = _titleController.text.trim() != widget.note!.title ||
                   _contentController.text.trim() != widget.note!.content;
    } else {
      hasChanges = _titleController.text.trim().isNotEmpty ||
                   _contentController.text.trim().isNotEmpty;
    }

    if (hasChanges) {
      _showCancelDialog();
    } else {
      Navigator.pop(context);
    }
  }

  // Dialogue de confirmation d'annulation
  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Annuler les modifications ?'),
        content: const Text('Les modifications non sauvegardées seront perdues.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continuer l\'édition'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Ferme le dialogue
              Navigator.pop(context); // Retourne à l'écran précédent
            },
            child: Text(
              'Annuler',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Modifier la note' : 'Nouvelle note'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _cancel,
        ),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _saveNote,
              tooltip: 'Enregistrer',
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Champ Titre
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Titre',
                hintText: 'Entrez le titre de la note',
                prefixIcon: Icon(Icons.title),
                border: OutlineInputBorder(),
              ),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textCapitalization: TextCapitalization.sentences,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Le titre est obligatoire';
                }
                if (value.trim().length < 3) {
                  return 'Le titre doit contenir au moins 3 caractères';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Champ Contenu
            TextFormField(
              controller: _contentController,
              decoration: const InputDecoration(
                labelText: 'Contenu',
                hintText: 'Écrivez votre note ici...',
                prefixIcon: Icon(Icons.notes),
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 15,
              textCapitalization: TextCapitalization.sentences,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Le contenu est obligatoire';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 24),
            
            // Boutons d'action
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _cancel,
                    icon: const Icon(Icons.cancel),
                    label: const Text('Annuler'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _saveNote,
                    icon: const Icon(Icons.save),
                    label: Text(_isEditMode ? 'Mettre à jour' : 'Enregistrer'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
            
            // Info sur la note (mode édition uniquement)
            if (_isEditMode) ...[
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 8),
              _buildInfoRow(
                icon: Icons.create,
                label: 'Créée le',
                value: _formatDate(widget.note!.createdAt),
              ),
              const SizedBox(height: 8),
              _buildInfoRow(
                icon: Icons.update,
                label: 'Modifiée le',
                value: _formatDate(widget.note!.updatedAt),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Widget pour afficher les infos de la note
  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  // Formater la date
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
           '${date.month.toString().padLeft(2, '0')}/'
           '${date.year} à '
           '${date.hour.toString().padLeft(2, '0')}:'
           '${date.minute.toString().padLeft(2, '0')}';
  }
}