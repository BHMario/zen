class User {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? profileImageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isEmailVerified;
  final bool lopdAccepted;
  final bool shareAnalytics;
  final bool showActiveStatus;
  final bool marketingEmails;
  final bool profilePrivate;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.profileImageUrl,
    required this.createdAt,
    required this.updatedAt,
    this.isEmailVerified = false,
    this.lopdAccepted = false,
    this.shareAnalytics = true,
    this.showActiveStatus = true,
    this.marketingEmails = true,
    this.profilePrivate = false,
  });

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? profileImageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isEmailVerified,
    bool? lopdAccepted,
    bool? shareAnalytics,
    bool? showActiveStatus,
    bool? marketingEmails,
    bool? profilePrivate,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      lopdAccepted: lopdAccepted ?? this.lopdAccepted,
      shareAnalytics: shareAnalytics ?? this.shareAnalytics,
      showActiveStatus: showActiveStatus ?? this.showActiveStatus,
      marketingEmails: marketingEmails ?? this.marketingEmails,
      profilePrivate: profilePrivate ?? this.profilePrivate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'profileImageUrl': profileImageUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isEmailVerified': isEmailVerified,
      'lopdAccepted': lopdAccepted,
      'shareAnalytics': shareAnalytics,
      'showActiveStatus': showActiveStatus,
      'marketingEmails': marketingEmails,
      'profilePrivate': profilePrivate,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as String,
      name: map['name'] as String,
      email: map['email'] as String,
      phone: map['phone'] as String?,
      profileImageUrl: map['profileImageUrl'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      isEmailVerified: map['isEmailVerified'] as bool? ?? false,
      lopdAccepted: map['lopdAccepted'] as bool? ?? false,
      shareAnalytics: map['shareAnalytics'] as bool? ?? true,
      showActiveStatus: map['showActiveStatus'] as bool? ?? true,
      marketingEmails: map['marketingEmails'] as bool? ?? true,
      profilePrivate: map['profilePrivate'] as bool? ?? false,
    );
  }
}
