import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/widgets/loading/app_skeleton.dart';
import '../providers/content_provider.dart';
import '../../domain/entities/attendee.dart';
import 'package:uuid/uuid.dart';

class AddAttendeePage extends ConsumerStatefulWidget {
  final VoidCallback onNext;

  const AddAttendeePage({super.key, required this.onNext});

  @override
  _AddAttendeePageState createState() => _AddAttendeePageState();
}

class _AddAttendeePageState extends ConsumerState<AddAttendeePage> {
  final _attendeeNameController = TextEditingController();

  Future<void> addAttendee() async {
    final name = _attendeeNameController.text;
    final addAttendee = ref.read(contentNotifierProvider.notifier).addAttendee;
    await addAttendee(Attendee(attendeeId: Uuid().v4(), name: name));
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    final contentState = ref.watch(contentNotifierProvider);

    return Column(
      children: [
        if (contentState.isLoading)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: AppSkeletonBox(width: double.infinity, height: 10),
          ),
        if (contentState.errorMessage.isNotEmpty)
          Text('Error: ${contentState.errorMessage}', style: TextStyle(color: Colors.red)),
        TextField(
          controller: _attendeeNameController,
          decoration: const InputDecoration(labelText: 'Attendee Name'),
        ),
        ElevatedButton(
          onPressed: () async {
            await addAttendee();
          },
          child: const Text('Add Attendee'),
        ),
      ],
    );
  }
}