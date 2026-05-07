import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/show_management/show_discovery/presentation/providers/attendee_overview_provider.dart';
import 'package:frontend/features/show_management/show_discovery/presentation/widgets/attendee_overview_title_widget.dart';

class AttendeeOverviewPage extends ConsumerStatefulWidget {
  final String attendeeId;

  const AttendeeOverviewPage({super.key, required this.attendeeId});

  @override
  _ShowOverviewPageState createState() => _ShowOverviewPageState();
}

class _ShowOverviewPageState extends ConsumerState<AttendeeOverviewPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(attendeeOverviewProvider.notifier).loadAttendee(widget.attendeeId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final attendee = ref.watch(attendeeOverviewProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Column(
        children: [
            AttendeeOverviewTitleWidget(name: attendee.name, attendeeId: widget.attendeeId),
            attendee.bio.isNotEmpty
            ? Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(attendee.bio),
              )
            : Container(),

        ],
      ),
    );
  }
}
