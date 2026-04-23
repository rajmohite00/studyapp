import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/session_model.dart';
import '../services/session_service.dart';

enum SessionStatus { idle, active, paused, ended }

class SessionState {
  final SessionModel? currentSession;
  final SessionStatus status;
  final Duration elapsed;
  final int interruptions;
  final bool isLoading;
  final String? error;

  const SessionState({
    this.currentSession,
    this.status = SessionStatus.idle,
    this.elapsed = Duration.zero,
    this.interruptions = 0,
    this.isLoading = false,
    this.error,
  });

  SessionState copyWith({
    SessionModel? currentSession,
    SessionStatus? status,
    Duration? elapsed,
    int? interruptions,
    bool? isLoading,
    String? error,
  }) =>
      SessionState(
        currentSession: currentSession ?? this.currentSession,
        status: status ?? this.status,
        elapsed: elapsed ?? this.elapsed,
        interruptions: interruptions ?? this.interruptions,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

class SessionNotifier extends StateNotifier<SessionState> {
  final SessionService _service;
  Timer? _timer;

  SessionNotifier(this._service) : super(const SessionState());

  Future<void> startSession({
    required String subject,
    String? topic,
    String mode = 'custom',
    int durationMinutes = 25,
    String? goal,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      final session = await _service.startSession(
        subject: subject,
        topic: topic,
        mode: mode,
        plannedDurationMinutes: durationMinutes,
        goal: goal,
      );
      state = SessionState(
        currentSession: session,
        status: SessionStatus.active,
        elapsed: Duration.zero,
      );
      _startTimer();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to start session');
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.status == SessionStatus.active) {
        state = state.copyWith(elapsed: state.elapsed + const Duration(seconds: 1));
      }
    });
  }

  Future<void> pauseSession() async {
    final id = state.currentSession?.id;
    if (id == null) return;
    _timer?.cancel();
    final session = await _service.updateSession(id, action: 'pause');
    state = state.copyWith(currentSession: session, status: SessionStatus.paused);
  }

  Future<void> resumeSession() async {
    final id = state.currentSession?.id;
    if (id == null) return;
    final session = await _service.updateSession(id, action: 'resume');
    state = state.copyWith(currentSession: session, status: SessionStatus.active);
    _startTimer();
  }

  Future<void> updateSubject(String subject) async {
    final id = state.currentSession?.id;
    if (id == null) return;
    final session = await _service.updateSession(id, subject: subject);
    state = state.copyWith(currentSession: session);
  }

  Future<SessionModel?> endSession({String? notes, int? rating, bool? goalCompleted}) async {
    final id = state.currentSession?.id;
    if (id == null) return null;
    _timer?.cancel();
    final session = await _service.updateSession(
      id,
      action: 'end',
      interruptions: state.interruptions,
      notes: notes,
      rating: rating,
      goalCompleted: goalCompleted,
    );
    state = const SessionState();
    return session;
  }

  void recordInterruption() {
    state = state.copyWith(interruptions: state.interruptions + 1);
  }

  void reset() {
    _timer?.cancel();
    state = const SessionState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final sessionServiceProvider = Provider((_) => SessionService());

final sessionProvider = StateNotifierProvider<SessionNotifier, SessionState>(
  (ref) => SessionNotifier(ref.read(sessionServiceProvider)),
);

final sessionHistoryProvider = FutureProvider.autoDispose<List<SessionModel>>((ref) async {
  final service = ref.read(sessionServiceProvider);
  final result = await service.getSessions();
  return result['sessions'] as List<SessionModel>;
});
