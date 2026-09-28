import 'package:flutter_test/flutter_test.dart';
import 'package:pagewatcher_mobile/features/auth/data/user.dart';

void main() {
  test('parses a /auth/me response', () {
    final user = User.fromJson({
      'id': '6f1c2d4e-0000-4000-8000-000000000001',
      'email': 'ada@example.com',
      'display_name': null,
      'is_active': true,
      'is_admin': false,
      'credits': 100,
      'plan': 'individual',
      'subscription_status': 'trialing',
      'trial_ends_at': '2026-10-28T12:00:00Z',
      'email_verified': false,
      'email_notifications_enabled': true,
      'created_at': '2026-09-28T12:00:00Z',
      'updated_at': '2026-09-28T12:00:00Z',
    });

    expect(user.email, 'ada@example.com');
    expect(user.plan, 'individual');
    expect(user.isTrialing, isTrue);
    expect(user.trialEndsAt?.toUtc(), DateTime.utc(2026, 10, 28, 12));
    expect(user.emailVerified, isFalse);
    expect(user.label, 'ada@example.com');
  });

  test('label prefers a non-blank display name', () {
    final user = User.fromJson({
      'id': '1',
      'email': 'ada@example.com',
      'display_name': '  Ada  ',
      'created_at': '2026-09-28T12:00:00Z',
    });
    expect(user.label, 'Ada');
    expect(user.plan, 'free');
  });
}
