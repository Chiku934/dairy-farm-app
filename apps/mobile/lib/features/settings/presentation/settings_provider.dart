import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/settings_repository.dart';
import '../domain/settings_models.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository();
});

final farmSettingsProvider = FutureProvider<FarmSettingsModel>((ref) async {
  final repo = ref.watch(settingsRepositoryProvider);
  return repo.fetchSettings();
});
