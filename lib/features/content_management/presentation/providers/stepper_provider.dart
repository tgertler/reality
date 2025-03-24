import 'package:flutter_riverpod/flutter_riverpod.dart';

class StepperState {
  final int currentStep;
  final String? showId;

  StepperState({this.currentStep = 0, this.showId});

  StepperState copyWith({int? currentStep, String? showId}) {
    return StepperState(
      currentStep: currentStep ?? this.currentStep,
      showId: showId ?? this.showId,
    );
  }
}

class StepperNotifier extends StateNotifier<StepperState> {
  StepperNotifier() : super(StepperState());

  void nextStep() {
    if (state.currentStep < 2) {
      state = state.copyWith(currentStep: state.currentStep + 1);
    }
  }

  void previousStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  void setShowId(String showId) {
    state = state.copyWith(showId: showId);
  }
}

final stepperProvider = StateNotifierProvider<StepperNotifier, StepperState>((ref) {
  return StepperNotifier();
});