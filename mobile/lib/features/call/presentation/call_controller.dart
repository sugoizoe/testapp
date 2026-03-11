import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

final callControllerProvider =
    StateNotifierProvider<CallController, CallState>((ref) {
  // Varsayılan: 5 dakikalık görüşme
  return CallController(initialDuration: const Duration(minutes: 5));
});

class CallState {
  final Duration remaining;
  final bool isMuted;
  final bool isCameraOff;
  final bool ended;

  const CallState({
    required this.remaining,
    required this.isMuted,
    required this.isCameraOff,
    required this.ended,
  });

  CallState copyWith({
    Duration? remaining,
    bool? isMuted,
    bool? isCameraOff,
    bool? ended,
  }) {
    return CallState(
      remaining: remaining ?? this.remaining,
      isMuted: isMuted ?? this.isMuted,
      isCameraOff: isCameraOff ?? this.isCameraOff,
      ended: ended ?? this.ended,
    );
  }
}

class CallController extends StateNotifier<CallState> {
  CallController({required Duration initialDuration})
      : _initialDuration = initialDuration,
        super(CallState(
          remaining: initialDuration,
          isMuted: false,
          isCameraOff: false,
          ended: false,
        )) {
    _startTimer();
  }

  final Duration _initialDuration;
  Timer? _timer;

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.ended) {
        timer.cancel();
        return;
      }
      final remainingSeconds = state.remaining.inSeconds - 1;
      if (remainingSeconds <= 0) {
        state = state.copyWith(
          remaining: Duration.zero,
          ended: true,
        );
        timer.cancel();
      } else {
        state = state.copyWith(
          remaining: Duration(seconds: remainingSeconds),
        );
      }
    });
  }

  void toggleMute() {
    state = state.copyWith(isMuted: !state.isMuted);
  }

  void toggleCamera() {
    state = state.copyWith(isCameraOff: !state.isCameraOff);
  }

  void endCall() {
    _timer?.cancel();
    state = state.copyWith(remaining: Duration.zero, ended: true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

