import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/widgets/loading/app_skeleton.dart';
import '../providers/content_provider.dart';
import '../../domain/entities/show.dart';

class CreateShowPage extends ConsumerStatefulWidget {
  final Function(String) onNext;

  const CreateShowPage({super.key, required this.onNext});

  @override
  _CreateShowPageState createState() => _CreateShowPageState();
}

class _CreateShowPageState extends ConsumerState<CreateShowPage> {
  final _formKey = GlobalKey<FormState>();
  final _showTitleController = TextEditingController();
  final _showShortTitleController = TextEditingController();

  Future<void> addShow() async {
    if (_formKey.currentState!.validate()) {
      final title = _showTitleController.text;
      final shortTitle = _showShortTitleController.text.trim();
      final addShow = ref.read(contentNotifierProvider.notifier).addShow;
      final show = Show.withRandomId(
        title: title,
        shortTitle: shortTitle.isEmpty ? null : shortTitle,
      );
      await addShow(show);
      widget.onNext(show.showId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final contentState = ref.watch(contentNotifierProvider);

    return Form(
      key: _formKey,
      child: Column(
        children: [
          if (contentState.isLoading)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: AppSkeletonBox(width: double.infinity, height: 10),
            ),
          if (contentState.errorMessage.isNotEmpty)
            Text('Error: ${contentState.errorMessage}', style: TextStyle(color: Colors.red)),
          TextFormField(
            controller: _showTitleController,
            decoration: const InputDecoration(labelText: 'Show Title'),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a show title';
              }
              return null;
            },
          ),
          TextFormField(
            controller: _showShortTitleController,
            decoration: const InputDecoration(
              labelText: 'Short Title (optional)',
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              await addShow();
            },
            child: const Text('Add Show'),
          ),
        ],
      ),
    );
  }
}