import 'package:flutter_riverpod/flutter_riverpod.dart';

enum SetupStatus {
  initial,
  settingUp,
  setupComplete,
  error,
}

class SetupState {
  final SetupStatus status;
  final String message;

  SetupState({this.status = SetupStatus.initial, this.message = ''});

  SetupState copyWith({SetupStatus? status, String? message}) {
    return SetupState(
      status: status ?? this.status,
      message: message ?? this.message,
    );
  }
}

final setupProvider = StateNotifierProvider<SetupNotifier, SetupState>((ref) {
  return SetupNotifier();
});

class SetupNotifier extends StateNotifier<SetupState> {
  SetupNotifier() : super(SetupState());

  void updateMessage(String message) {
    state = state.copyWith(message: message);
  }

  void setStatus(SetupStatus status) {
    state = state.copyWith(status: status);
  }
}
