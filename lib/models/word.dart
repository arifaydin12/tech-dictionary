class Word {
  final String? id; // Firebase document ID
  final String term;
  final String definition;
  final String category;
  final DateTime createdAt;
  final String? userId; // Kelimeyi oluşturan kullanıcı ID
  final String? createdBy; // Kullanıcı adı
  final String? imageUrl; // Kelime görseli URL
  bool isFavorite;

  Word({
    this.id,
    required this.term,
    required this.definition,
    required this.category,
    DateTime? createdAt,
    this.isFavorite = false,
    this.userId,
    this.createdBy,
    this.imageUrl,
  }) : createdAt = createdAt ?? DateTime.now();

  // Kolay arama için
  String get searchableText => '$term $definition $category'.toLowerCase();

  // Sahiplik kontrolü
  bool isOwnedBy(String? userId) => this.userId != null && this.userId == userId;

  // JSON dönüşüm (local storage için)
  Map<String, dynamic> toJson() => {
    'id': id,
    'term': term,
    'definition': definition,
    'category': category,
    'createdAt': createdAt.toIso8601String(),
    'isFavorite': isFavorite,
    'userId': userId,
    'createdBy': createdBy,
    'imageUrl': imageUrl,
  };

  factory Word.fromJson(Map<String, dynamic> json) => Word(
    id: json['id'] as String?,
    term: json['term'] as String,
    definition: json['definition'] as String,
    category: json['category'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
    isFavorite: json['isFavorite'] as bool? ?? false,
    userId: json['userId'] as String?,
    createdBy: json['createdBy'] as String?,
    imageUrl: json['imageUrl'] as String?,
  );

  // Firestore dönüşüm
  Map<String, dynamic> toFirestore() => {
    'term': term,
    'definition': definition,
    'category': category,
    'createdAt': createdAt.toIso8601String(),
    'isFavorite': isFavorite,
    'userId': userId,
    'createdBy': createdBy,
    'imageUrl': imageUrl,
  };

  factory Word.fromFirestore(Map<String, dynamic> json, String docId) => Word(
    id: docId,
    term: json['term'] as String,
    definition: json['definition'] as String,
    category: json['category'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
    isFavorite: json['isFavorite'] as bool? ?? false,
    userId: json['userId'] as String?,
    createdBy: json['createdBy'] as String?,
    imageUrl: json['imageUrl'] as String?,
  );

  // Kopyalama için
  Word copyWith({
    String? id,
    String? term,
    String? definition,
    String? category,
    DateTime? createdAt,
    bool? isFavorite,
    String? userId,
    String? createdBy,
    String? imageUrl,
  }) {
    return Word(
      id: id ?? this.id,
      term: term ?? this.term,
      definition: definition ?? this.definition,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      isFavorite: isFavorite ?? this.isFavorite,
      userId: userId ?? this.userId,
      createdBy: createdBy ?? this.createdBy,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}
