import 'package:hive/hive.dart';

part 'registration_model.g.dart';

@HiveType(typeId: 4)
class RegistrationModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String judgeName;

  @HiveField(2)
  String email;

  @HiveField(3)
  String password;

  @HiveField(4)
  String country;

  @HiveField(5)
  bool oath;

  @HiveField(6)
  DateTime createdAt;

  @HiveField(7)
  bool isEmailVerified;

  @HiveField(8)
  String? activationCode;

  @HiveField(9)
  DateTime? emailVerifiedAt;

  @HiveField(10)
  bool isActive;

  @HiveField(11)
  String? phoneNumber;

  @HiveField(12)
  String? profileImage;

  @HiveField(13)
  DateTime lastLoginAt;

  @HiveField(14)
  int loginAttempts;

  @HiveField(15)
  DateTime? lastLoginAttemptAt;

  /// Kullanıcının admin yetkisi olup olmadığını belirtir
  /// Admin kullanıcılar özel sayfalara erişebilir
  @HiveField(16)
  bool isAdmin;

  /// Son dava açma zamanı - 19 saatlik süre kontrolü için
  @HiveField(17)
  DateTime? lastDavaAcTime;

  /// Son haykırma zamanı - 19 saatlik süre kontrolü için
  @HiveField(18)
  DateTime? lastHaykirTime;

  RegistrationModel({
    required this.id,
    required this.judgeName,
    required this.email,
    required this.password,
    required this.country,
    required this.oath,
    required this.createdAt,
    this.isEmailVerified = false,
    this.activationCode,
    this.emailVerifiedAt,
    this.isActive = true,
    this.phoneNumber,
    this.profileImage,
    required this.lastLoginAt,
    this.loginAttempts = 0,
    this.lastLoginAttemptAt,
    this.isAdmin = false,
    this.lastDavaAcTime,
    this.lastHaykirTime,
  });

  // JSON'dan model oluşturma
  factory RegistrationModel.fromJson(Map<String, dynamic> json) {
    return RegistrationModel(
      id: json['id'] ?? '',
      judgeName: json['judgeName'] ?? '',
      email: json['email'] ?? '',
      password: json['password'] ?? '',
      country: json['country'] ?? '',
      oath: json['oath'] ?? false,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      isEmailVerified: json['isEmailVerified'] ?? false,
      activationCode: json['activationCode'],
      emailVerifiedAt: json['emailVerifiedAt'] != null 
          ? DateTime.parse(json['emailVerifiedAt']) 
          : null,
      isActive: json['isActive'] ?? true,
      phoneNumber: json['phoneNumber'],
      profileImage: json['profileImage'],
      lastLoginAt: DateTime.parse(json['lastLoginAt'] ?? DateTime.now().toIso8601String()),
      loginAttempts: json['loginAttempts'] ?? 0,
      lastLoginAttemptAt: json['lastLoginAttemptAt'] != null 
          ? DateTime.parse(json['lastLoginAttemptAt']) 
          : null,
      isAdmin: json['isAdmin'] ?? false,
      lastDavaAcTime: json['lastDavaAcTime'] != null 
          ? DateTime.parse(json['lastDavaAcTime']) 
          : null,
      lastHaykirTime: json['lastHaykirTime'] != null 
          ? DateTime.parse(json['lastHaykirTime']) 
          : null,
    );
  }

  // Model'den JSON oluşturma
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'judgeName': judgeName,
      'email': email,
      'password': password,
      'country': country,
      'oath': oath,
      'createdAt': createdAt.toIso8601String(),
      'isEmailVerified': isEmailVerified,
      'activationCode': activationCode,
      'emailVerifiedAt': emailVerifiedAt?.toIso8601String(),
      'isActive': isActive,
      'phoneNumber': phoneNumber,
      'profileImage': profileImage,
      'lastLoginAt': lastLoginAt.toIso8601String(),
      'loginAttempts': loginAttempts,
      'lastLoginAttemptAt': lastLoginAttemptAt?.toIso8601String(),
      'isAdmin': isAdmin,
      'lastDavaAcTime': lastDavaAcTime?.toIso8601String(),
      'lastHaykirTime': lastHaykirTime?.toIso8601String(),
    };
  }

  // Kopyalama metodu
  RegistrationModel copyWith({
    String? id,
    String? judgeName,
    String? email,
    String? password,
    String? country,
    bool? oath,
    DateTime? createdAt,
    bool? isEmailVerified,
    String? activationCode,
    DateTime? emailVerifiedAt,
    bool? isActive,
    String? phoneNumber,
    String? profileImage,
    DateTime? lastLoginAt,
    int? loginAttempts,
    DateTime? lastLoginAttemptAt,
    bool? isAdmin,
    DateTime? lastDavaAcTime,
    DateTime? lastHaykirTime,
  }) {
    return RegistrationModel(
      id: id ?? this.id,
      judgeName: judgeName ?? this.judgeName,
      email: email ?? this.email,
      password: password ?? this.password,
      country: country ?? this.country,
      oath: oath ?? this.oath,
      createdAt: createdAt ?? this.createdAt,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      activationCode: activationCode ?? this.activationCode,
      emailVerifiedAt: emailVerifiedAt ?? this.emailVerifiedAt,
      isActive: isActive ?? this.isActive,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImage: profileImage ?? this.profileImage,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      loginAttempts: loginAttempts ?? this.loginAttempts,
      lastLoginAttemptAt: lastLoginAttemptAt ?? this.lastLoginAttemptAt,
      isAdmin: isAdmin ?? this.isAdmin,
      lastDavaAcTime: lastDavaAcTime ?? this.lastDavaAcTime,
      lastHaykirTime: lastHaykirTime ?? this.lastHaykirTime,
    );
  }

  // E-posta doğrulama metodu
  void verifyEmail() {
    isEmailVerified = true;
    emailVerifiedAt = DateTime.now();
  }

  // Giriş denemesi kaydetme metodu
  void recordLoginAttempt() {
    loginAttempts++;
    lastLoginAttemptAt = DateTime.now();
  }

  // Başarılı giriş metodu
  void recordSuccessfulLogin() {
    lastLoginAt = DateTime.now();
    loginAttempts = 0;
  }

  // Hesap aktiflik durumu kontrolü
  bool get canLogin => isActive && isEmailVerified;

  // Hesap kilitleme kontrolü (5 başarısız deneme sonrası)
  bool get isLocked => loginAttempts >= 5;
} 