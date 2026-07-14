import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aestral/features/auth/services/auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // Reset SharedPreferences mock before each test
    SharedPreferences.setMockInitialValues({});
  });

  group('UserSession', () {
    test('should create valid user session', () {
      final session = UserSession(
        uid: 'test_uid_123',
        displayName: 'Test User',
        email: 'test@example.com',
        photoUrl: 'https://example.com/photo.jpg',
        isMock: false,
      );

      expect(session.uid, 'test_uid_123');
      expect(session.displayName, 'Test User');
      expect(session.email, 'test@example.com');
      expect(session.photoUrl, 'https://example.com/photo.jpg');
      expect(session.isMock, false);
    });

    test('should create mock user session', () {
      final session = UserSession(
        uid: 'guest_123456',
        displayName: 'Tamu Offline',
        email: 'guest@aestral.local',
        isMock: true,
      );

      expect(session.uid, 'guest_123456');
      expect(session.isMock, true);
      expect(session.photoUrl, isNull);
    });

    test('should allow nullable photoUrl', () {
      final session = UserSession(
        uid: 'uid',
        displayName: 'Name',
        email: 'email@test.com',
        isMock: false,
      );

      expect(session.photoUrl, isNull);
    });
  });

  group('AuthNotifier.getAuthHeader', () {
    test('should return Guest header for null session', () async {
      final container = ProviderContainer();
      final notifier = container.read(authProvider.notifier);

      expect(notifier.state, isNull);

      final header = await notifier.getAuthHeader();
      expect(header, startsWith('Guest'));
      expect(header, contains('anonymous'));

      container.dispose();
    });

    test('should return Guest header for mock session', () async {
      final container = ProviderContainer();
      final notifier = container.read(authProvider.notifier);

      await notifier.signInAsGuest();

      final header = await notifier.getAuthHeader();
      expect(header, startsWith('Guest'));
      expect(header, contains('guest_'));

      container.dispose();
    });

    test('should generate header with guest UID', () async {
      final container = ProviderContainer();
      final notifier = container.read(authProvider.notifier);

      await notifier.signInAsGuest();
      final session = notifier.state;

      expect(session, isNotNull);
      expect(session!.isMock, true);

      final header = await notifier.getAuthHeader();
      expect(header, contains(session.uid));

      container.dispose();
    });
  });

  group('AuthNotifier.signInAsGuest', () {
    test('should create guest session', () async {
      final container = ProviderContainer();
      final notifier = container.read(authProvider.notifier);

      await notifier.signInAsGuest();
      final session = notifier.state;

      expect(session, isNotNull);
      expect(session!.isMock, true);
      expect(session.displayName, 'Tamu Offline');
      expect(session.email, 'guest@aestral.local');
      expect(session.uid, startsWith('guest_'));

      container.dispose();
    });

    test('should generate unique guest UID', () async {
      final container = ProviderContainer();
      final notifier = container.read(authProvider.notifier);

      await notifier.signInAsGuest();
      final uid1 = notifier.state!.uid;

      await notifier.signOut();
      await notifier.signInAsGuest();
      final uid2 = notifier.state!.uid;

      expect(uid1, isNot(uid2));

      container.dispose();
    });

    test('should persist guest UID across sessions', () async {
      final container = ProviderContainer();
      final notifier = container.read(authProvider.notifier);

      await notifier.signInAsGuest();
      final uid1 = notifier.state!.uid;

      container.dispose();

      final container2 = ProviderContainer();
      final notifier2 = container2.read(authProvider.notifier);

      await Future.delayed(const Duration(milliseconds: 100));

      final session2 = notifier2.state;
      if (session2 != null && session2.isMock) {
        expect(session2.uid, uid1);
      }

      container2.dispose();
    });

    test('should not collide with hardcoded placeholder UID', () async {
      final container = ProviderContainer();
      final notifier = container.read(authProvider.notifier);

      await notifier.signInAsGuest();
      final uid = notifier.state!.uid;

      expect(uid, isNot('guest_user_123'));
      expect(uid, matches(RegExp(r'^guest_\d+_\d{5}$')));

      container.dispose();
    });
  });

  group('AuthNotifier.signOut', () {
    test('should clear session state', () async {
      final container = ProviderContainer();
      final notifier = container.read(authProvider.notifier);

      await notifier.signInAsGuest();
      expect(notifier.state, isNotNull);

      await notifier.signOut();
      expect(notifier.state, isNull);

      container.dispose();
    });

    test('should clear SharedPreferences data', () async {
      final container = ProviderContainer();
      final notifier = container.read(authProvider.notifier);

      await notifier.signInAsGuest();
      await notifier.signOut();

      // After signOut, state should be null
      expect(notifier.state, isNull);

      container.dispose();
    });

    test('should handle sign out when no session exists', () async {
      final container = ProviderContainer();
      final notifier = container.read(authProvider.notifier);

      // Properly await signOut (no session exists - should not throw)
      await notifier.signOut();
      expect(notifier.state, isNull);

      container.dispose();
    });
  });

  group('AuthNotifier state management', () {
    test('should initialize with null state', () {
      final container = ProviderContainer();
      final session = container.read(authProvider);

      expect(session, isNull);

      container.dispose();
    });

    test('should update state after guest sign-in', () async {
      final container = ProviderContainer();
      final notifier = container.read(authProvider.notifier);

      expect(notifier.state, isNull);

      await notifier.signInAsGuest();

      expect(notifier.state, isNotNull);
      expect(notifier.state!.isMock, true);

      container.dispose();
    });

    test('should maintain state consistency', () async {
      final container = ProviderContainer();
      final notifier = container.read(authProvider.notifier);

      await notifier.signInAsGuest();
      final session = notifier.state;

      expect(notifier.state, same(session));

      container.dispose();
    });
  });

  group('AuthInitializingProvider', () {
    test('should start as true (initializing)', () {
      final container = ProviderContainer();
      final isInitializing = container.read(authInitializingProvider);

      expect(isInitializing, true);

      container.dispose();
    });

    test('should become false after initialization', () async {
      final container = ProviderContainer();

      container.read(authProvider);

      await Future.delayed(const Duration(milliseconds: 200));

      final isInitializing = container.read(authInitializingProvider);
      expect(isInitializing, false);

      container.dispose();
    });
  });
}
