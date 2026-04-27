import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/flashcard_service.dart';
import '../models/flashcard_model.dart';

class FlashcardState {
  final List<Flashcard> dueCards;
  final bool isLoading;
  final String? error;

  const FlashcardState({
    this.dueCards = const [],
    this.isLoading = false,
    this.error,
  });

  FlashcardState copyWith({
    List<Flashcard>? dueCards,
    bool? isLoading,
    String? error,
  }) {
    return FlashcardState(
      dueCards: dueCards ?? this.dueCards,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class FlashcardNotifier extends StateNotifier<FlashcardState> {
  final FlashcardService _service;

  FlashcardNotifier(this._service) : super(const FlashcardState()) {
    loadDueCards();
  }

  Future<void> loadDueCards() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final cards = await _service.getDueFlashcards();
      state = state.copyWith(dueCards: cards, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to load flashcards');
    }
  }

  Future<void> reviewCard(String cardId, int quality) async {
    try {
      // Optimistically remove from due list
      state = state.copyWith(
        dueCards: state.dueCards.where((c) => c.id != cardId).toList(),
      );
      await _service.reviewFlashcard(cardId, quality);
    } catch (e) {
      // If fails, reload
      loadDueCards();
    }
  }
}

final flashcardServiceProvider = Provider((ref) => FlashcardService());

final flashcardProvider = StateNotifierProvider<FlashcardNotifier, FlashcardState>((ref) {
  return FlashcardNotifier(ref.read(flashcardServiceProvider));
});
