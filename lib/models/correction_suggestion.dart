class CorrectionSuggestion {
  final String? id;
  final String wordId;
  final String wordTerm;
  final String suggestedTerm;
  final String suggestedDefinition;
  final String? suggestedCategory;
  final String suggestedBy; // Kullanıcı ID
  final String suggestedByName; // Kullanıcı adı
  final String reason; // Düzeltme nedeni
  final DateTime createdAt;
  final String status; // 'pending', 'accepted', 'rejected'

  CorrectionSuggestion({
    this.id,
    required this.wordId,
    required this.wordTerm,
    required this.suggestedTerm,
    required this.suggestedDefinition,
    this.suggestedCategory,
    required this.suggestedBy,
    required this.suggestedByName,
    required this.reason,
    DateTime? createdAt,
    this.status = 'pending',
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toFirestore() => {
    'wordId': wordId,
    'wordTerm': wordTerm,
    'suggestedTerm': suggestedTerm,
    'suggestedDefinition': suggestedDefinition,
    'suggestedCategory': suggestedCategory,
    'suggestedBy': suggestedBy,
    'suggestedByName': suggestedByName,
    'reason': reason,
    'createdAt': createdAt.toIso8601String(),
    'status': status,
  };

  factory CorrectionSuggestion.fromFirestore(Map<String, dynamic> json, String docId) {
    return CorrectionSuggestion(
      id: docId,
      wordId: json['wordId'] as String,
      wordTerm: json['wordTerm'] as String,
      suggestedTerm: json['suggestedTerm'] as String,
      suggestedDefinition: json['suggestedDefinition'] as String,
      suggestedCategory: json['suggestedCategory'] as String?,
      suggestedBy: json['suggestedBy'] as String,
      suggestedByName: json['suggestedByName'] as String,
      reason: json['reason'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      status: json['status'] as String? ?? 'pending',
    );
  }
}

