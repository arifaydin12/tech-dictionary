/// Kullanıcı bilgileri modeli
class UserProfile {
  final String uid;
  final String email;
  final String displayName;
  final String? photoURL;
  final String? phoneNumber;
  final String? bio;

  // Profil detayları
  final String? occupation; // Meslek
  final String? location; // Konum
  final List<String> interests; // İlgi alanları

  // Hesap bilgileri
  final String accountType; // 'email', 'google', 'apple'
  final bool isEmailVerified;
  final bool isPremium;

  // Tarihler
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastLoginAt;

  UserProfile({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoURL,
    this.phoneNumber,
    this.bio,
    this.occupation,
    this.location,
    List<String>? interests,
    this.accountType = 'email',
    this.isEmailVerified = false,
    this.isPremium = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.lastLoginAt,
  }) : interests = interests ?? [],
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  /// Firestore'a kaydet
  Map<String, dynamic> toFirestore() => {
    'uid': uid,
    'email': email,
    'displayName': displayName,
    'photoURL': photoURL,
    'phoneNumber': phoneNumber,
    'bio': bio,
    'occupation': occupation,
    'location': location,
    'interests': interests,
    'accountType': accountType,
    'isEmailVerified': isEmailVerified,
    'isPremium': isPremium,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'lastLoginAt': lastLoginAt?.toIso8601String(),
  };

  /// Firestore'dan oluştur
  factory UserProfile.fromFirestore(Map<String, dynamic> data) {
    return UserProfile(
      uid: data['uid'] as String,
      email: data['email'] as String,
      displayName:
          data['displayName'] as String? ??
          (data['email'] as String).split('@')[0],
      photoURL: data['photoURL'] as String?,
      phoneNumber: data['phoneNumber'] as String?,
      bio: data['bio'] as String?,
      occupation: data['occupation'] as String?,
      location: data['location'] as String?,
      interests:
          (data['interests'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      accountType: data['accountType'] as String? ?? 'email',
      isEmailVerified: data['isEmailVerified'] as bool? ?? false,
      isPremium: data['isPremium'] as bool? ?? false,
      createdAt: data['createdAt'] != null
          ? DateTime.parse(data['createdAt'] as String)
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? DateTime.parse(data['updatedAt'] as String)
          : DateTime.now(),
      lastLoginAt: data['lastLoginAt'] != null
          ? DateTime.parse(data['lastLoginAt'] as String)
          : null,
    );
  }

  /// Kopyala ve değiştir
  UserProfile copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoURL,
    String? phoneNumber,
    String? bio,
    String? occupation,
    String? location,
    List<String>? interests,
    String? accountType,
    bool? isEmailVerified,
    bool? isPremium,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastLoginAt,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      bio: bio ?? this.bio,
      occupation: occupation ?? this.occupation,
      location: location ?? this.location,
      interests: interests ?? this.interests,
      accountType: accountType ?? this.accountType,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isPremium: isPremium ?? this.isPremium,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }

  /// Kullanıcı adının baş harflerini al (Avatar için)
  String get initials {
    final parts = displayName.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';
  }
}
