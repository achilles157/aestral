import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aestral/core/providers/birth_profile_provider.dart';
import 'package:aestral/core/models/birth_profile.dart';
import 'package:aestral/features/auth/services/auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BirthProfileNotifier - Guest Mode', () {
    test('should initialize with empty profile', () async {
      final container = ProviderContainer();
      await Future.delayed(const Duration(milliseconds: 100));

      final profileAsync = container.read(birthProfileProvider);
      expect(profileAsync.hasValue, true);
      expect(profileAsync.value, isNotNull);

      final profile = profileAsync.value!;
      expect(profile.dobDate, isNull);

      container.dispose();
    });

    test('should save DOB in guest mode', () async {
      final container = ProviderContainer();
      await Future.delayed(const Duration(milliseconds: 100));
      await container.read(authProvider.notifier).signInAsGuest();

      final notifier = container.read(birthProfileProvider.notifier);
      final dob = DateTime.utc(1990, 6, 15);
      await notifier.saveDob(dob);

      final profile = container.read(birthProfileProvider).value!;
      expect(profile.dobDate, dob);
      expect(profile.weton, isNotNull);

      container.dispose();
    });

    test('should save birth hour', () async {
      final container = ProviderContainer();
      await Future.delayed(const Duration(milliseconds: 100));
      await container.read(authProvider.notifier).signInAsGuest();

      final notifier = container.read(birthProfileProvider.notifier);
      await notifier.saveBirthHour(14);

      final profile = container.read(birthProfileProvider).value!;
      expect(profile.birthHour, 14);

      container.dispose();
    });

    test('should save location', () async {
      final container = ProviderContainer();
      await Future.delayed(const Duration(milliseconds: 100));
      await container.read(authProvider.notifier).signInAsGuest();

      final notifier = container.read(birthProfileProvider.notifier);
      await notifier.saveLocation(-6.2088, 106.8456, cityName: 'Jakarta');

      final profile = container.read(birthProfileProvider).value!;
      expect(profile.latitude, -6.2088);
      expect(profile.longitude, 106.8456);
      expect(profile.cityName, 'Jakarta');

      container.dispose();
    });

    test('should save gender', () async {
      final container = ProviderContainer();
      await Future.delayed(const Duration(milliseconds: 100));
      await container.read(authProvider.notifier).signInAsGuest();

      final notifier = container.read(birthProfileProvider.notifier);
      await notifier.saveGender('male');

      final profile = container.read(birthProfileProvider).value!;
      expect(profile.gender, 'male');

      container.dispose();
    });

    test('should clear birth hour when null', () async {
      final container = ProviderContainer();
      await Future.delayed(const Duration(milliseconds: 100));
      await container.read(authProvider.notifier).signInAsGuest();

      final notifier = container.read(birthProfileProvider.notifier);
      await notifier.saveBirthHour(10);
      expect(container.read(birthProfileProvider).value!.birthHour, 10);

      await notifier.saveBirthHour(null);
      expect(container.read(birthProfileProvider).value!.birthHour, isNull);

      container.dispose();
    });

    test('should clear gender when null', () async {
      final container = ProviderContainer();
      await Future.delayed(const Duration(milliseconds: 100));
      await container.read(authProvider.notifier).signInAsGuest();

      final notifier = container.read(birthProfileProvider.notifier);
      await notifier.saveGender('female');
      expect(container.read(birthProfileProvider).value!.gender, 'female');

      await notifier.saveGender(null);
      expect(container.read(birthProfileProvider).value!.gender, isNull);

      container.dispose();
    });
  });

  group('BirthProfileNotifier.saveAll', () {
    test('should save all fields at once', () async {
      final container = ProviderContainer();
      await Future.delayed(const Duration(milliseconds: 100));
      await container.read(authProvider.notifier).signInAsGuest();

      final notifier = container.read(birthProfileProvider.notifier);
      final dob = DateTime.utc(1995, 3, 20);

      await notifier.saveAll(
        dob: dob,
        birthHour: 15,
        latitude: -7.7956,
        longitude: 110.3695,
        cityName: 'Yogyakarta',
        gender: 'female',
      );

      final profile = container.read(birthProfileProvider).value!;
      expect(profile.dobDate, dob);
      expect(profile.birthHour, 15);
      expect(profile.latitude, -7.7956);
      expect(profile.longitude, 110.3695);
      expect(profile.cityName, 'Yogyakarta');
      expect(profile.gender, 'female');
      expect(profile.weton, isNotNull);

      container.dispose();
    });

    test('should handle partial fields in saveAll', () async {
      final container = ProviderContainer();
      await Future.delayed(const Duration(milliseconds: 100));
      await container.read(authProvider.notifier).signInAsGuest();

      final notifier = container.read(birthProfileProvider.notifier);
      final dob = DateTime.utc(2000, 1, 1);
      await notifier.saveAll(dob: dob);

      final profile = container.read(birthProfileProvider).value!;
      expect(profile.dobDate, dob);
      expect(profile.birthHour, isNull);
      expect(profile.latitude, isNull);

      container.dispose();
    });
  });

  group('BirthProfileNotifier - Weton Calculation', () {
    test('should calculate weton when saving DOB', () async {
      final container = ProviderContainer();
      await Future.delayed(const Duration(milliseconds: 100));
      await container.read(authProvider.notifier).signInAsGuest();

      final notifier = container.read(birthProfileProvider.notifier);
      final dob = DateTime.utc(1990, 1, 1);
      await notifier.saveDob(dob);

      final profile = container.read(birthProfileProvider).value!;
      expect(profile.weton, isNotNull);
      expect(profile.weton!.saptawara, 'Senin');
      expect(profile.weton!.pancawara, 'Wage');
      expect(profile.weton!.totalNeptu, 8);

      container.dispose();
    });

    test('should recalculate weton when DOB changes', () async {
      final container = ProviderContainer();
      await Future.delayed(const Duration(milliseconds: 100));
      await container.read(authProvider.notifier).signInAsGuest();

      final notifier = container.read(birthProfileProvider.notifier);
      await notifier.saveDob(DateTime.utc(1990, 1, 1));
      final weton1 = container.read(birthProfileProvider).value!.weton!;

      await notifier.saveDob(DateTime.utc(2000, 1, 1));
      final weton2 = container.read(birthProfileProvider).value!.weton!;

      expect(weton1.saptawara, isNot(weton2.saptawara));

      container.dispose();
    });
  });

  group('BirthProfileNotifier - State Persistence', () {
    test('should persist data across provider reads', () async {
      final container = ProviderContainer();
      await Future.delayed(const Duration(milliseconds: 100));
      await container.read(authProvider.notifier).signInAsGuest();

      final notifier = container.read(birthProfileProvider.notifier);
      await notifier.saveDob(DateTime.utc(1995, 5, 10));
      await notifier.saveBirthHour(8);

      final profile1 = container.read(birthProfileProvider).value!;
      final profile2 = container.read(birthProfileProvider).value!;

      expect(profile1.dobDate, profile2.dobDate);
      expect(profile1.birthHour, profile2.birthHour);

      container.dispose();
    });

    test('should maintain data integrity after multiple updates', () async {
      final container = ProviderContainer();
      await Future.delayed(const Duration(milliseconds: 100));
      await container.read(authProvider.notifier).signInAsGuest();

      final notifier = container.read(birthProfileProvider.notifier);
      await notifier.saveDob(DateTime.utc(1990, 1, 1));
      await notifier.saveBirthHour(10);
      await notifier.saveLocation(-6.2, 106.8);
      await notifier.saveGender('male');

      final profile = container.read(birthProfileProvider).value!;
      expect(profile.dobDate, isNotNull);
      expect(profile.birthHour, 10);
      expect(profile.latitude, -6.2);
      expect(profile.gender, 'male');

      container.dispose();
    });
  });

  group('BirthProfile Model', () {
    test('should create empty profile', () {
      const profile = BirthProfile();
      expect(profile.dobDate, isNull);
      expect(profile.birthHour, isNull);
      expect(profile.weton, isNull);
    });

    test('should create profile with copyWith', () {
      const profile1 = BirthProfile();
      final dob = DateTime.utc(2000, 1, 1);
      final profile2 = profile1.copyWith(dobDate: dob, birthHour: 12);

      expect(profile2.dobDate, dob);
      expect(profile2.birthHour, 12);
      expect(profile2.latitude, isNull);
    });
  });
}
