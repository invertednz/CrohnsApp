/// Model representing a user in the application
class UserModel {
  final String id;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime? lastSignInAt;
  
  /// Constructor for the user model
  UserModel({
    required this.id,
    this.email,
    this.displayName,
    this.photoUrl,
    this.metadata = const {},
    required this.createdAt,
    this.lastSignInAt,
  });
  
  /// Create a user model from a Supabase user
  factory UserModel.fromSupabaseUser(dynamic user) {
    return UserModel(
      id: user.id,
      email: user.email,
      displayName: user.userMetadata?['full_name'] ?? user.userMetadata?['name'],
      photoUrl: user.userMetadata?['avatar_url'],
      metadata: user.userMetadata ?? {},
      createdAt: DateTime.parse(user.createdAt),
      lastSignInAt: user.lastSignInAt != null ? DateTime.parse(user.lastSignInAt) : null,
    );
  }
  
  /// Convert the user model to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'display_name': displayName,
      'photo_url': photoUrl,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
      'last_sign_in_at': lastSignInAt?.toIso8601String(),
    };
  }
  
  /// Create a user model from a JSON map
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      email: json['email'],
      displayName: json['display_name'],
      photoUrl: json['photo_url'],
      metadata: json['metadata'] ?? {},
      createdAt: DateTime.parse(json['created_at']),
      lastSignInAt: json['last_sign_in_at'] != null
          ? DateTime.parse(json['last_sign_in_at'])
          : null,
    );
  }
  
  /// Create a copy of the user model with updated fields
  UserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? lastSignInAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      lastSignInAt: lastSignInAt ?? this.lastSignInAt,
    );
  }
}