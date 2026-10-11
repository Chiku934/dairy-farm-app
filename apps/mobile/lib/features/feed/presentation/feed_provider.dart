import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/feed_repository.dart';
import '../domain/feed_models.dart';

final feedRepositoryProvider = Provider<FeedRepository>((ref) {
  return FeedRepository();
});

class FeedFilterState {
  final String? date;
  final FeedType? feedType;
  final String? search;

  const FeedFilterState({
    this.date,
    this.feedType,
    this.search,
  });

  FeedFilterState copyWith({
    String? date,
    FeedType? feedType,
    String? search,
    bool clearDate = false,
    bool clearFeedType = false,
  }) {
    return FeedFilterState(
      date: clearDate ? null : (date ?? this.date),
      feedType: clearFeedType ? null : (feedType ?? this.feedType),
      search: search ?? this.search,
    );
  }
}

class FeedFilterNotifier extends Notifier<FeedFilterState> {
  @override
  FeedFilterState build() => const FeedFilterState();

  void setDate(String? date) => state = state.copyWith(date: date, clearDate: date == null);
  void setFeedType(FeedType? type) => state = state.copyWith(feedType: type, clearFeedType: type == null);
  void setSearch(String search) => state = state.copyWith(search: search);
  void reset() => state = const FeedFilterState();
}

final feedFilterProvider =
    NotifierProvider<FeedFilterNotifier, FeedFilterState>(FeedFilterNotifier.new);

final feedEntriesProvider = FutureProvider<({List<FeedEntryModel> items, int total, int totalPages})>((ref) async {
  final repo = ref.watch(feedRepositoryProvider);
  final filter = ref.watch(feedFilterProvider);

  return repo.fetchFeedEntries(
    date: filter.date,
    feedType: filter.feedType,
    search: filter.search,
  );
});

final rationsProvider = FutureProvider<List<RationDefinitionModel>>((ref) async {
  final repo = ref.watch(feedRepositoryProvider);
  return repo.fetchRations();
});

final concentrateTargetProvider = FutureProvider.family<ConcentrateTargetModel, String>((ref, animalId) async {
  final repo = ref.watch(feedRepositoryProvider);
  return repo.calculateConcentrateTarget(animalId);
});
