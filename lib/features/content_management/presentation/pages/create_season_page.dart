import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/widgets/loading/app_skeleton.dart';
import '../providers/content_provider.dart';
import '../../domain/entities/season.dart';
import 'package:uuid/uuid.dart';

class CreateSeasonPage extends ConsumerStatefulWidget {
  final String showId;
  final VoidCallback onNext;

  const CreateSeasonPage({super.key, required this.showId, required this.onNext});

  @override
  _CreateSeasonPageState createState() => _CreateSeasonPageState();
}

class _CreateSeasonPageState extends ConsumerState<CreateSeasonPage> {
  final _formKey = GlobalKey<FormState>();
  final _seasonTitleController = TextEditingController();
  final _seasonNumberController = TextEditingController();
  final _totalEpisodesController = TextEditingController();
  final _releaseFrequencyController = TextEditingController();
  final _startDateController = TextEditingController();
  DateTime? _selectedStartDate;
  bool _isSubmitting = false;

  Future<void> addSeason() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
      });

      final seasonNumber = int.parse(_seasonNumberController.text);
      final totalEpisodes = int.parse(_totalEpisodesController.text);
      final releaseFrequency = _releaseFrequencyController.text;
      final startDate = _selectedStartDate!;
      final addSeason = ref.read(contentNotifierProvider.notifier).addSeason;
      final season = Season(
        seasonId: Uuid().v4(),
        showId: widget.showId,
        seasonNumber: seasonNumber,
        totalEpisodes: totalEpisodes,
        releaseFrequency: releaseFrequency,
        startDate: startDate,
      );

      print('Adding season: ${season.toJson()}'); // Debugging-Log
      await addSeason(season);
      widget.onNext();

      setState(() {
        _isSubmitting = false;
      });
    }
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedStartDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedStartDate) {
      setState(() {
        _selectedStartDate = picked;
        _startDateController.text = "${picked.toLocal()}".split(' ')[0];
      });
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
            controller: _seasonTitleController,
            decoration: const InputDecoration(labelText: 'Season Title'),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a season title';
              }
              return null;
            },
          ),
          TextFormField(
            controller: _seasonNumberController,
            decoration: const InputDecoration(labelText: 'Season Number'),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a season number';
              }
              if (int.tryParse(value) == null) {
                return 'Please enter a valid number';
              }
              return null;
            },
          ),
          TextFormField(
            controller: _totalEpisodesController,
            decoration: const InputDecoration(labelText: 'Total Episodes'),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter the total episodes';
              }
              if (int.tryParse(value) == null) {
                return 'Please enter a valid number';
              }
              return null;
            },
          ),
          DropdownButtonFormField<String>(
            initialValue: _releaseFrequencyController.text.isEmpty ? null : _releaseFrequencyController.text,
            decoration: const InputDecoration(labelText: 'Release Frequency'),
            items: ['daily', 'weekly', 'monthly', 'onetime']
                .map((label) => DropdownMenuItem(
                      value: label,
                      child: Text(label),
                    ))
                .toList(),
            onChanged: (value) {
              setState(() {
                _releaseFrequencyController.text = value!;
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select a release frequency';
              }
              return null;
            },
          ),
          TextFormField(
            controller: _startDateController,
            decoration: const InputDecoration(labelText: 'Start Date (YYYY-MM-DD)'),
            readOnly: true,
            onTap: () => _selectStartDate(context),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select a start date';
              }
              return null;
            },
          ),
          ElevatedButton(
            onPressed: _isSubmitting ? null : () async {
              await addSeason();
            },
            child: _isSubmitting
                ? const AppSkeletonBox(width: 92, height: 14)
                : const Text('Add Season'),
          ),
        ],
      ),
    );
  }
}