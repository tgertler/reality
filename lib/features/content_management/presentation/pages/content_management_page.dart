import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'create_show_page.dart';
import 'create_season_page.dart';
import 'add_attendee_page.dart';
import '../providers/stepper_provider.dart';

class ContentManagementPage extends ConsumerWidget {
  const ContentManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stepperState = ref.watch(stepperProvider);
    final stepperNotifier = ref.read(stepperProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Content Management'),
      ),
      body: Stepper(
        currentStep: stepperState.currentStep,
        onStepContinue: () {
          if (stepperState.currentStep == 0 && stepperState.showId == null) {
            // Show an error message if showId is null
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Please create a show first')),
            );
          } else {
            stepperNotifier.nextStep();
          }
        },
        onStepCancel: stepperNotifier.previousStep,
        steps: [
          Step(
            title: const Text('Create Show'),
            content: CreateShowPage(onNext: (showId) {
              stepperNotifier.setShowId(showId);
              stepperNotifier.nextStep();
            }),
            isActive: stepperState.currentStep == 0,
          ),
          Step(
            title: const Text('Create Season'),
            content: stepperState.showId != null
                ? CreateSeasonPage(showId: stepperState.showId!, onNext: stepperNotifier.nextStep)
                : Center(child: Text('Please create a show first')),
            isActive: stepperState.currentStep == 1,
          ),
          Step(
            title: const Text('Add Attendee'),
            content: AddAttendeePage(onNext: stepperNotifier.nextStep),
            isActive: stepperState.currentStep == 2,
          ),
        ],
      ),
    );
  }
}