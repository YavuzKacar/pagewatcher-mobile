/// Mirrors the backend's `UserResponse` (backend/app/schemas/user.py).
class User {
  const User({
    required this.id,
    required this.email,
    required this.displayName,
    required this.isActive,
    required this.isAdmin,
    required this.plan,
    required this.subscriptionStatus,
    required this.trialEndsAt,
    required this.emailVerified,
    required this.emailNotificationsEnabled,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as String,
        email: json['email'] as String,
        displayName: json['display_name'] as String?,
        isActive: json['is_active'] as bool? ?? true,
        isAdmin: json['is_admin'] as bool? ?? false,
        plan: json['plan'] as String? ?? 'free',
        subscriptionStatus: json['subscription_status'] as String? ?? 'active',
        trialEndsAt: _parseDate(json['trial_ends_at']),
        emailVerified: json['email_verified'] as bool? ?? true,
        emailNotificationsEnabled: json['email_notifications_enabled'] as bool? ?? true,
        createdAt: _parseDate(json['created_at']) ?? DateTime.now(),
      );

  final String id;
  final String email;
  final String? displayName;
  final bool isActive;
  final bool isAdmin;

  /// `free` | `individual` | `pro`
  final String plan;

  /// `active` | `trialing` | `past_due` | `canceled` | ...
  final String subscriptionStatus;
  final DateTime? trialEndsAt;
  final bool emailVerified;
  final bool emailNotificationsEnabled;
  final DateTime createdAt;

  bool get isTrialing => subscriptionStatus == 'trialing';

  String get label => (displayName?.trim().isNotEmpty ?? false) ? displayName!.trim() : email;
}

DateTime? _parseDate(Object? value) => value is String ? DateTime.tryParse(value)?.toLocal() : null;
