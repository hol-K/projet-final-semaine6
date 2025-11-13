class Note {
  //propiétés d'une note
  int? id; 
  String title ;
  String content; 
  DateTime createdAt;
  DateTime updatedAt;


// constructeur de la classe note 
Note({
  this.id,
  required this.title,
  required this.content,
  required this.createdAt,  
  required this.updatedAt,  
});

  // Méthode toString() pour afficher la note dans la console (debug)
  @override
  String toString() {
    return 'Note{id: $id, title: $title, content: $content, createdAt: $createdAt, updatedAt: $updatedAt}';
  }

  //conversion de la note en map pour la base de données
Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  //création d'un objet Note à partir d'une map
  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'],
      title: map['title'],
      content: map['content'],
      createdAt: DateTime.parse(map['createdAt']as String),
      updatedAt: DateTime.parse(map['updatedAt']as String),
    );
  }

  // Méthode pour mettre à jour la date de mise à jour
  void updateTimestamp() {
    updatedAt = DateTime.now();
  }
  // Méthode pour mettre à jour le contenu de la note
  void updateContent(String newContent) {
    content = newContent;
    updateTimestamp(); // Met à jour la date de mise à jour
  }
  //méthode pour mettre à jour le titre 
  void updateTitle(String newTitle) {
    title = newTitle;
    updateTimestamp(); // Met à jour la date de mise à jour
    if (title.isEmpty) {
      print('Le titre ne peut pas être vide');
    } else {
      print('Titre mis à jour : $title');
    }
  }
  // Méthode pour vérifier si la note est vide
  bool isEmpty() {
    final empty = title.isEmpty && content.isEmpty;
    if (empty) {
      print('La note est vide');
    }
    return empty;
  }
  // Méthode pour vérifier si la note est valide
  bool isValid() {
    print('La note est valide');
    return title.isNotEmpty && content.isNotEmpty;
  } 
  // Méthode pour obtenir un résumé du contenu
  String getContentSummary(int maxLength) {
    if (content.length <= maxLength) {
      return content;
    } else {
      return '${content.substring(0, maxLength)}...';
    }
  }
}