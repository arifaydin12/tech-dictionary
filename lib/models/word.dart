/// A dictionary entry. Built-in entries ship with the app; community entries
/// are created by users and carry author information.
class Word {
  const Word({
    required this.id,
    required this.term,
    required this.definition,
    required this.category,
    this.example,
    this.authorId,
    this.authorName,
    this.isBuiltIn = false,
    this.createdAt,
  });

  final String id;
  final String term;
  final String definition;
  final String category;

  /// Optional usage example shown on the detail screen.
  final String? example;

  final String? authorId;
  final String? authorName;
  final bool isBuiltIn;
  final DateTime? createdAt;

  bool isOwnedBy(String? userId) =>
      !isBuiltIn && authorId != null && authorId == userId;

  Word copyWith({
    String? term,
    String? definition,
    String? category,
    String? example,
    bool clearExample = false,
  }) {
    return Word(
      id: id,
      term: term ?? this.term,
      definition: definition ?? this.definition,
      category: category ?? this.category,
      example: clearExample ? null : (example ?? this.example),
      authorId: authorId,
      authorName: authorName,
      isBuiltIn: isBuiltIn,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'term': term,
    'definition': definition,
    'category': category,
    'example': example,
    'authorId': authorId,
    'authorName': authorName,
    'createdAt': createdAt?.toIso8601String(),
  };

  factory Word.fromJson(Map<String, dynamic> json, {String? id}) {
    final created = json['createdAt'];
    return Word(
      id: id ?? json['id'] as String,
      term: json['term'] as String,
      definition: json['definition'] as String,
      category: json['category'] as String,
      example: json['example'] as String?,
      authorId: json['authorId'] as String?,
      authorName: json['authorName'] as String?,
      createdAt: created is String ? DateTime.tryParse(created) : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Word &&
      other.id == id &&
      other.term == term &&
      other.definition == definition &&
      other.category == category &&
      other.example == example;

  @override
  int get hashCode => Object.hash(id, term, definition, category, example);
}
