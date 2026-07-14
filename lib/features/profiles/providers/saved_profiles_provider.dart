import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/saved_profile.dart';
import '../services/saved_profiles_service.dart';

/// Single source of truth untuk profil-profil yang tersimpan di device.
///
/// Menggantikan pattern _isLoading + _profiles + setState di SavedProfilesScreen
/// dengan AsyncNotifier yang handle loading state secara otomatis.
///
/// Usage:
/// ```dart
/// // Read state
/// final profilesAsync = ref.watch(savedProfilesProvider);
///
/// // Mutate
/// ref.read(savedProfilesProvider.notifier).add(profile);
/// ref.read(savedProfilesProvider.notifier).remove(profileId);
/// ```
class SavedProfilesNotifier extends AsyncNotifier<List<SavedProfile>> {
  @override
  Future<List<SavedProfile>> build() => SavedProfilesService.load();

  /// Simpan profil baru dan refresh state.
  Future<void> add(SavedProfile profile) async {
    await SavedProfilesService.save(profile);
    state = AsyncData(await SavedProfilesService.load());
  }

  /// Hapus profil berdasarkan id dan refresh state.
  Future<void> remove(String id) async {
    // Optimistic update — langsung hapus dari UI
    final current = state.value ?? [];
    state = AsyncData(current.where((p) => p.id != id).toList());

    // Persist deletion
    await SavedProfilesService.delete(id);
  }

  /// Reload dari SharedPreferences (pull-to-refresh, dll).
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await SavedProfilesService.load());
  }
}

final savedProfilesProvider =
    AsyncNotifierProvider<SavedProfilesNotifier, List<SavedProfile>>(
      SavedProfilesNotifier.new,
    );
