import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/config/app_colors.dart';
import 'package:frontend/features/content_management/domain/entities/season.dart';
import 'package:frontend/features/content_management/domain/entities/show.dart';
import 'package:frontend/features/content_management/presentation/providers/content_provider.dart';
import 'package:frontend/features/content_management/presentation/widgets/cms_admin_card.dart';
import 'package:frontend/features/content_management/presentation/widgets/cms_form_fields.dart';
import 'package:frontend/features/content_management/presentation/widgets/cms_search_sort_bar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';

enum _CmsSection { shows, creators, trash, feed }

enum _ShowsActionMode { createShow, createSeason }

enum _CreatorActionMode { createCreator, blockEvents, createEvent }

enum _ShowsSubPage { shows, seasons, showEvents, calendarEvents, actions }

enum _CreatorsSubPage { creators, creatorEvents, actions }

enum _TrashSubPage { trashEvents, actions }

enum _FeedSubPage { overview, actions, newsTicker }

enum _FeedActionMode { quoteOfWeek, throwback }

class _PrimaryActionConfig {
  final String label;
  final Future<void> Function() onPressed;

  const _PrimaryActionConfig({
    required this.label,
    required this.onPressed,
  });
}

class ContentManagementPage extends ConsumerStatefulWidget {
  const ContentManagementPage({super.key});

  @override
  ConsumerState<ContentManagementPage> createState() =>
      _ContentManagementPageState();
}

class _ContentManagementPageState extends ConsumerState<ContentManagementPage> {
  _CmsSection _currentSection = _CmsSection.shows;
  _ShowsActionMode _showsActionMode = _ShowsActionMode.createShow;
  _CreatorActionMode _creatorActionMode = _CreatorActionMode.createCreator;
  _ShowsSubPage _showsSubPage = _ShowsSubPage.shows;
  _CreatorsSubPage _creatorsSubPage = _CreatorsSubPage.creators;
  _TrashSubPage _trashSubPage = _TrashSubPage.trashEvents;
  _FeedSubPage _feedSubPage = _FeedSubPage.overview;
  _FeedActionMode _feedActionMode = _FeedActionMode.quoteOfWeek;
  String? _inlineFormError;

  String _showTableSearchQuery = '';
  String _seasonTableSearchQuery = '';
  String _showEventsTableSearchQuery = '';
  String _calendarEventsTableSearchQuery = '';
  String _creatorTableSearchQuery = '';
  String _creatorEventsTableSearchQuery = '';
  String _trashEventsTableSearchQuery = '';
  String _feedItemsSearchQuery = '';
  String _newsTickerItemsSearchQuery = '';
  String? _selectedShowTableId;
  String? _selectedSeasonTableId;
  String? _selectedShowEventTableId;
  String? _selectedCreatorTableId;

  String _showsSortKey = 'updated_at';
  bool _showsSortAsc = false;
  String _seasonsSortKey = 'streaming_release_date';
  bool _seasonsSortAsc = true;
  String _showEventsSortKey = 'created_at';
  bool _showEventsSortAsc = false;
  String _calendarEventsSortKey = 'start_datetime';
  bool _calendarEventsSortAsc = true;
  String _creatorsSortKey = 'name';
  bool _creatorsSortAsc = true;
  String _creatorEventsSortKey = 'created_at';
  bool _creatorEventsSortAsc = false;
  String _trashEventsSortKey = 'created_at';
  bool _trashEventsSortAsc = false;
  String _feedItemsSortKey = 'priority';
  bool _feedItemsSortAsc = true;
  String _newsTickerItemsSortKey = 'priority';
  bool _newsTickerItemsSortAsc = true;

  final _showTitleController = TextEditingController();
  final _showShortTitleController = TextEditingController();
  final _showDescriptionController = TextEditingController();
  final _showGenreController = TextEditingController();
  final _showReleaseWindowController = TextEditingController();
  final _showStatusController = TextEditingController();
  final _showSlugController = TextEditingController();
  final _showTmdbIdController = TextEditingController();
  final _showTraktSlugController = TextEditingController();
  final _showHeaderImageUrlController = TextEditingController();
  final _showMainColorController = TextEditingController();

  String? _seasonShowId;
  final _seasonNumberController = TextEditingController();
  final _seasonEpisodesController = TextEditingController();
  final _seasonReleaseTimeController = TextEditingController(text: '20:15');
  final _seasonEpisodeLengthController = TextEditingController();
  final _seasonStreamingOptionController = TextEditingController();
  final _showEventEpisodeController = TextEditingController();
  final _showEventDescriptionController = TextEditingController();
  String _seasonReleaseFrequency = 'weekly';
  String _showEventSubtype = 'episode';
  final Set<int> _seasonMultiWeeklyDays = <int>{1, 4};
  DateTime? _seasonStartDate;
  DateTime? _showEventStartDateTime;

  final _creatorNameController = TextEditingController();
  final _creatorDescriptionController = TextEditingController();
  final _creatorAvatarController = TextEditingController();
  final _creatorYoutubeController = TextEditingController();
  final _creatorInstagramController = TextEditingController();
  final _creatorTiktokController = TextEditingController();

  String? _blockCreatorId;
  String? _blockShowId;
  String? _blockSeasonId;
  String _blockEventKind = 'reaction_video';
  final _blockTitlePrefixController = TextEditingController();
  final _blockDescriptionController = TextEditingController();

  String? _detailCreatorId;
  String? _detailShowId;
  String? _detailSeasonId;
  String _detailEventKind = 'reaction_video';
  final _detailEpisodeNumberController = TextEditingController();
  final _detailTitleController = TextEditingController();
  final _detailDescriptionController = TextEditingController();
  final _detailYoutubeUrlController = TextEditingController();
  final _detailThumbnailUrlController = TextEditingController();
  DateTime? _detailDateTime;

  final _trashTitleController = TextEditingController();
  final _trashDescriptionController = TextEditingController();
  final _trashImageUrlController = TextEditingController();
  final _trashLocationController = TextEditingController();
  final _trashAddressController = TextEditingController();
  final _trashOrganizerController = TextEditingController();
  final _trashPriceController = TextEditingController();
  final _trashExternalUrlController = TextEditingController();
  String? _trashShowId;
  String? _trashSeasonId;
  DateTime? _trashDateTime;
  String _trashRepeatMode = 'none';
  final _trashOccurrencesController = TextEditingController(text: '1');
  final _trashCustomDaysController = TextEditingController(text: '7');

  final _quoteTextController = TextEditingController();
  final _quoteSpeakerController = TextEditingController();
  String? _quoteShowId;
  final _quoteSeasonController = TextEditingController();
  final _quoteEpisodeController = TextEditingController();
  final _quoteCtaController = TextEditingController(text: 'Zur Show');

  final _newsTickerHeadlineController = TextEditingController();
  bool _newsTickerIsActive = true;

  final _throwbackLabelController =
      TextEditingController(text: 'Throwback der Woche');
  final _throwbackMomentController = TextEditingController();
  String? _throwbackShowId;
  final _throwbackSeasonController = TextEditingController();
  final _throwbackEpisodeController = TextEditingController();
  final _throwbackCtaController =
      TextEditingController(text: 'Szene anschauen');
  final _throwbackStickerController = TextEditingController(text: 'OG Moment');

  List<Season> _blockSeasons = const [];
  List<Season> _detailSeasons = const [];
  List<Season> _trashSeasons = const [];

  static const _weekdayLabels = <int, String>{
    1: 'Mo',
    2: 'Di',
    3: 'Mi',
    4: 'Do',
    5: 'Fr',
    6: 'Sa',
    7: 'So',
  };

  static const _releaseFrequencyOptions = <String, String>{
    'onetime': 'onetime',
    'daily': 'daily',
    'weekly': 'weekly',
    'weekly2': 'weekly2',
    'weekly3': 'weekly3',
    'multi_weekly': 'multi_weekly',
    'biweekly': 'biweekly',
    'monthly': 'monthly',
    'premiere3_then_weekly': 'premiere3_then_weekly',
    'premiere2_then_weekly': 'premiere2_then_weekly',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final notifier = ref.read(contentNotifierProvider.notifier);
      await notifier.loadShows();
      await notifier.loadShowsTableRows();
      await notifier.loadCreators();
      await notifier.loadAllSeasons();
      await notifier.loadCreatorEvents();
      await notifier.loadTrashEvents();
      await notifier.loadFeedItems();
      await notifier.loadNewsTickerItems();
    });
  }

  @override
  void dispose() {
    _showTitleController.dispose();
    _showShortTitleController.dispose();
    _showDescriptionController.dispose();
    _showGenreController.dispose();
    _showReleaseWindowController.dispose();
    _showStatusController.dispose();
    _showSlugController.dispose();
    _showTmdbIdController.dispose();
    _showTraktSlugController.dispose();
    _showHeaderImageUrlController.dispose();
    _showMainColorController.dispose();
    _seasonNumberController.dispose();
    _seasonEpisodesController.dispose();
    _seasonReleaseTimeController.dispose();
    _seasonEpisodeLengthController.dispose();
    _seasonStreamingOptionController.dispose();
    _showEventEpisodeController.dispose();
    _showEventDescriptionController.dispose();
    _creatorNameController.dispose();
    _creatorDescriptionController.dispose();
    _creatorAvatarController.dispose();
    _creatorYoutubeController.dispose();
    _creatorInstagramController.dispose();
    _creatorTiktokController.dispose();
    _blockTitlePrefixController.dispose();
    _blockDescriptionController.dispose();
    _detailEpisodeNumberController.dispose();
    _detailTitleController.dispose();
    _detailDescriptionController.dispose();
    _detailYoutubeUrlController.dispose();
    _detailThumbnailUrlController.dispose();
    _trashTitleController.dispose();
    _trashDescriptionController.dispose();
    _trashImageUrlController.dispose();
    _trashLocationController.dispose();
    _trashAddressController.dispose();
    _trashOrganizerController.dispose();
    _trashPriceController.dispose();
    _trashExternalUrlController.dispose();
    _trashOccurrencesController.dispose();
    _trashCustomDaysController.dispose();
    _quoteTextController.dispose();
    _quoteSpeakerController.dispose();
    _quoteSeasonController.dispose();
    _quoteEpisodeController.dispose();
    _quoteCtaController.dispose();
    _newsTickerHeadlineController.dispose();
    _throwbackLabelController.dispose();
    _throwbackMomentController.dispose();
    _throwbackSeasonController.dispose();
    _throwbackEpisodeController.dispose();
    _throwbackCtaController.dispose();
    _throwbackStickerController.dispose();
    super.dispose();
  }

  Future<void> _loadBlockSeasons(String showId) async {
    final seasons = await ref
        .read(contentNotifierProvider.notifier)
        .getSeasonsByShowIdDirect(showId);
    if (mounted) {
      setState(() {
        _blockSeasons = seasons;
        _blockSeasonId = null;
      });
    }
  }

  Future<void> _loadDetailSeasons(String showId) async {
    final seasons = await ref
        .read(contentNotifierProvider.notifier)
        .getSeasonsByShowIdDirect(showId);
    if (mounted) {
      setState(() {
        _detailSeasons = seasons;
        _detailSeasonId = null;
      });
    }
  }

  Future<void> _loadTrashSeasons(String showId) async {
    final seasons = await ref
        .read(contentNotifierProvider.notifier)
        .getSeasonsByShowIdDirect(showId);
    if (mounted) {
      setState(() {
        _trashSeasons = seasons;
        _trashSeasonId = null;
      });
    }
  }

  String _buildSeasonReleaseFrequencyValue() {
    if (_seasonReleaseFrequency != 'multi_weekly') {
      return _seasonReleaseFrequency;
    }
    final sorted = _seasonMultiWeeklyDays.toList()..sort();
    return 'multi_weekly:${sorted.join(',')}';
  }

  bool _isValidTimeValue(String raw) {
    final match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(raw.trim());
    if (match == null) return false;
    final hour = int.tryParse(match.group(1)!);
    final minute = int.tryParse(match.group(2)!);
    return hour != null &&
        minute != null &&
        hour >= 0 &&
        hour < 24 &&
        minute >= 0 &&
        minute < 60;
  }

  DateTime _combineSeasonStartDateTime(DateTime date) {
    final raw = _seasonReleaseTimeController.text.trim();
    final match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(raw);
    final hour = int.tryParse(match?.group(1) ?? '') ?? 20;
    final minute = int.tryParse(match?.group(2) ?? '') ?? 15;

    return DateTime(
      date.year,
      date.month,
      date.day,
      hour.clamp(0, 23),
      minute.clamp(0, 59),
    );
  }

  String _normalizeFrequency(String value) {
    final normalized = value.trim().toLowerCase();

    if (normalized.startsWith('multi_weekly')) {
      return 'multi_weekly';
    }

    if (normalized == 'premiere3_weekly') {
      return 'premiere3_then_weekly';
    }

    if (normalized == 'premiere2_weekly') {
      return 'premiere2_then_weekly';
    }

    if (normalized == 'one_time' ||
        normalized == 'one-time' ||
        normalized == 'once') {
      return 'onetime';
    }

    if (_releaseFrequencyOptions.containsKey(normalized)) {
      return normalized;
    }

    // Legacy / unknown DB value: avoid DropdownButton assertion by falling back
    // to a valid option.
    return 'weekly';
  }

  Set<int> _parseMultiWeeklyDays(String value) {
    if (!value.startsWith('multi_weekly:')) return <int>{};
    return value
        .split(':')
        .last
        .split(',')
        .map((e) => int.tryParse(e.trim()))
        .whereType<int>()
        .where((d) => d >= 1 && d <= 7)
        .toSet();
  }

  Duration _trashSeriesInterval() {
    switch (_trashRepeatMode) {
      case 'daily':
        return const Duration(days: 1);
      case 'weekly':
        return const Duration(days: 7);
      case 'biweekly':
        return const Duration(days: 14);
      case 'monthly':
        return const Duration(days: 30);
      case 'custom_days':
        return Duration(
            days: int.tryParse(_trashCustomDaysController.text) ?? 7);
      default:
        return const Duration(days: 1);
    }
  }

  Future<bool> _confirmDelete({
    required String table,
    required String id,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'Datensatz löschen?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Der ausgewählte Eintrag wird dauerhaft gelöscht.\n\nDieser Vorgang kann nicht rückgängig gemacht werden.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
    return result == true;
  }

  Future<void> _deleteCmsRowAndRefresh({
    required String table,
    required String id,
  }) async {
    final confirm = await _confirmDelete(table: table, id: id);
    if (!confirm) return;

    final notifier = ref.read(contentNotifierProvider.notifier);
    await notifier.deleteCmsRow(table: table, id: id);

    switch (table) {
      case 'shows':
        await notifier.loadShows();
        await notifier.loadShowsTableRows();
        break;
      case 'seasons':
        await notifier.loadAllSeasons();
        if (_selectedShowTableId != null) {
          await notifier.loadSeasonsTableRowsByShowId(_selectedShowTableId!);
        }
        break;
      case 'show_events':
        if (_selectedSeasonTableId != null) {
          await notifier.loadShowEventsBySeasonId(_selectedSeasonTableId!);
        }
        if (_selectedShowEventTableId == id) {
          setState(() => _selectedShowEventTableId = null);
        }
        break;
      case 'calendar_events':
        if (_selectedShowEventTableId != null) {
          await notifier
              .loadCalendarEventsByShowEventId(_selectedShowEventTableId!);
        }
        break;
      case 'creators':
        await notifier.loadCreators();
        await notifier.loadCreatorEvents();
        break;
      case 'creator_events':
        await notifier.loadCreatorEvents();
        break;
      case 'trash_events':
        await notifier.loadTrashEvents();
        break;
      case 'feed_items':
        await notifier.loadFeedItems();
        break;
      case 'news_ticker_items':
        await notifier.loadNewsTickerItems();
        break;
      default:
        break;
    }
  }

  Future<void> _openCreateShowEventDialog() async {
    if (_selectedShowTableId == null || _selectedSeasonTableId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bitte zuerst Show und Season auswählen.'),
        ),
      );
      return;
    }

    _showEventEpisodeController.clear();
    _showEventDescriptionController.clear();
    _showEventSubtype = 'episode';
    _showEventStartDateTime = DateTime.now();

    final notifier = ref.read(contentNotifierProvider.notifier);

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1A1A1A),
              title: const Text(
                'Show Event + Calendar Event',
                style: TextStyle(color: Colors.white),
              ),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: _showEventSubtype,
                        dropdownColor: const Color(0xFF1F1F1F),
                        style: const TextStyle(color: Colors.white),
                        decoration: cmsInputDecoration('Typ'),
                        items: const [
                          DropdownMenuItem(
                              value: 'episode', child: Text('episode')),
                          DropdownMenuItem(
                              value: 'premiere', child: Text('premiere')),
                          DropdownMenuItem(
                              value: 'finale', child: Text('finale')),
                          DropdownMenuItem(
                              value: 'reunion', child: Text('reunion')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setStateDialog(() => _showEventSubtype = value);
                          }
                        },
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _showEventEpisodeController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: cmsInputDecoration('Episode'),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _showEventDescriptionController,
                        style: const TextStyle(color: Colors.white),
                        maxLines: 2,
                        decoration:
                            cmsInputDecoration('Beschreibung (optional)'),
                      ),
                      const SizedBox(height: 8),
                      CmsDateTimePickerField(
                        label: 'Startdatum + Zeit *',
                        value: _showEventStartDateTime,
                        onChanged: (value) {
                          setStateDialog(() => _showEventStartDateTime = value);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Abbrechen'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final episodeNumber =
                        int.tryParse(_showEventEpisodeController.text.trim());
                    if (episodeNumber == null ||
                        _showEventStartDateTime == null) {
                      return;
                    }

                    await notifier.addShowEventWithCalendarEvent(
                      showId: _selectedShowTableId!,
                      seasonId: _selectedSeasonTableId!,
                      eventSubtype: _showEventSubtype,
                      episodeNumber: episodeNumber,
                      description:
                          _showEventDescriptionController.text.trim().isEmpty
                              ? null
                              : _showEventDescriptionController.text.trim(),
                      startDatetime: _showEventStartDateTime!,
                    );

                    await notifier
                        .loadShowEventsBySeasonId(_selectedSeasonTableId!);
                    if (mounted) Navigator.pop(context);
                  },
                  child: const Text('Erstellen'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(contentNotifierProvider);

    ref.listen<ContentState>(contentNotifierProvider, (prev, next) {
      if (next.errorMessage.isNotEmpty &&
          next.errorMessage != prev?.errorMessage) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(next.errorMessage),
              backgroundColor: Colors.red.shade800,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 5),
            ),
          );
      }
      if (next.successMessage.isNotEmpty &&
          next.successMessage != prev?.successMessage) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(next.successMessage),
              backgroundColor: Colors.green.shade800,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
            ),
          );
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        title: Text(
          'Content Management',
          style: GoogleFonts.montserrat(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
      ),
      body: ListTileTheme(
        data: const ListTileThemeData(
          visualDensity: VisualDensity.compact,
          shape: Border(
            bottom: BorderSide(
              color: Color(0x26FFFFFF),
              width: 0.7,
            ),
          ),
        ),
        child: Column(
          children: [
            if (state.isLoading) const LinearProgressIndicator(minHeight: 2),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth > 1000) {
                    return Row(
                      children: [
                        NavigationRail(
                          backgroundColor: const Color(0xFF141922),
                          selectedLabelTextStyle: GoogleFonts.montserrat(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                          unselectedLabelTextStyle: GoogleFonts.dmSans(
                            color: Colors.white70,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                          selectedIconTheme:
                              const IconThemeData(color: Color(0xFFFFB347)),
                          unselectedIconTheme:
                              const IconThemeData(color: Colors.white70),
                          useIndicator: true,
                          indicatorColor: const Color(0xFF222C3A),
                          selectedIndex:
                              _CmsSection.values.indexOf(_currentSection),
                          onDestinationSelected: (index) {
                            setState(() =>
                                _currentSection = _CmsSection.values[index]);
                          },
                          labelType: NavigationRailLabelType.all,
                          destinations: const [
                            NavigationRailDestination(
                              icon: Icon(Icons.video_collection_outlined),
                              selectedIcon: Icon(Icons.video_collection),
                              label: Text('Shows'),
                            ),
                            NavigationRailDestination(
                              icon: Icon(Icons.groups_outlined),
                              selectedIcon: Icon(Icons.groups),
                              label: Text('Creator'),
                            ),
                            NavigationRailDestination(
                              icon: Icon(Icons.delete_sweep_outlined),
                              selectedIcon: Icon(Icons.delete_sweep),
                              label: Text('Trash'),
                            ),
                            NavigationRailDestination(
                              icon: Icon(Icons.rss_feed_outlined),
                              selectedIcon: Icon(Icons.rss_feed),
                              label: Text('Feed'),
                            ),
                          ],
                        ),
                        const VerticalDivider(width: 1),
                        Expanded(
                          child: Column(
                            children: [
                              //_buildSectionOverview(state),
                              Expanded(child: _buildSectionContent(state)),
                            ],
                          ),
                        ),
                      ],
                    );
                  }

                  return Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Color(0x26FFFFFF),
                              width: 0.7,
                            ),
                          ),
                        ),
                        child: SizedBox(
                          height: 40,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              _sectionChip('Shows', _CmsSection.shows),
                              _sectionChip('Creator', _CmsSection.creators),
                              _sectionChip('Trash', _CmsSection.trash),
                              _sectionChip('Feed', _CmsSection.feed),
                            ],
                          ),
                        ),
                      ),
                      //_buildSectionOverview(state),
                      Expanded(child: _buildSectionContent(state)),
                    ],
                  );
                },
              ),
            ),
            _buildStickyActionBar(state),
          ],
        ),
      ),
    );
  }

  // Widget _buildSectionOverview(ContentState state) {
  //   return Padding(
  //     padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
  //     child: CmsAdminCard(
  //       title: _sectionTitle(),
  //       subtitle: _sectionSubtitle(state),
  //       child: Wrap(
  //         spacing: 8,
  //         runSpacing: 8,
  //         children: _sectionStats(state),
  //       ),
  //     ),
  //   );
  // }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0x121fffffff),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x26FFFFFF)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white54, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.montserrat(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.dmSans(
                    color: Colors.white60,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionChip(String label, _CmsSection section) {
    final selected = _currentSection == section;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _currentSection = section),
        showCheckmark: false,
        selectedColor: const Color(0xFFFFB347),
        side: BorderSide(
          color: selected ? Colors.transparent : const Color(0x2AFFFFFF),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        labelStyle: GoogleFonts.montserrat(
          color: selected ? Colors.black : Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
        backgroundColor: const Color(0xFF1A2230),
      ),
    );
  }

  Widget _subPageChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        showCheckmark: false,
        selectedColor: const Color(0xFF4DA3FF),
        side: BorderSide(
          color: selected ? Colors.transparent : const Color(0x2AFFFFFF),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        labelStyle: GoogleFonts.montserrat(
          color: selected ? Colors.black : Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
        backgroundColor: const Color(0xFF172235),
      ),
    );
  }

  Widget _buildRowDetails(List<String> lines) {
    final visible =
        lines.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: visible
          .map(
            (line) => Text(
              line,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),
          )
          .toList(),
    );
  }

  Widget _buildFlowHint(String text) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0x1A4DA3FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0x334DA3FF)),
      ),
      child: Row(
        children: [
          const Icon(Icons.tips_and_updates_outlined,
              color: Color(0xFF8EC5FF), size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.dmSans(color: Colors.white70, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  String _slugify(String input) {
    final lower = input.toLowerCase().trim();
    final replaced = lower.replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    final collapsed = replaced.replaceAll(RegExp(r'-+'), '-');
    return collapsed.replaceAll(RegExp(r'^-|-$'), '');
  }

  Widget _buildInlineValidationMessage() {
    if (_inlineFormError == null || _inlineFormError!.trim().isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0x22FF6B6B),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0x66FF6B6B)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFFF9A9A), size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _inlineFormError!,
              style: GoogleFonts.dmSans(color: Colors.white70, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionStepper({
    required List<String> labels,
    required int current,
    required ValueChanged<int> onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: List.generate(labels.length, (index) {
          final isActive = current == index;
          return InkWell(
            onTap: () => onTap(index),
            borderRadius: BorderRadius.circular(999),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isActive
                    ? const Color(0xFF4DA3FF)
                    : const Color(0x1FFFFFFF),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color:
                      isActive ? Colors.transparent : const Color(0x2AFFFFFF),
                ),
              ),
              child: Text(
                '${index + 1}. ${labels[index]}',
                style: GoogleFonts.dmSans(
                  color: isActive ? Colors.black : Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  void _setInlineError(String message) {
    setState(() => _inlineFormError = message);
  }

  void _clearInlineError() {
    if (_inlineFormError != null) {
      setState(() => _inlineFormError = null);
    }
  }

  Future<void> _submitCreateShow() async {
    final notifier = ref.read(contentNotifierProvider.notifier);
    final title = _showTitleController.text.trim();
    final shortTitle = _showShortTitleController.text.trim();
    final description = _showDescriptionController.text.trim();
    final genre = _showGenreController.text.trim();
    final releaseWindow = _showReleaseWindowController.text.trim();
    final status = _showStatusController.text.trim();
    final slug = _showSlugController.text.trim();
    final tmdbId = _showTmdbIdController.text.trim();
    final traktSlug = _showTraktSlugController.text.trim();
    final headerImageUrl = _showHeaderImageUrlController.text.trim();
    final mainColor = _showMainColorController.text.trim();
    if (title.isEmpty) {
      _setInlineError('Bitte einen Show-Titel eintragen.');
      return;
    }

    _clearInlineError();
    await notifier.addShow(
      Show.withRandomId(
        title: title,
        shortTitle: shortTitle.isEmpty ? null : shortTitle,
        description: description.isEmpty ? null : description,
        genre: genre.isEmpty ? null : genre,
        releaseWindow: releaseWindow.isEmpty ? null : releaseWindow,
        status: status.isEmpty ? null : status,
        slug: slug.isEmpty ? null : slug,
        tmdbId: tmdbId.isEmpty ? null : tmdbId,
        traktSlug: traktSlug.isEmpty ? null : traktSlug,
        headerImageUrl: headerImageUrl.isEmpty ? null : headerImageUrl,
        mainColor: mainColor.isEmpty ? null : mainColor,
      ),
    );
    _showTitleController.clear();
    _showShortTitleController.clear();
    _showDescriptionController.clear();
    _showGenreController.clear();
    _showReleaseWindowController.clear();
    _showStatusController.clear();
    _showSlugController.clear();
    _showTmdbIdController.clear();
    _showTraktSlugController.clear();
    _showHeaderImageUrlController.clear();
    _showMainColorController.clear();
    await notifier.loadShows();
    await notifier.loadShowsTableRows();
  }

  Future<void> _submitCreateSeason() async {
    final notifier = ref.read(contentNotifierProvider.notifier);
    final seasonNumber = int.tryParse(_seasonNumberController.text);
    final episodes = int.tryParse(_seasonEpisodesController.text);
    final episodeLengthText = _seasonEpisodeLengthController.text.trim();
    final streamingOptionText = _seasonStreamingOptionController.text.trim();
    final episodeLength =
        episodeLengthText.isEmpty ? null : int.tryParse(episodeLengthText);
    if (_seasonShowId == null ||
        _seasonStartDate == null ||
        seasonNumber == null ||
        episodes == null) {
      _setInlineError(
          'Bitte Show, Staffelnummer, Episodenzahl und Startdatum setzen.');
      return;
    }
    if (_seasonReleaseFrequency == 'multi_weekly' &&
        _seasonMultiWeeklyDays.isEmpty) {
      _setInlineError(
          'Bitte mindestens einen Wochentag fuer multi_weekly auswaehlen.');
      return;
    }
    if (episodeLengthText.isNotEmpty && episodeLength == null) {
      _setInlineError('Bitte eine gültige Episodenlänge in Minuten eingeben.');
      return;
    }
    if (streamingOptionText.length > 20) {
      _setInlineError('Streaming Option darf maximal 20 Zeichen haben.');
      return;
    }
    if (!_isValidTimeValue(_seasonReleaseTimeController.text)) {
      _setInlineError('Bitte eine Uhrzeit im Format HH:mm eingeben.');
      return;
    }

    final startDateTime = _combineSeasonStartDateTime(_seasonStartDate!);

    _clearInlineError();
    await notifier.addSeason(Season(
      seasonId: const Uuid().v4(),
      showId: _seasonShowId,
      seasonNumber: seasonNumber,
      totalEpisodes: episodes,
      releaseFrequency: _buildSeasonReleaseFrequencyValue(),
      startDate: startDateTime,
      episodeLength: episodeLength,
      streamingOption: streamingOptionText.isEmpty ? null : streamingOptionText,
    ));
    _seasonNumberController.clear();
    _seasonEpisodesController.clear();
    _seasonReleaseTimeController.text = '20:15';
    _seasonEpisodeLengthController.clear();
    _seasonStreamingOptionController.clear();
    setState(() => _seasonStartDate = null);
    await notifier.loadShowsTableRows();
  }

  Future<void> _submitCreateCreator() async {
    final notifier = ref.read(contentNotifierProvider.notifier);
    final name = _creatorNameController.text.trim();
    if (name.isEmpty) {
      _setInlineError('Bitte einen Creator-Namen eintragen.');
      return;
    }

    _clearInlineError();
    await notifier.addCreator(
      name: name,
      description: _creatorDescriptionController.text.trim().isEmpty
          ? null
          : _creatorDescriptionController.text.trim(),
      avatarUrl: _creatorAvatarController.text.trim().isEmpty
          ? null
          : _creatorAvatarController.text.trim(),
      youtubeChannelUrl: _creatorYoutubeController.text.trim().isEmpty
          ? null
          : _creatorYoutubeController.text.trim(),
      instagramUrl: _creatorInstagramController.text.trim().isEmpty
          ? null
          : _creatorInstagramController.text.trim(),
      tiktokUrl: _creatorTiktokController.text.trim().isEmpty
          ? null
          : _creatorTiktokController.text.trim(),
    );
    _creatorNameController.clear();
  }

  Future<void> _submitCreatorBlock() async {
    final notifier = ref.read(contentNotifierProvider.notifier);
    if (_blockCreatorId == null ||
        _blockShowId == null ||
        _blockSeasonId == null) {
      _setInlineError(
          'Bitte Creator, Show und Staffel fuer den Event-Block auswaehlen.');
      return;
    }

    _clearInlineError();
    await notifier.createCreatorEventBlockForSeason(
      creatorId: _blockCreatorId!,
      showId: _blockShowId!,
      seasonId: _blockSeasonId!,
      eventKind: _blockEventKind,
      titlePrefix: _blockTitlePrefixController.text.trim().isEmpty
          ? null
          : _blockTitlePrefixController.text.trim(),
      descriptionTemplate: _blockDescriptionController.text.trim().isEmpty
          ? null
          : _blockDescriptionController.text.trim(),
    );
    await notifier.loadCreatorEvents();
  }

  Future<void> _submitCreatorEvent() async {
    final notifier = ref.read(contentNotifierProvider.notifier);
    if (_detailCreatorId == null) {
      _setInlineError('Bitte einen Creator fuer das Einzel-Event auswaehlen.');
      return;
    }

    _clearInlineError();
    await notifier.addCreatorEvent(
      creatorId: _detailCreatorId!,
      eventKind: _detailEventKind,
      relatedShowId: _detailShowId,
      relatedSeasonId: _detailSeasonId,
      episodeNumber: int.tryParse(_detailEpisodeNumberController.text),
      title: _detailTitleController.text.trim().isEmpty
          ? null
          : _detailTitleController.text.trim(),
      description: _detailDescriptionController.text.trim().isEmpty
          ? null
          : _detailDescriptionController.text.trim(),
      youtubeUrl: _detailYoutubeUrlController.text.trim().isEmpty
          ? null
          : _detailYoutubeUrlController.text.trim(),
      thumbnailUrl: _detailThumbnailUrlController.text.trim().isEmpty
          ? null
          : _detailThumbnailUrlController.text.trim(),
      scheduledAt: _detailDateTime,
    );
  }

  Future<void> _submitTrashEvent() async {
    final notifier = ref.read(contentNotifierProvider.notifier);
    if (_trashTitleController.text.trim().isEmpty || _trashDateTime == null) {
      _setInlineError(
          'Bitte mindestens Titel und Starttermin fuer das Trash-Event setzen.');
      return;
    }

    _clearInlineError();
    final occurrences = int.tryParse(_trashOccurrencesController.text) ?? 1;
    if (_trashRepeatMode != 'none' && occurrences > 1) {
      await notifier.addTrashEventSeries(
        title: _trashTitleController.text.trim(),
        description: _trashDescriptionController.text.trim().isEmpty
            ? null
            : _trashDescriptionController.text.trim(),
        imageUrl: _trashImageUrlController.text.trim().isEmpty
            ? null
            : _trashImageUrlController.text.trim(),
        location: _trashLocationController.text.trim().isEmpty
            ? null
            : _trashLocationController.text.trim(),
        address: _trashAddressController.text.trim().isEmpty
            ? null
            : _trashAddressController.text.trim(),
        organizer: _trashOrganizerController.text.trim().isEmpty
            ? null
            : _trashOrganizerController.text.trim(),
        price: _trashPriceController.text.trim().isEmpty
            ? null
            : _trashPriceController.text.trim(),
        externalUrl: _trashExternalUrlController.text.trim().isEmpty
            ? null
            : _trashExternalUrlController.text.trim(),
        relatedShowId: _trashShowId,
        relatedSeasonId: _trashSeasonId,
        startAt: _trashDateTime!,
        occurrences: occurrences,
        interval: _trashSeriesInterval(),
      );
    } else {
      await notifier.addTrashEvent(
        title: _trashTitleController.text.trim(),
        description: _trashDescriptionController.text.trim().isEmpty
            ? null
            : _trashDescriptionController.text.trim(),
        imageUrl: _trashImageUrlController.text.trim().isEmpty
            ? null
            : _trashImageUrlController.text.trim(),
        location: _trashLocationController.text.trim().isEmpty
            ? null
            : _trashLocationController.text.trim(),
        address: _trashAddressController.text.trim().isEmpty
            ? null
            : _trashAddressController.text.trim(),
        organizer: _trashOrganizerController.text.trim().isEmpty
            ? null
            : _trashOrganizerController.text.trim(),
        price: _trashPriceController.text.trim().isEmpty
            ? null
            : _trashPriceController.text.trim(),
        externalUrl: _trashExternalUrlController.text.trim().isEmpty
            ? null
            : _trashExternalUrlController.text.trim(),
        relatedShowId: _trashShowId,
        relatedSeasonId: _trashSeasonId,
        scheduledAt: _trashDateTime!,
      );
    }
  }

  Future<void> _submitFeedAction(ContentState state) async {
    final notifier = ref.read(contentNotifierProvider.notifier);
    if (_feedActionMode == _FeedActionMode.quoteOfWeek) {
      if (_quoteTextController.text.trim().isEmpty ||
          _quoteSpeakerController.text.trim().isEmpty ||
          _quoteShowId == null) {
        _setInlineError(
            'Bitte fuer "Spruch der Woche" Zitat, Sprecher und Show ausfuellen.');
        return;
      }
      _clearInlineError();
      final showTitle = _showTitleById(state, _quoteShowId);
      await notifier.addQuoteOfWeekFeedItem(
        quote: _quoteTextController.text.trim(),
        speakerName: _quoteSpeakerController.text.trim(),
        showId: _quoteShowId!,
        showTitle: showTitle,
        seasonNumber: int.tryParse(_quoteSeasonController.text.trim()),
        episodeNumber: int.tryParse(_quoteEpisodeController.text.trim()),
        ctaLabel: _quoteCtaController.text.trim().isEmpty
            ? null
            : _quoteCtaController.text.trim(),
      );
      _quoteTextController.clear();
      _quoteSpeakerController.clear();
      _quoteSeasonController.clear();
      _quoteEpisodeController.clear();
      _quoteCtaController.text = 'Zur Show';
      setState(() {
        _quoteShowId = null;
        _feedSubPage = _FeedSubPage.overview;
      });
      return;
    }

    if (_throwbackLabelController.text.trim().isEmpty ||
        _throwbackMomentController.text.trim().isEmpty ||
        _throwbackShowId == null) {
      _setInlineError(
          'Bitte fuer Throwback Label, Moment und Show ausfuellen.');
      return;
    }

    _clearInlineError();
    final showTitle = _showTitleById(state, _throwbackShowId);
    await notifier.addThrowbackFeedItem(
      label: _throwbackLabelController.text.trim(),
      momentText: _throwbackMomentController.text.trim(),
      showId: _throwbackShowId!,
      showTitle: showTitle,
      seasonNumber: int.tryParse(_throwbackSeasonController.text.trim()),
      episodeNumber: int.tryParse(_throwbackEpisodeController.text.trim()),
      ctaLabel: _throwbackCtaController.text.trim().isEmpty
          ? null
          : _throwbackCtaController.text.trim(),
      stickerLabel: _throwbackStickerController.text.trim().isEmpty
          ? null
          : _throwbackStickerController.text.trim(),
    );
    _throwbackLabelController.text = 'Throwback der Woche';
    _throwbackMomentController.clear();
    _throwbackSeasonController.clear();
    _throwbackEpisodeController.clear();
    _throwbackCtaController.text = 'Szene anschauen';
    _throwbackStickerController.text = 'OG Moment';
    setState(() {
      _throwbackShowId = null;
      _feedSubPage = _FeedSubPage.overview;
    });
  }

  _PrimaryActionConfig? _currentPrimaryAction(ContentState state) {
    if (_currentSection == _CmsSection.shows &&
        _showsSubPage == _ShowsSubPage.actions) {
      if (_showsActionMode == _ShowsActionMode.createShow) {
        return _PrimaryActionConfig(
            label: 'Show speichern', onPressed: _submitCreateShow);
      }
      return _PrimaryActionConfig(
          label: 'Staffel speichern', onPressed: _submitCreateSeason);
    }

    if (_currentSection == _CmsSection.creators &&
        _creatorsSubPage == _CreatorsSubPage.actions) {
      if (_creatorActionMode == _CreatorActionMode.createCreator) {
        return _PrimaryActionConfig(
            label: 'Creator speichern', onPressed: _submitCreateCreator);
      }
      if (_creatorActionMode == _CreatorActionMode.blockEvents) {
        return _PrimaryActionConfig(
            label: 'Block erstellen', onPressed: _submitCreatorBlock);
      }
      return _PrimaryActionConfig(
          label: 'Creator Event speichern', onPressed: _submitCreatorEvent);
    }

    if (_currentSection == _CmsSection.trash &&
        _trashSubPage == _TrashSubPage.actions) {
      return _PrimaryActionConfig(
          label: 'Trash Event speichern', onPressed: _submitTrashEvent);
    }

    if (_currentSection == _CmsSection.feed &&
        _feedSubPage == _FeedSubPage.actions) {
      return _PrimaryActionConfig(
        label: _feedActionMode == _FeedActionMode.quoteOfWeek
            ? 'Spruch-Karte speichern'
            : 'Throwback-Karte speichern',
        onPressed: () => _submitFeedAction(state),
      );
    }

    return null;
  }

  Widget _buildStickyActionBar(ContentState state) {
    final action = _currentPrimaryAction(state);
    if (action == null) return const SizedBox.shrink();

    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        decoration: const BoxDecoration(
          color: Color(0xFF121212),
          border: Border(
            top: BorderSide(color: Color(0x26FFFFFF), width: 1),
          ),
        ),
        child: SizedBox(
          height: 46,
          child: ElevatedButton.icon(
            onPressed: state.isLoading ? null : action.onPressed,
            icon: state.isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_circle_outline),
            label: Text(state.isLoading ? 'Speichert…' : action.label),
          ),
        ),
      ),
    );
  }

  String _showTitleById(ContentState state, String? showId) {
    if (showId == null || showId.isEmpty) return '-';
    for (final show in state.availableShows) {
      if (show.showId == showId) return show.displayTitle;
    }
    final row = state.showsTableRows.where((r) => r['id'] == showId).toList();
    if (row.isNotEmpty) {
      final short = (row.first['short_title'] as String?)?.trim();
      if (short != null && short.isNotEmpty) return short;
      return (row.first['title'] as String?) ?? '-';
    }
    return '-';
  }

  String _selectedShowTitle(ContentState state) {
    return _showTitleById(state, _selectedShowTableId);
  }

  String _selectedSeasonLabel(ContentState state) {
    if (_selectedSeasonTableId == null) return '-';
    for (final season in state.seasonsTableRows) {
      if (season['id'] == _selectedSeasonTableId) {
        return 'S${season['season_number'] ?? '-'}';
      }
    }
    return '-';
  }

  String _selectedShowEventLabel(ContentState state) {
    if (_selectedShowEventTableId == null) return '-';
    for (final event in state.showEventsTableRows) {
      if (event['id'] == _selectedShowEventTableId) {
        final timeLabel = _formatCompactDateTimeRange(
          event['calendar_start_datetime'],
          event['calendar_end_datetime'],
        );
        return '#${event['episode_number'] ?? '-'} (${event['event_subtype'] ?? '-'}) · $timeLabel';
      }
    }
    return '-';
  }

  String _formatCompactDateTime(dynamic value) {
    final parsed = _tryParseDate(value)?.toLocal();
    if (parsed == null) return '-';

    final day = parsed.day.toString().padLeft(2, '0');
    final month = parsed.month.toString().padLeft(2, '0');
    final hour = parsed.hour.toString().padLeft(2, '0');
    final minute = parsed.minute.toString().padLeft(2, '0');
    return '$day.$month. $hour:$minute';
  }

  String _formatCompactTime(dynamic value) {
    final parsed = _tryParseDate(value)?.toLocal();
    if (parsed == null) return '-';

    final hour = parsed.hour.toString().padLeft(2, '0');
    final minute = parsed.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatCompactDateTimeRange(dynamic startValue, dynamic endValue) {
    final start = _tryParseDate(startValue)?.toLocal();
    final end = _tryParseDate(endValue)?.toLocal();

    if (start == null) return 'kein Termin';
    if (end == null) return _formatCompactDateTime(start);

    final sameDay = start.year == end.year &&
        start.month == end.month &&
        start.day == end.day;

    if (sameDay) {
      return '${_formatCompactDateTime(start)}–${_formatCompactTime(end)}';
    }

    return '${_formatCompactDateTime(start)} → ${_formatCompactDateTime(end)}';
  }

  String _selectedCreatorName(ContentState state) {
    if (_selectedCreatorTableId == null) return '-';
    for (final creator in state.availableCreators) {
      if (creator['id'] == _selectedCreatorTableId) {
        return (creator['name'] as String?) ?? '-';
      }
    }
    return '-';
  }

  DateTime? _tryParseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String && value.trim().isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  int _compareMapValues(
    Map<String, dynamic> a,
    Map<String, dynamic> b,
    String key,
    bool asc,
  ) {
    final av = a[key];
    final bv = b[key];

    final ad = _tryParseDate(av);
    final bd = _tryParseDate(bv);
    int result;
    if (ad != null || bd != null) {
      result = (ad ?? DateTime.fromMillisecondsSinceEpoch(0))
          .compareTo(bd ?? DateTime.fromMillisecondsSinceEpoch(0));
    } else if (av is num || bv is num) {
      result = (av is num ? av.toDouble() : double.nan)
          .compareTo(bv is num ? bv.toDouble() : double.nan);
      if (result.isNaN) result = 0;
    } else {
      result = (av?.toString() ?? '')
          .toLowerCase()
          .compareTo((bv?.toString() ?? '').toLowerCase());
    }
    return asc ? result : -result;
  }

  Widget _buildSectionContent(ContentState state) {
    switch (_currentSection) {
      case _CmsSection.shows:
        return _buildShowsSection(state);
      case _CmsSection.creators:
        return _buildCreatorsSection(state);
      case _CmsSection.trash:
        return _buildTrashSection(state);
      case _CmsSection.feed:
        return _buildFeedSection(state);
    }
  }

  Widget _buildShowsSection(ContentState state) {
    final notifier = ref.read(contentNotifierProvider.notifier);
    final showRows = state.showsTableRows;
    final filteredShowRows = showRows.where((row) {
      if (_showTableSearchQuery.trim().isEmpty) return true;
      final title = (row['title'] as String? ?? '').toLowerCase();
      final shortTitle = (row['short_title'] as String? ?? '').toLowerCase();
      final query = _showTableSearchQuery.trim().toLowerCase();
      return title.contains(query) || shortTitle.contains(query);
    }).toList();
    final filteredSeasonRows = state.seasonsTableRows.where((row) {
      if (_seasonTableSearchQuery.trim().isEmpty) return true;
      final seasonNumber = (row['season_number'] ?? '').toString();
      final frequency =
          (row['release_frequency'] as String? ?? '').toLowerCase();
      final query = _seasonTableSearchQuery.trim().toLowerCase();
      return seasonNumber.contains(query) || frequency.contains(query);
    }).toList();
    final filteredShowEventRows = state.showEventsTableRows.where((row) {
      if (_showEventsTableSearchQuery.trim().isEmpty) return true;
      final subtype = (row['event_subtype'] as String? ?? '').toLowerCase();
      final description = (row['description'] as String? ?? '').toLowerCase();
      final episode = (row['episode_number'] ?? '').toString();
      final calendarStart =
          (row['calendar_start_datetime'] as String? ?? '').toLowerCase();
      final calendarEnd =
          (row['calendar_end_datetime'] as String? ?? '').toLowerCase();
      final query = _showEventsTableSearchQuery.trim().toLowerCase();
      return subtype.contains(query) ||
          description.contains(query) ||
          episode.contains(query) ||
          calendarStart.contains(query) ||
          calendarEnd.contains(query);
    }).toList();
    final filteredCalendarRows = state.calendarEventsTableRows.where((row) {
      if (_calendarEventsTableSearchQuery.trim().isEmpty) return true;
      final eventType = (row['event_type'] as String? ?? '').toLowerCase();
      final entityType =
          (row['event_entity_type'] as String? ?? '').toLowerCase();
      final query = _calendarEventsTableSearchQuery.trim().toLowerCase();
      return eventType.contains(query) || entityType.contains(query);
    }).toList();
    final sortedShowRows = [...filteredShowRows]
      ..sort((a, b) => _compareMapValues(a, b, _showsSortKey, _showsSortAsc));
    final sortedSeasonRows = [...filteredSeasonRows]..sort(
        (a, b) => _compareMapValues(a, b, _seasonsSortKey, _seasonsSortAsc));
    final sortedShowEventRows = [...filteredShowEventRows]..sort((a, b) =>
        _compareMapValues(a, b, _showEventsSortKey, _showEventsSortAsc));
    final sortedCalendarRows = [...filteredCalendarRows]..sort((a, b) =>
        _compareMapValues(
            a, b, _calendarEventsSortKey, _calendarEventsSortAsc));

    return Column(
      children: [
        const SizedBox(height: 16),
        SizedBox(
          height: 44,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            children: [
              _subPageChip(
                label: 'Übersicht',
                selected: _showsSubPage != _ShowsSubPage.actions,
                onTap: () =>
                    setState(() => _showsSubPage = _ShowsSubPage.shows),
              ),
              _subPageChip(
                label: 'Show anlegen',
                selected: _showsSubPage == _ShowsSubPage.actions &&
                    _showsActionMode == _ShowsActionMode.createShow,
                onTap: () => setState(() {
                  _showsActionMode = _ShowsActionMode.createShow;
                  _showsSubPage = _ShowsSubPage.actions;
                }),
              ),
              _subPageChip(
                label: 'Staffel anlegen',
                selected: _showsSubPage == _ShowsSubPage.actions &&
                    _showsActionMode == _ShowsActionMode.createSeason,
                onTap: () => setState(() {
                  _showsActionMode = _ShowsActionMode.createSeason;
                  _showsSubPage = _ShowsSubPage.actions;
                }),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (_showsSubPage == _ShowsSubPage.shows)
                CmsLocationInfo('Aktuelle Auswahl: keine Show gewählt'),
              if (_showsSubPage == _ShowsSubPage.seasons)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () =>
                        setState(() => _showsSubPage = _ShowsSubPage.shows),
                    icon: const Icon(Icons.arrow_back, color: Colors.white70),
                    label: const Text('Zurück zu Shows',
                        style: TextStyle(color: Colors.white70)),
                  ),
                ),
              if (_showsSubPage == _ShowsSubPage.showEvents)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () =>
                        setState(() => _showsSubPage = _ShowsSubPage.seasons),
                    icon: const Icon(Icons.arrow_back, color: Colors.white70),
                    label: const Text('Zurück zu Seasons',
                        style: TextStyle(color: Colors.white70)),
                  ),
                ),
              if (_showsSubPage == _ShowsSubPage.calendarEvents)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => setState(
                        () => _showsSubPage = _ShowsSubPage.showEvents),
                    icon: const Icon(Icons.arrow_back, color: Colors.white70),
                    label: const Text('Zurück zu Show Events',
                        style: TextStyle(color: Colors.white70)),
                  ),
                ),
              if (_showsSubPage == _ShowsSubPage.seasons)
                CmsLocationInfo('Aktuelle Show: ${_selectedShowTitle(state)}'),
              if (_showsSubPage == _ShowsSubPage.showEvents)
                CmsLocationInfo(
                    'Aktuell: ${_selectedShowTitle(state)} · ${_selectedSeasonLabel(state)}'),
              if (_showsSubPage == _ShowsSubPage.calendarEvents)
                CmsLocationInfo(
                    'Aktuell: ${_selectedShowTitle(state)} · ${_selectedSeasonLabel(state)} · ${_selectedShowEventLabel(state)}'),
              if (_showsSubPage == _ShowsSubPage.shows)
                CmsAdminCard(
                  title: 'Shows',
                  subtitle: 'Suchen, auswählen und bearbeiten.',
                  child: Column(
                    children: [
                      CmsSearchSortBar(
                        searchHint: 'Suche Titel / Kurztitel …',
                        onSearchChanged: (value) =>
                            setState(() => _showTableSearchQuery = value),
                        sortKey: _showsSortKey,
                        ascending: _showsSortAsc,
                        sortOptions: const {
                          'title': 'Titel',
                          'short_title': 'Kurztitel',
                          'genre': 'Genre',
                          'release_window': 'Release Window',
                          'status': 'Status',
                          'main_color': 'Main Color',
                          'updated_at': 'Zuletzt aktualisiert',
                          'created_at': 'Erstellt am',
                        },
                        onSortChanged: (value) {
                          if (value != null) {
                            setState(() => _showsSortKey = value);
                          }
                        },
                        onToggleDirection: () =>
                            setState(() => _showsSortAsc = !_showsSortAsc),
                      ),
                      const SizedBox(height: 10),
                      if (sortedShowRows.isEmpty)
                        _buildEmptyState(
                          icon: Icons.search_off_rounded,
                          title: 'Keine Shows gefunden',
                          subtitle:
                              'Passe Suche oder Filter an oder lege eine neue Show an.',
                        ),
                      ...sortedShowRows.map(
                        (showRow) => ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            (showRow['short_title'] as String?)
                                        ?.trim()
                                        .isNotEmpty ==
                                    true
                                ? (showRow['short_title'] as String)
                                : (showRow['title'] as String?) ??
                                    '(ohne Titel)',
                            style: const TextStyle(color: Colors.white),
                          ),
                          subtitle: _buildRowDetails([
                            'Titel: ${(showRow['title'] as String?) ?? '-'} · Kurztitel: ${(showRow['short_title'] as String?) ?? '-'}',
                            'Genre: ${(showRow['genre'] as String?) ?? '-'} · Release: ${(showRow['release_window'] as String?) ?? '-'} · Status: ${(showRow['status'] as String?) ?? '-'}',
                            'Main Color: ${(showRow['main_color'] as String?) ?? '-'}',
                            'Header Image: ${(showRow['header_image'] as String?) ?? '-'}',
                          ]),
                          selected:
                              _selectedShowTableId == showRow['id'] as String?,
                          onTap: () async {
                            final showId = showRow['id'] as String?;
                            if (showId == null) return;
                            setState(() {
                              _selectedShowTableId = showId;
                              _selectedSeasonTableId = null;
                              _selectedShowEventTableId = null;
                            });
                            notifier.clearShowDrilldown();
                            await notifier.loadSeasonsTableRowsByShowId(showId);
                            if (mounted) {
                              setState(
                                  () => _showsSubPage = _ShowsSubPage.seasons);
                            }
                          },
                          trailing: IconButton(
                            icon: const Icon(Icons.edit, color: AppColors.pop),
                            onPressed: () =>
                                _openShowTableRowEditDialog(showRow),
                          ),
                          leading: IconButton(
                            tooltip: 'Löschen',
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.redAccent),
                            onPressed: () {
                              final id = showRow['id'] as String?;
                              if (id == null) return;
                              _deleteCmsRowAndRefresh(table: 'shows', id: id);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (_showsSubPage == _ShowsSubPage.seasons)
                CmsAdminCard(
                  title: 'Staffeln',
                  subtitle: 'Staffeln zur gewählten Show.',
                  child: Column(
                    children: [
                      CmsSearchSortBar(
                        searchHint: 'Suche Staffel / Frequenz …',
                        onSearchChanged: (value) =>
                            setState(() => _seasonTableSearchQuery = value),
                        sortKey: _seasonsSortKey,
                        ascending: _seasonsSortAsc,
                        sortOptions: const {
                          'season_number': 'Staffel Nr.',
                          'total_episodes': 'Episoden',
                          'release_frequency': 'Frequenz',
                          'streaming_release_date': 'Release-Datum',
                          'created_at': 'Erstellt am',
                        },
                        onSortChanged: (value) {
                          if (value != null) {
                            setState(() => _seasonsSortKey = value);
                          }
                        },
                        onToggleDirection: () =>
                            setState(() => _seasonsSortAsc = !_seasonsSortAsc),
                      ),
                      const SizedBox(height: 10),
                      if (sortedSeasonRows.isEmpty)
                        _buildEmptyState(
                          icon: Icons.layers_clear_outlined,
                          title: 'Keine Staffeln vorhanden',
                          subtitle:
                              'Für diese Show wurden noch keine Staffeln angelegt.',
                        ),
                      ...sortedSeasonRows.map(
                        (season) => ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            'S${season['season_number'] ?? '-'} · ${season['total_episodes'] ?? '-'} Folgen',
                            style: const TextStyle(color: Colors.white),
                          ),
                          subtitle: _buildRowDetails([
                            'Frequenz: ${season['release_frequency'] ?? '-'} · Status: ${season['status'] ?? '-'}',
                            'Startdatum: ${season['streaming_release_date'] ?? '-'} · Release Zeit: ${season['streaming_release_time'] ?? '-'}',
                            'Episodenlänge: ${season['episode_length'] ?? '-'} · Streaming: ${season['streaming_option'] ?? '-'}',
                          ]),
                          selected:
                              _selectedSeasonTableId == season['id'] as String?,
                          onTap: () async {
                            final seasonId = season['id'] as String?;
                            if (seasonId == null) return;
                            setState(() {
                              _selectedSeasonTableId = seasonId;
                              _selectedShowEventTableId = null;
                            });
                            await notifier.loadShowEventsBySeasonId(seasonId);
                            if (mounted) {
                              setState(() =>
                                  _showsSubPage = _ShowsSubPage.showEvents);
                            }
                          },
                          trailing: IconButton(
                            icon: const Icon(Icons.edit, color: AppColors.pop),
                            onPressed: () => _openSeasonTableRowEditDialog(
                                season, state.availableShows),
                          ),
                          leading: IconButton(
                            tooltip: 'Löschen',
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.redAccent),
                            onPressed: () {
                              final id = season['id'] as String?;
                              if (id == null) return;
                              _deleteCmsRowAndRefresh(table: 'seasons', id: id);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (_showsSubPage == _ShowsSubPage.showEvents)
                CmsAdminCard(
                  title: 'Show-Events',
                  subtitle: 'Episoden-Events und Terminzuordnung.',
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.centerRight,
                        child: OutlinedButton.icon(
                          onPressed: _openCreateShowEventDialog,
                          icon: const Icon(Icons.add_circle_outline),
                          label: const Text('Show Event + Calendar Event'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      CmsSearchSortBar(
                        searchHint:
                            'Suche Typ / Beschreibung / Episode / Startzeit …',
                        onSearchChanged: (value) =>
                            setState(() => _showEventsTableSearchQuery = value),
                        sortKey: _showEventsSortKey,
                        ascending: _showEventsSortAsc,
                        sortOptions: const {
                          'episode_number': 'Episode',
                          'event_subtype': 'Typ',
                          'calendar_start_datetime': 'Laufzeit Start',
                          'created_at': 'Erstellt am',
                        },
                        onSortChanged: (value) {
                          if (value != null) {
                            setState(() => _showEventsSortKey = value);
                          }
                        },
                        onToggleDirection: () => setState(
                            () => _showEventsSortAsc = !_showEventsSortAsc),
                      ),
                      const SizedBox(height: 10),
                      if (sortedShowEventRows.isEmpty)
                        _buildEmptyState(
                          icon: Icons.event_busy_outlined,
                          title: 'Keine Show-Events vorhanden',
                          subtitle:
                              'Lege für die ausgewählte Staffel ein Event oder einen Termin an.',
                        ),
                      ...sortedShowEventRows.map(
                        (event) => ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            '#${event['episode_number'] ?? '-'} · ${(event['event_subtype'] as String?) ?? '-'} · ${_formatCompactDateTimeRange(event['calendar_start_datetime'], event['calendar_end_datetime'])}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white),
                          ),
                          subtitle: _buildRowDetails([
                            'Termin: ${_formatCompactDateTimeRange(event['calendar_start_datetime'], event['calendar_end_datetime'])}',
                            'Beschreibung: ${(event['description'] as String?) ?? '-'}',
                          ]),
                          selected: _selectedShowEventTableId ==
                              event['id'] as String?,
                          onTap: () async {
                            final showEventId = event['id'] as String?;
                            if (showEventId == null) return;
                            setState(
                                () => _selectedShowEventTableId = showEventId);
                            await notifier
                                .loadCalendarEventsByShowEventId(showEventId);
                            if (mounted) {
                              setState(() =>
                                  _showsSubPage = _ShowsSubPage.calendarEvents);
                            }
                          },
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Kalenderdatum ändern',
                                icon: const Icon(Icons.event,
                                    color: AppColors.pop),
                                onPressed: () {
                                  final calendarEventId =
                                      event['calendar_event_id'] as String?;
                                  if (calendarEventId == null ||
                                      calendarEventId.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Kein Termin verknüpft.'),
                                      ),
                                    );
                                    return;
                                  }
                                  _openCalendarEventEditDialog({
                                    'id': calendarEventId,
                                    'start_datetime':
                                        event['calendar_start_datetime'],
                                    'end_datetime':
                                        event['calendar_end_datetime'],
                                    'event_type':
                                        event['calendar_event_type'] ??
                                            event['event_subtype'],
                                    'event_entity_type': 'show_event',
                                  });
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit,
                                    color: AppColors.pop),
                                onPressed: () =>
                                    _openShowEventEditDialog(event),
                              ),
                              IconButton(
                                tooltip: 'Löschen',
                                icon: const Icon(Icons.delete_outline,
                                    color: Colors.redAccent),
                                onPressed: () {
                                  final id = event['id'] as String?;
                                  if (id == null) return;
                                  _deleteCmsRowAndRefresh(
                                      table: 'show_events', id: id);
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (_showsSubPage == _ShowsSubPage.calendarEvents)
                CmsAdminCard(
                  title: 'Kalendertermine',
                  subtitle: 'Termine zum ausgewählten Event.',
                  child: Column(
                    children: [
                      CmsSearchSortBar(
                        searchHint: 'Suche Event-Typ / Entity-Typ …',
                        onSearchChanged: (value) => setState(
                            () => _calendarEventsTableSearchQuery = value),
                        sortKey: _calendarEventsSortKey,
                        ascending: _calendarEventsSortAsc,
                        sortOptions: const {
                          'start_datetime': 'Start',
                          'end_datetime': 'Ende',
                          'event_type': 'Event-Typ',
                          'drama_level': 'Drama-Level',
                          'created_at': 'Erstellt am',
                        },
                        onSortChanged: (value) {
                          if (value != null) {
                            setState(() => _calendarEventsSortKey = value);
                          }
                        },
                        onToggleDirection: () => setState(() =>
                            _calendarEventsSortAsc = !_calendarEventsSortAsc),
                      ),
                      const SizedBox(height: 10),
                      ...sortedCalendarRows.map(
                        (event) => ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            (event['event_type'] as String?) ?? '-',
                            style: const TextStyle(color: Colors.white),
                          ),
                          subtitle: _buildRowDetails([
                            'Start: ${event['start_datetime'] ?? '-'}',
                            'Ende: ${event['end_datetime'] ?? '-'} · Entity: ${event['event_entity_type'] ?? '-'}',
                            'Drama: ${event['drama_level'] ?? '-'}',
                          ]),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit, color: AppColors.pop),
                            onPressed: () =>
                                _openCalendarEventEditDialog(event),
                          ),
                          leading: IconButton(
                            tooltip: 'Löschen',
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.redAccent),
                            onPressed: () {
                              final id = event['id'] as String?;
                              if (id == null) return;
                              _deleteCmsRowAndRefresh(
                                  table: 'calendar_events', id: id);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (_showsSubPage == _ShowsSubPage.actions) ...[
                if (_showsActionMode == _ShowsActionMode.createShow)
                  _buildCreateShowCard(state),
                if (_showsActionMode == _ShowsActionMode.createSeason)
                  _buildCreateSeasonCard(state),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCreateShowCard(ContentState state) {
    return CmsAdminCard(
      title: 'Neue Show',
      subtitle: 'Show in die Tabelle shows eintragen.',
      child: Column(
        children: [
          _buildFlowHint(
              'Pflichtfeld: Titel. Slug wird beim Tippen automatisch vorgeschlagen.'),
          _buildInlineValidationMessage(),
          TextField(
            controller: _showTitleController,
            style: const TextStyle(color: Colors.white),
            decoration: cmsInputDecoration('Show Titel *'),
            onChanged: (value) {
              if (_showSlugController.text.trim().isEmpty) {
                _showSlugController.text = _slugify(value);
              }
            },
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _showShortTitleController,
            style: const TextStyle(color: Colors.white),
            decoration: cmsInputDecoration('Kurztitel (optional)'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _showDescriptionController,
            style: const TextStyle(color: Colors.white),
            maxLines: 3,
            decoration: cmsInputDecoration('Beschreibung (optional)'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _showGenreController,
            style: const TextStyle(color: Colors.white),
            decoration: cmsInputDecoration('Genre (optional)'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _showReleaseWindowController,
            style: const TextStyle(color: Colors.white),
            decoration: cmsInputDecoration(
                'Release Window (z. B. 2026-SPRING oder 2026-03)'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _showStatusController,
            style: const TextStyle(color: Colors.white),
            decoration: cmsInputDecoration('Status (optional)'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _showSlugController,
            style: const TextStyle(color: Colors.white),
            decoration: cmsInputDecoration('Slug (optional)'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _showTmdbIdController,
            style: const TextStyle(color: Colors.white),
            decoration: cmsInputDecoration('TMDB ID (optional)'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _showTraktSlugController,
            style: const TextStyle(color: Colors.white),
            decoration: cmsInputDecoration('Trakt Slug (optional)'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _showHeaderImageUrlController,
            style: const TextStyle(color: Colors.white),
            decoration: cmsInputDecoration('Header Image URL (optional)'),
          ),
          const SizedBox(height: 10),
          CmsColorPickerField(
            controller: _showMainColorController,
            label: 'Main Color (hex, z. B. #E85D9E)',
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  Widget _buildCreateSeasonCard(ContentState state) {
    return CmsAdminCard(
      title: 'Neue Staffel',
      subtitle: 'Rhythmus, Startdatum und Metadaten festlegen.',
      child: Column(
        children: [
          _buildFlowHint(
              'Schrittfolge: Show waehlen -> Staffel/Episoden setzen -> Frequenz + Startdatum + Metadaten waehlen.'),
          _buildInlineValidationMessage(),
          CmsSearchableShowField(
            shows: state.availableShows,
            selectedShowId: _seasonShowId,
            label: 'Show *',
            onChanged: (value) => setState(() => _seasonShowId = value),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _seasonNumberController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: cmsInputDecoration('Staffel Nr. *'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _seasonEpisodesController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: cmsInputDecoration('Episoden *'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: _seasonReleaseFrequency,
            decoration: cmsInputDecoration('Rhythmus *'),
            dropdownColor: const Color(0xFF1F1F1F),
            style: const TextStyle(color: Colors.white),
            items: _releaseFrequencyOptions.entries
                .map((entry) => DropdownMenuItem(
                      value: entry.key,
                      child: Text(entry.value),
                    ))
                .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _seasonReleaseFrequency = value);
              }
            },
          ),
          if (_seasonReleaseFrequency == 'multi_weekly') ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Tage wählen',
                style: GoogleFonts.dmSans(color: Colors.white70),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _weekdayLabels.entries.map((entry) {
                final selected = _seasonMultiWeeklyDays.contains(entry.key);
                return FilterChip(
                  label: Text(entry.value),
                  selected: selected,
                  onSelected: (value) {
                    setState(() {
                      if (value) {
                        _seasonMultiWeeklyDays.add(entry.key);
                      } else {
                        _seasonMultiWeeklyDays.remove(entry.key);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: CmsDatePickerField(
                  label: 'Startdatum *',
                  value: _seasonStartDate,
                  onChanged: (value) =>
                      setState(() => _seasonStartDate = value),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: CmsTimeTextField(
                  label: 'Uhrzeit *',
                  controller: _seasonReleaseTimeController,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _seasonEpisodeLengthController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: cmsInputDecoration('Episode Length (Min)'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _seasonStreamingOptionController,
                  style: const TextStyle(color: Colors.white),
                  decoration: cmsInputDecoration('Streaming Option'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  Widget _buildCreatorsSection(ContentState state) {
    final filteredCreators = state.availableCreators.where((creator) {
      if (_creatorTableSearchQuery.trim().isEmpty) return true;
      final name = (creator['name'] as String? ?? '').toLowerCase();
      return name.contains(_creatorTableSearchQuery.trim().toLowerCase());
    }).toList();
    final creatorEventsForSelected = state.creatorEvents.where((event) {
      if (_selectedCreatorTableId == null) return false;
      return event['creator_id'] == _selectedCreatorTableId;
    }).toList();
    final filteredCreatorEvents = creatorEventsForSelected.where((event) {
      if (_creatorEventsTableSearchQuery.trim().isEmpty) return true;
      final title = (event['title'] as String? ?? '').toLowerCase();
      final kind = (event['event_kind'] as String? ?? '').toLowerCase();
      final query = _creatorEventsTableSearchQuery.trim().toLowerCase();
      return title.contains(query) || kind.contains(query);
    }).toList();
    final sortedCreators = [...filteredCreators]..sort(
        (a, b) => _compareMapValues(a, b, _creatorsSortKey, _creatorsSortAsc));
    final sortedCreatorEvents = [...filteredCreatorEvents]..sort((a, b) =>
        _compareMapValues(a, b, _creatorEventsSortKey, _creatorEventsSortAsc));

    return Column(
      children: [
        const SizedBox(height: 16),
        SizedBox(
          height: 44,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            children: [
              _subPageChip(
                label: 'Übersicht',
                selected: _creatorsSubPage != _CreatorsSubPage.actions,
                onTap: () => setState(
                    () => _creatorsSubPage = _CreatorsSubPage.creators),
              ),
              _subPageChip(
                label: 'Creator anlegen',
                selected: _creatorsSubPage == _CreatorsSubPage.actions &&
                    _creatorActionMode == _CreatorActionMode.createCreator,
                onTap: () => setState(() {
                  _creatorActionMode = _CreatorActionMode.createCreator;
                  _creatorsSubPage = _CreatorsSubPage.actions;
                }),
              ),
              _subPageChip(
                label: 'Event-Block',
                selected: _creatorsSubPage == _CreatorsSubPage.actions &&
                    _creatorActionMode == _CreatorActionMode.blockEvents,
                onTap: () => setState(() {
                  _creatorActionMode = _CreatorActionMode.blockEvents;
                  _creatorsSubPage = _CreatorsSubPage.actions;
                }),
              ),
              _subPageChip(
                label: 'Einzel-Event',
                selected: _creatorsSubPage == _CreatorsSubPage.actions &&
                    _creatorActionMode == _CreatorActionMode.createEvent,
                onTap: () => setState(() {
                  _creatorActionMode = _CreatorActionMode.createEvent;
                  _creatorsSubPage = _CreatorsSubPage.actions;
                }),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (_creatorsSubPage == _CreatorsSubPage.creators)
                CmsLocationInfo('Aktuelle Auswahl: kein Creator gewählt'),
              if (_creatorsSubPage == _CreatorsSubPage.creatorEvents)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => setState(
                        () => _creatorsSubPage = _CreatorsSubPage.creators),
                    icon: const Icon(Icons.arrow_back, color: Colors.white70),
                    label: const Text('Zurück zu Creators',
                        style: TextStyle(color: Colors.white70)),
                  ),
                ),
              if (_creatorsSubPage == _CreatorsSubPage.creatorEvents)
                CmsLocationInfo(
                    'Aktueller Creator: ${_selectedCreatorName(state)}'),
              if (_creatorsSubPage == _CreatorsSubPage.creators)
                CmsAdminCard(
                  title: 'Creators',
                  subtitle: 'Creator auswählen und Events öffnen.',
                  child: Column(
                    children: [
                      CmsSearchSortBar(
                        searchHint: 'Suche Creator …',
                        onSearchChanged: (value) =>
                            setState(() => _creatorTableSearchQuery = value),
                        sortKey: _creatorsSortKey,
                        ascending: _creatorsSortAsc,
                        sortOptions: const {
                          'name': 'Name',
                          'created_at': 'Erstellt am',
                          'updated_at': 'Aktualisiert am',
                        },
                        onSortChanged: (value) {
                          if (value != null) {
                            setState(() => _creatorsSortKey = value);
                          }
                        },
                        onToggleDirection: () => setState(
                            () => _creatorsSortAsc = !_creatorsSortAsc),
                      ),
                      const SizedBox(height: 10),
                      ...sortedCreators.map(
                        (creator) => ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            (creator['name'] as String?) ?? '',
                            style: const TextStyle(color: Colors.white),
                          ),
                          subtitle: _buildRowDetails([
                            'YouTube: ${((creator['youtube_channel_url'] as String?)?.isNotEmpty ?? false) ? 'ja' : 'nein'} · Instagram: ${((creator['instagram_url'] as String?)?.isNotEmpty ?? false) ? 'ja' : 'nein'} · TikTok: ${((creator['tiktok_url'] as String?)?.isNotEmpty ?? false) ? 'ja' : 'nein'}',
                            'Beschreibung: ${(creator['description'] as String?) ?? '-'}',
                          ]),
                          selected: _selectedCreatorTableId ==
                              creator['id'] as String?,
                          onTap: () {
                            setState(() {
                              _selectedCreatorTableId =
                                  creator['id'] as String?;
                              _creatorsSubPage = _CreatorsSubPage.creatorEvents;
                            });
                          },
                          trailing: IconButton(
                            icon: const Icon(Icons.edit, color: AppColors.pop),
                            onPressed: () => _openCreatorEditDialog(creator),
                          ),
                          leading: IconButton(
                            tooltip: 'Löschen',
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.redAccent),
                            onPressed: () {
                              final id = creator['id'] as String?;
                              if (id == null) return;
                              _deleteCmsRowAndRefresh(
                                  table: 'creators', id: id);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (_creatorsSubPage == _CreatorsSubPage.creatorEvents)
                CmsAdminCard(
                  title: 'Creator-Events',
                  subtitle: _selectedCreatorTableId == null
                      ? 'Bitte zuerst einen Creator auswählen.'
                      : 'Events des ausgewählten Creators bearbeiten.',
                  child: Column(
                    children: [
                      CmsSearchSortBar(
                        searchHint: 'Suche Titel / Typ …',
                        onSearchChanged: (value) => setState(
                            () => _creatorEventsTableSearchQuery = value),
                        sortKey: _creatorEventsSortKey,
                        ascending: _creatorEventsSortAsc,
                        sortOptions: const {
                          'title': 'Titel',
                          'event_kind': 'Event-Typ',
                          'episode_number': 'Episode',
                          'created_at': 'Erstellt am',
                        },
                        onSortChanged: (value) {
                          if (value != null) {
                            setState(() => _creatorEventsSortKey = value);
                          }
                        },
                        onToggleDirection: () => setState(() =>
                            _creatorEventsSortAsc = !_creatorEventsSortAsc),
                      ),
                      const SizedBox(height: 10),
                      if (_selectedCreatorTableId == null)
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Kein Creator ausgewählt',
                            style: TextStyle(color: Colors.white54),
                          ),
                        ),
                      ...sortedCreatorEvents.map(
                        (event) => ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            (event['title'] as String?) ?? '(ohne Titel)',
                            style: const TextStyle(color: Colors.white),
                          ),
                          subtitle: _buildRowDetails([
                            'Typ: ${(event['event_kind'] as String?) ?? '-'} · Episode: ${event['episode_number'] ?? '-'}',
                            'Show: ${_showTitleById(state, event['related_show_id'] as String?)}',
                            'Beschreibung: ${(event['description'] as String?) ?? '-'}',
                          ]),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit, color: AppColors.pop),
                            onPressed: () => _openCreatorEventEditDialog(event),
                          ),
                          leading: IconButton(
                            tooltip: 'Löschen',
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.redAccent),
                            onPressed: () {
                              final id = event['id'] as String?;
                              if (id == null) return;
                              _deleteCmsRowAndRefresh(
                                  table: 'creator_events', id: id);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (_creatorsSubPage == _CreatorsSubPage.actions) ...[
                // _buildActionStepper(
                //   labels: const ['Creator', 'Event-Block', 'Einzel-Event'],
                //   current:
                //       _creatorActionMode == _CreatorActionMode.createCreator
                //           ? 0
                //           : _creatorActionMode == _CreatorActionMode.blockEvents
                //               ? 1
                //               : 2,
                //   onTap: (index) {
                //     setState(() {
                //       _clearInlineError();
                //       _creatorActionMode = switch (index) {
                //         0 => _CreatorActionMode.createCreator,
                //         1 => _CreatorActionMode.blockEvents,
                //         _ => _CreatorActionMode.createEvent,
                //       };
                //       _creatorsSubPage = _CreatorsSubPage.actions;
                //     });
                //   },
                // ),
                if (_creatorActionMode == _CreatorActionMode.createCreator)
                  CmsAdminCard(
                    title: 'Creator anlegen',
                    subtitle: 'Neue Zeile in creators.',
                    child: Column(
                      children: [
                        _buildFlowHint(
                            'Pflichtfeld: Creator-Name. Social-Links und Avatar koennen spaeter ergaenzt werden.'),
                        _buildInlineValidationMessage(),
                        TextField(
                          controller: _creatorNameController,
                          style: const TextStyle(color: Colors.white),
                          decoration: cmsInputDecoration('Name *'),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _creatorDescriptionController,
                          style: const TextStyle(color: Colors.white),
                          decoration: cmsInputDecoration('Beschreibung'),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _creatorAvatarController,
                          style: const TextStyle(color: Colors.white),
                          decoration: cmsInputDecoration('Avatar URL'),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _creatorYoutubeController,
                          style: const TextStyle(color: Colors.white),
                          decoration: cmsInputDecoration('YouTube Kanal URL'),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _creatorInstagramController,
                          style: const TextStyle(color: Colors.white),
                          decoration: cmsInputDecoration('Instagram URL'),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _creatorTiktokController,
                          style: const TextStyle(color: Colors.white),
                          decoration: cmsInputDecoration('TikTok URL'),
                        ),
                        const SizedBox(height: 6),
                      ],
                    ),
                  ),
                const SizedBox(height: 14),
                if (_creatorActionMode == _CreatorActionMode.blockEvents)
                  CmsAdminCard(
                    title: 'Event-Block pro Staffel',
                    subtitle:
                        'Automatisch 1 Creator Event pro Episode erstellen.',
                    child: Column(
                      children: [
                        _buildFlowHint(
                            'Ein Block erzeugt automatisch Creator-Events pro Episode der gewaehlten Staffel.'),
                        _buildInlineValidationMessage(),
                        CmsCreatorDropdown(
                          creators: state.availableCreators,
                          value: _blockCreatorId,
                          onChanged: (v) => setState(() => _blockCreatorId = v),
                        ),
                        const SizedBox(height: 8),
                        CmsSearchableShowField(
                          shows: state.availableShows,
                          selectedShowId: _blockShowId,
                          label: 'Show *',
                          onChanged: (v) async {
                            setState(() => _blockShowId = v);
                            if (v != null) await _loadBlockSeasons(v);
                          },
                        ),
                        const SizedBox(height: 8),
                        CmsSeasonDropdown(
                          seasons: _blockSeasons,
                          value: _blockSeasonId,
                          onChanged: (v) => setState(() => _blockSeasonId = v),
                          label: 'Staffel *',
                        ),
                        const SizedBox(height: 8),
                        CmsEventKindDropdown(
                          value: _blockEventKind,
                          onChanged: (v) => setState(() => _blockEventKind = v),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _blockTitlePrefixController,
                          style: const TextStyle(color: Colors.white),
                          decoration:
                              cmsInputDecoration('Titel-Präfix (optional)'),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _blockDescriptionController,
                          style: const TextStyle(color: Colors.white),
                          decoration: cmsInputDecoration(
                              'Beschreibungsvorlage (optional)'),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 6),
                      ],
                    ),
                  ),
                const SizedBox(height: 14),
                if (_creatorActionMode == _CreatorActionMode.createEvent)
                  CmsAdminCard(
                    title: 'Einzelnes Creator Event',
                    subtitle: 'Manuelle Anpassungen/Overrides.',
                    child: Column(
                      children: [
                        _buildFlowHint(
                            'Ideal fuer Ausnahmen und Sonderfaelle. Optionales Datum plant direkt im Kalender.'),
                        _buildInlineValidationMessage(),
                        CmsCreatorDropdown(
                          creators: state.availableCreators,
                          value: _detailCreatorId,
                          onChanged: (v) =>
                              setState(() => _detailCreatorId = v),
                        ),
                        const SizedBox(height: 8),
                        CmsSearchableShowField(
                          shows: state.availableShows,
                          selectedShowId: _detailShowId,
                          label: 'Show (optional)',
                          onChanged: (v) async {
                            setState(() => _detailShowId = v);
                            if (v != null) await _loadDetailSeasons(v);
                          },
                        ),
                        const SizedBox(height: 8),
                        CmsSeasonDropdown(
                          seasons: _detailSeasons,
                          value: _detailSeasonId,
                          onChanged: (v) => setState(() => _detailSeasonId = v),
                          label: 'Staffel (optional)',
                        ),
                        const SizedBox(height: 8),
                        CmsEventKindDropdown(
                          value: _detailEventKind,
                          onChanged: (v) =>
                              setState(() => _detailEventKind = v),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _detailEpisodeNumberController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white),
                          decoration:
                              cmsInputDecoration('Episode Nummer (optional)'),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _detailTitleController,
                          style: const TextStyle(color: Colors.white),
                          decoration: cmsInputDecoration('Titel'),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _detailDescriptionController,
                          style: const TextStyle(color: Colors.white),
                          decoration: cmsInputDecoration('Beschreibung'),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _detailYoutubeUrlController,
                          style: const TextStyle(color: Colors.white),
                          decoration: cmsInputDecoration('YouTube Video URL'),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _detailThumbnailUrlController,
                          style: const TextStyle(color: Colors.white),
                          decoration: cmsInputDecoration('Thumbnail URL'),
                        ),
                        const SizedBox(height: 8),
                        CmsDateTimePickerField(
                          label: 'Kalenderplanung (optional)',
                          value: _detailDateTime,
                          onChanged: (value) =>
                              setState(() => _detailDateTime = value),
                        ),
                        const SizedBox(height: 6),
                      ],
                    ),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTrashSection(ContentState state) {
    final filteredTrashEvents = state.trashEvents.where((event) {
      if (_trashEventsTableSearchQuery.trim().isEmpty) return true;
      final title = (event['title'] as String? ?? '').toLowerCase();
      final location = (event['location'] as String? ?? '').toLowerCase();
      final query = _trashEventsTableSearchQuery.trim().toLowerCase();
      return title.contains(query) || location.contains(query);
    }).toList();
    final sortedTrashEvents = [...filteredTrashEvents]..sort((a, b) =>
        _compareMapValues(a, b, _trashEventsSortKey, _trashEventsSortAsc));

    return Column(
      children: [
        const SizedBox(height: 16),
        SizedBox(
          height: 44,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            children: [
              _subPageChip(
                label: 'Übersicht',
                selected: _trashSubPage == _TrashSubPage.trashEvents,
                onTap: () =>
                    setState(() => _trashSubPage = _TrashSubPage.trashEvents),
              ),
              _subPageChip(
                label: 'Event/Serie anlegen',
                selected: _trashSubPage == _TrashSubPage.actions,
                onTap: () =>
                    setState(() => _trashSubPage = _TrashSubPage.actions),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (_trashSubPage == _TrashSubPage.trashEvents)
                CmsLocationInfo(
                    'Aktuelle Filterung: ${_trashShowId == null ? 'keine Show gesetzt' : _showTitleById(state, _trashShowId)}'),
              if (_trashSubPage == _TrashSubPage.trashEvents)
                CmsAdminCard(
                  title: 'Trash-Events',
                  subtitle: 'Übersicht und Bearbeitung.',
                  child: Column(
                    children: [
                      CmsSearchSortBar(
                        searchHint: 'Suche Titel / Ort …',
                        onSearchChanged: (value) => setState(
                            () => _trashEventsTableSearchQuery = value),
                        sortKey: _trashEventsSortKey,
                        ascending: _trashEventsSortAsc,
                        sortOptions: const {
                          'title': 'Titel',
                          'location': 'Ort',
                          'price': 'Preis',
                          'created_at': 'Erstellt am',
                        },
                        onSortChanged: (value) {
                          if (value != null) {
                            setState(() => _trashEventsSortKey = value);
                          }
                        },
                        onToggleDirection: () => setState(
                            () => _trashEventsSortAsc = !_trashEventsSortAsc),
                      ),
                      const SizedBox(height: 10),
                      if (sortedTrashEvents.isEmpty)
                        _buildEmptyState(
                          icon: Icons.delete_sweep_outlined,
                          title: 'Keine Trash-Events gefunden',
                          subtitle:
                              'Lege ein neues Event an oder entferne aktive Filter.',
                        ),
                      ...sortedTrashEvents.map(
                        (event) => ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            (event['title'] as String?) ?? '(ohne Titel)',
                            style: const TextStyle(color: Colors.white),
                          ),
                          subtitle: _buildRowDetails([
                            'Ort: ${(event['location'] as String?) ?? '-'} · Adresse: ${(event['address'] as String?) ?? '-'}',
                            'Veranstalter: ${(event['organizer'] as String?) ?? '-'} · Preis: ${(event['price'] as String?) ?? '-'}',
                            'Show: ${_showTitleById(state, event['related_show_id'] as String?)}',
                          ]),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit, color: AppColors.pop),
                            onPressed: () => _openTrashEventEditDialog(event),
                          ),
                          leading: IconButton(
                            tooltip: 'Löschen',
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.redAccent),
                            onPressed: () {
                              final id = event['id'] as String?;
                              if (id == null) return;
                              _deleteCmsRowAndRefresh(
                                  table: 'trash_events', id: id);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (_trashSubPage == _TrashSubPage.actions)
                CmsAdminCard(
                  title: 'Trash Event / Serie anlegen',
                  subtitle:
                      'Einzeln oder als Reihe in bestimmten Abständen erstellen.',
                  child: Column(
                    children: [
                      _buildFlowHint(
                          'Bei Serien: Wiederholung + Anzahl setzen. Bei Einzelterminen Wiederholung auf "Keine" lassen.'),
                      _buildInlineValidationMessage(),
                      TextField(
                        controller: _trashTitleController,
                        style: const TextStyle(color: Colors.white),
                        decoration: cmsInputDecoration('Titel *'),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _trashDescriptionController,
                        style: const TextStyle(color: Colors.white),
                        decoration: cmsInputDecoration('Beschreibung'),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _trashImageUrlController,
                        style: const TextStyle(color: Colors.white),
                        decoration: cmsInputDecoration('Bild URL'),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _trashLocationController,
                        style: const TextStyle(color: Colors.white),
                        decoration: cmsInputDecoration('Ort'),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _trashAddressController,
                        style: const TextStyle(color: Colors.white),
                        decoration: cmsInputDecoration('Adresse'),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _trashOrganizerController,
                        style: const TextStyle(color: Colors.white),
                        decoration: cmsInputDecoration('Veranstalter'),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _trashPriceController,
                        style: const TextStyle(color: Colors.white),
                        decoration: cmsInputDecoration('Preis'),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _trashExternalUrlController,
                        style: const TextStyle(color: Colors.white),
                        decoration: cmsInputDecoration('Externe URL'),
                      ),
                      const SizedBox(height: 8),
                      CmsSearchableShowField(
                        shows: state.availableShows,
                        selectedShowId: _trashShowId,
                        label: 'Zugehörige Show (optional)',
                        onChanged: (v) async {
                          setState(() => _trashShowId = v);
                          if (v != null) {
                            await _loadTrashSeasons(v);
                          } else {
                            setState(() {
                              _trashSeasons = const [];
                              _trashSeasonId = null;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 8),
                      CmsSeasonDropdown(
                        seasons: _trashSeasons,
                        value: _trashSeasonId,
                        onChanged: (v) => setState(() => _trashSeasonId = v),
                        label: 'Zugehörige Staffel (optional)',
                      ),
                      const SizedBox(height: 8),
                      CmsDateTimePickerField(
                        label: 'Starttermin *',
                        value: _trashDateTime,
                        onChanged: (value) =>
                            setState(() => _trashDateTime = value),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: _trashRepeatMode,
                        decoration: cmsInputDecoration('Wiederholung'),
                        dropdownColor: const Color(0xFF1F1F1F),
                        style: const TextStyle(color: Colors.white),
                        items: const [
                          DropdownMenuItem(value: 'none', child: Text('Keine')),
                          DropdownMenuItem(
                              value: 'daily', child: Text('Täglich')),
                          DropdownMenuItem(
                              value: 'weekly', child: Text('Wöchentlich')),
                          DropdownMenuItem(
                              value: 'biweekly', child: Text('Alle 2 Wochen')),
                          DropdownMenuItem(
                              value: 'monthly', child: Text('Monatlich')),
                          DropdownMenuItem(
                              value: 'custom_days',
                              child: Text('Custom (Tage)')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _trashRepeatMode = value);
                          }
                        },
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _trashOccurrencesController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: cmsInputDecoration('Anzahl Termine'),
                      ),
                      if (_trashRepeatMode == 'custom_days') ...[
                        const SizedBox(height: 8),
                        TextField(
                          controller: _trashCustomDaysController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white),
                          decoration: cmsInputDecoration('Intervall in Tagen'),
                        ),
                      ],
                      const SizedBox(height: 6),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeedSection(ContentState state) {
    final notifier = ref.read(contentNotifierProvider.notifier);
    final filteredFeedItems = state.feedItems.where((item) {
      if (_feedItemsSearchQuery.trim().isEmpty) return true;
      final query = _feedItemsSearchQuery.trim().toLowerCase();
      final type = (item['item_type'] as String? ?? '').toLowerCase();
      final data = (item['data'] as Map<String, dynamic>? ?? const {});
      final quote = (data['quote'] as String? ?? '').toLowerCase();
      final speaker = (data['speaker_name'] as String? ?? '').toLowerCase();
      final show = (data['show_title'] as String? ?? '').toLowerCase();
      return type.contains(query) ||
          quote.contains(query) ||
          speaker.contains(query) ||
          show.contains(query);
    }).toList();

    final sortedFeedItems = [...filteredFeedItems]..sort((a, b) =>
        _compareMapValues(a, b, _feedItemsSortKey, _feedItemsSortAsc));
    final filteredNewsTickerItems = state.newsTickerItems.where((item) {
      if (_newsTickerItemsSearchQuery.trim().isEmpty) return true;
      final query = _newsTickerItemsSearchQuery.trim().toLowerCase();
      final headline = (item['headline'] as String? ?? '').toLowerCase();
      final isActive = (item['is_active'] ?? false).toString().toLowerCase();
      return headline.contains(query) || isActive.contains(query);
    }).toList();

    final sortedNewsTickerItems = [...filteredNewsTickerItems]..sort((a, b) =>
        _compareMapValues(
            a, b, _newsTickerItemsSortKey, _newsTickerItemsSortAsc));

    return Column(
      children: [
        const SizedBox(height: 16),
        SizedBox(
          height: 44,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            children: [
              _subPageChip(
                label: 'Übersicht',
                selected: _feedSubPage == _FeedSubPage.overview,
                onTap: () =>
                    setState(() => _feedSubPage = _FeedSubPage.overview),
              ),
              _subPageChip(
                label: 'Feed-Karte anlegen',
                selected: _feedSubPage == _FeedSubPage.actions,
                onTap: () =>
                    setState(() => _feedSubPage = _FeedSubPage.actions),
              ),
              _subPageChip(
                label: 'Newsticker',
                selected: _feedSubPage == _FeedSubPage.newsTicker,
                onTap: () =>
                    setState(() => _feedSubPage = _FeedSubPage.newsTicker),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (_feedSubPage == _FeedSubPage.overview)
                CmsLocationInfo(
                    'Alle aktuellen Feed-Karten (${state.feedItems.length})'),
              if (_feedSubPage == _FeedSubPage.overview)
                CmsAdminCard(
                  title: 'Feed-Karten',
                  subtitle:
                      'Karten ansehen und Reihenfolge per Priorität verschieben.',
                  child: Column(
                    children: [
                      CmsSearchSortBar(
                        searchHint: 'Suche Typ / Zitat / Show / Sprecher …',
                        onSearchChanged: (value) =>
                            setState(() => _feedItemsSearchQuery = value),
                        sortKey: _feedItemsSortKey,
                        ascending: _feedItemsSortAsc,
                        sortOptions: const {
                          'priority': 'Priorität',
                          'feed_timestamp': 'Zeitpunkt',
                          'item_type': 'Typ',
                        },
                        onSortChanged: (value) {
                          if (value != null) {
                            setState(() => _feedItemsSortKey = value);
                          }
                        },
                        onToggleDirection: () => setState(
                            () => _feedItemsSortAsc = !_feedItemsSortAsc),
                      ),
                      const SizedBox(height: 10),
                      ...sortedFeedItems.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final item = entry.value;
                        final data =
                            (item['data'] as Map<String, dynamic>? ?? const {});
                        final quote = data['quote'] as String?;
                        final speaker = data['speaker_name'] as String?;
                        final show = data['show_title'] as String?;
                        final season = data['season_number']?.toString();
                        final episode = data['episode_number']?.toString();

                        final context = StringBuffer();
                        if (speaker != null && speaker.trim().isNotEmpty) {
                          context.write(speaker.trim());
                        }
                        if (show != null && show.trim().isNotEmpty) {
                          if (context.isNotEmpty) context.write(' · ');
                          context.write(show.trim());
                        }
                        if ((season != null && season.isNotEmpty) ||
                            (episode != null && episode.isNotEmpty)) {
                          if (context.isNotEmpty) context.write(' · ');
                          if (season != null && season.isNotEmpty) {
                            context.write('S$season');
                          }
                          if (episode != null && episode.isNotEmpty) {
                            if (season != null && season.isNotEmpty) {
                              context.write(' · ');
                            }
                            context.write('E$episode');
                          }
                        }

                        return ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            '${item['item_type'] ?? '-'} · P${item['priority'] ?? '-'}',
                            style: const TextStyle(color: Colors.white),
                          ),
                          subtitle: _buildRowDetails([
                            'Zeitpunkt: ${(item['feed_timestamp'] ?? '-').toString()}',
                            if (quote != null && quote.trim().isNotEmpty)
                              'Zitat: "${quote.trim()}"',
                            if (context.isNotEmpty)
                              'Kontext: ${context.toString()}',
                          ]),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Bearbeiten',
                                onPressed: () => _openFeedItemEditDialog(item),
                                icon: const Icon(
                                  Icons.edit,
                                  color: AppColors.pop,
                                ),
                              ),
                              IconButton(
                                tooltip: 'Nach oben',
                                onPressed: idx == 0
                                    ? null
                                    : () => notifier.moveFeedItem(
                                          feedItemId: item['id'] as String,
                                          moveUp: true,
                                        ),
                                icon: const Icon(
                                  Icons.keyboard_arrow_up,
                                  color: AppColors.pop,
                                ),
                              ),
                              IconButton(
                                tooltip: 'Nach unten',
                                onPressed: idx == sortedFeedItems.length - 1
                                    ? null
                                    : () => notifier.moveFeedItem(
                                          feedItemId: item['id'] as String,
                                          moveUp: false,
                                        ),
                                icon: const Icon(
                                  Icons.keyboard_arrow_down,
                                  color: AppColors.pop,
                                ),
                              ),
                              IconButton(
                                tooltip: 'Löschen',
                                onPressed: () => _deleteCmsRowAndRefresh(
                                  table: 'feed_items',
                                  id: item['id'] as String,
                                ),
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.redAccent,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              if (_feedSubPage == _FeedSubPage.actions)
                CmsAdminCard(
                  title: _feedActionMode == _FeedActionMode.quoteOfWeek
                      ? 'Feed-Karte: Spruch der Woche'
                      : 'Feed-Karte: Throwback',
                  subtitle: _feedActionMode == _FeedActionMode.quoteOfWeek
                      ? 'Zitat mit Kontext anlegen. Die Karte erscheint danach automatisch im Feed.'
                      : 'Legendären Moment inkl. Show-Kontext als Throwback im Feed anlegen.',
                  child: Column(
                    children: [
                      _buildFlowHint(
                          'Zuerst Kartenmodus waehlen, dann nur die markierten Pflichtfelder ausfuellen.'),
                      _buildActionStepper(
                        labels: const ['Spruch', 'Throwback'],
                        current: _feedActionMode == _FeedActionMode.quoteOfWeek
                            ? 0
                            : 1,
                        onTap: (index) {
                          setState(() {
                            _clearInlineError();
                            _feedActionMode = index == 0
                                ? _FeedActionMode.quoteOfWeek
                                : _FeedActionMode.throwback;
                          });
                        },
                      ),
                      _buildInlineValidationMessage(),
                      const SizedBox(height: 4),
                      if (_feedActionMode == _FeedActionMode.quoteOfWeek) ...[
                        TextField(
                          controller: _quoteTextController,
                          style: const TextStyle(color: Colors.white),
                          maxLines: 2,
                          decoration: cmsInputDecoration('Zitat *'),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _quoteSpeakerController,
                          style: const TextStyle(color: Colors.white),
                          decoration: cmsInputDecoration('Gesagt von *'),
                        ),
                        const SizedBox(height: 8),
                        CmsSearchableShowField(
                          shows: state.availableShows,
                          selectedShowId: _quoteShowId,
                          label: 'Show *',
                          onChanged: (value) =>
                              setState(() => _quoteShowId = value),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _quoteSeasonController,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(color: Colors.white),
                                decoration:
                                    cmsInputDecoration('Staffel (z. B. 12)'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _quoteEpisodeController,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(color: Colors.white),
                                decoration:
                                    cmsInputDecoration('Episode (z. B. 7)'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _quoteCtaController,
                          style: const TextStyle(color: Colors.white),
                          decoration:
                              cmsInputDecoration('CTA Label (optional)'),
                        ),
                      ],
                      if (_feedActionMode == _FeedActionMode.throwback) ...[
                        TextField(
                          controller: _throwbackLabelController,
                          style: const TextStyle(color: Colors.white),
                          decoration: cmsInputDecoration(
                              'Label (z. B. Throwback der Woche) *'),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _throwbackMomentController,
                          style: const TextStyle(color: Colors.white),
                          maxLines: 3,
                          decoration: cmsInputDecoration('Legendärer Moment *'),
                        ),
                        const SizedBox(height: 8),
                        CmsSearchableShowField(
                          shows: state.availableShows,
                          selectedShowId: _throwbackShowId,
                          label: 'Show *',
                          onChanged: (value) =>
                              setState(() => _throwbackShowId = value),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _throwbackSeasonController,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(color: Colors.white),
                                decoration:
                                    cmsInputDecoration('Staffel (optional)'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _throwbackEpisodeController,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(color: Colors.white),
                                decoration:
                                    cmsInputDecoration('Episode (optional)'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _throwbackStickerController,
                          style: const TextStyle(color: Colors.white),
                          decoration: cmsInputDecoration(
                              'Sticker (optional, z. B. OG Moment)'),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _throwbackCtaController,
                          style: const TextStyle(color: Colors.white),
                          decoration:
                              cmsInputDecoration('CTA Label (optional)'),
                        ),
                      ],
                      const SizedBox(height: 6),
                    ],
                  ),
                ),
              if (_feedSubPage == _FeedSubPage.newsTicker)
                CmsLocationInfo(
                    'Alle aktuellen Newsticker-Einträge (${state.newsTickerItems.length})'),
              if (_feedSubPage == _FeedSubPage.newsTicker)
                CmsAdminCard(
                  title: 'Newsticker',
                  subtitle:
                      'Top-Bar Headlines verwalten, aktivieren und in der Reihenfolge sortieren.',
                  child: Column(
                    children: [
                      CmsSearchSortBar(
                        searchHint: 'Suche Headline / Status …',
                        onSearchChanged: (value) =>
                            setState(() => _newsTickerItemsSearchQuery = value),
                        sortKey: _newsTickerItemsSortKey,
                        ascending: _newsTickerItemsSortAsc,
                        sortOptions: const {
                          'priority': 'Prioritat',
                          'headline': 'Headline',
                          'is_active': 'Aktiv',
                          'updated_at': 'Zuletzt aktualisiert',
                        },
                        onSortChanged: (value) {
                          if (value != null) {
                            setState(() => _newsTickerItemsSortKey = value);
                          }
                        },
                        onToggleDirection: () => setState(() =>
                            _newsTickerItemsSortAsc = !_newsTickerItemsSortAsc),
                      ),
                      const SizedBox(height: 10),
                      ...sortedNewsTickerItems.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final item = entry.value;
                        final isActive = item['is_active'] == true;
                        return ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            (item['headline'] as String? ?? '-').trim(),
                            style: const TextStyle(color: Colors.white),
                          ),
                          subtitle: _buildRowDetails([
                            'Priorität: ${item['priority'] ?? '-'} · Status: ${isActive ? 'aktiv' : 'inaktiv'}',
                            'Zuletzt aktualisiert: ${(item['updated_at'] ?? '-').toString()}',
                          ]),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Bearbeiten',
                                onPressed: () =>
                                    _openNewsTickerItemEditDialog(item),
                                icon: const Icon(
                                  Icons.edit,
                                  color: AppColors.pop,
                                ),
                              ),
                              IconButton(
                                tooltip: 'Nach oben',
                                onPressed: idx == 0
                                    ? null
                                    : () => notifier.moveNewsTickerItem(
                                          newsTickerItemId:
                                              item['id'] as String,
                                          moveUp: true,
                                        ),
                                icon: const Icon(
                                  Icons.keyboard_arrow_up,
                                  color: AppColors.pop,
                                ),
                              ),
                              IconButton(
                                tooltip: 'Nach unten',
                                onPressed:
                                    idx == sortedNewsTickerItems.length - 1
                                        ? null
                                        : () => notifier.moveNewsTickerItem(
                                              newsTickerItemId:
                                                  item['id'] as String,
                                              moveUp: false,
                                            ),
                                icon: const Icon(
                                  Icons.keyboard_arrow_down,
                                  color: AppColors.pop,
                                ),
                              ),
                              IconButton(
                                tooltip: 'Löschen',
                                onPressed: () => _deleteCmsRowAndRefresh(
                                  table: 'news_ticker_items',
                                  id: item['id'] as String,
                                ),
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.redAccent,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const Divider(height: 24, color: Colors.white12),
                      TextField(
                        controller: _newsTickerHeadlineController,
                        style: const TextStyle(color: Colors.white),
                        maxLines: 2,
                        decoration: cmsInputDecoration('Neue Headline *'),
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _newsTickerIsActive,
                        onChanged: (value) =>
                            setState(() => _newsTickerIsActive = value),
                        title: const Text(
                          'Sofort aktiv schalten',
                          style: TextStyle(color: Colors.white),
                        ),
                        activeThumbColor: AppColors.pop,
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            final headline =
                                _newsTickerHeadlineController.text.trim();
                            if (headline.isEmpty) return;
                            await notifier.addNewsTickerItem(
                              headline: headline,
                              isActive: _newsTickerIsActive,
                            );
                            _newsTickerHeadlineController.clear();
                            if (mounted) {
                              setState(() => _newsTickerIsActive = true);
                            }
                          },
                          child: const Text('Newsticker-Eintrag speichern'),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  DateTime? _parseDateTimeValue(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value.toLocal();
    if (value is String && value.trim().isNotEmpty) {
      return DateTime.tryParse(value)?.toLocal();
    }
    return null;
  }

  DateTime? _parseDateOnlyValue(dynamic value) {
    if (value is! String || value.trim().isEmpty) return null;
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return null;
    return DateTime(parsed.year, parsed.month, parsed.day);
  }

  DateTime? _parseUtcSeasonReleaseToLocal(
      dynamic dateValue, dynamic timeValue) {
    if (dateValue is! String || dateValue.trim().isEmpty) return null;
    final parsedDate = DateTime.tryParse(dateValue);
    if (parsedDate == null) return null;

    final rawTime = timeValue?.toString().trim();
    final parts = (rawTime == null || rawTime.isEmpty)
        ? const <String>[]
        : rawTime.split(':');
    final hour = parts.isNotEmpty ? int.tryParse(parts[0]) ?? 0 : 0;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    final second =
        parts.length > 2 ? int.tryParse(parts[2].split('.').first) ?? 0 : 0;

    return DateTime.utc(
      parsedDate.year,
      parsedDate.month,
      parsedDate.day,
      hour,
      minute,
      second,
    ).toLocal();
  }

  Future<void> _openShowTableRowEditDialog(Map<String, dynamic> showRow) async {
    final notifier = ref.read(contentNotifierProvider.notifier);
    final titleController =
        TextEditingController(text: showRow['title'] as String? ?? '');
    final shortTitleController =
        TextEditingController(text: showRow['short_title'] as String? ?? '');
    final descriptionController =
        TextEditingController(text: showRow['description'] as String? ?? '');
    final genreController =
        TextEditingController(text: showRow['genre'] as String? ?? '');
    final releaseWindowController =
        TextEditingController(text: showRow['release_window'] as String? ?? '');
    final statusController =
        TextEditingController(text: showRow['status'] as String? ?? '');
    final slugController =
        TextEditingController(text: showRow['slug'] as String? ?? '');
    final tmdbController =
        TextEditingController(text: showRow['tmdb_id'] as String? ?? '');
    final traktController =
        TextEditingController(text: showRow['trakt_slug'] as String? ?? '');
    final headerImageUrlController =
        TextEditingController(text: showRow['header_image'] as String? ?? '');
    final mainColorController =
        TextEditingController(text: showRow['main_color'] as String? ?? '');

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Show bearbeiten',
            style: TextStyle(color: Colors.white)),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: titleController,
                  style: const TextStyle(color: Colors.white),
                  decoration: cmsInputDecoration('Titel'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: shortTitleController,
                  style: const TextStyle(color: Colors.white),
                  decoration: cmsInputDecoration('Kurztitel'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descriptionController,
                  style: const TextStyle(color: Colors.white),
                  decoration: cmsInputDecoration('Beschreibung'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: genreController,
                  style: const TextStyle(color: Colors.white),
                  decoration: cmsInputDecoration('Genre'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: releaseWindowController,
                  style: const TextStyle(color: Colors.white),
                  decoration: cmsInputDecoration('Release Window'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: statusController,
                  style: const TextStyle(color: Colors.white),
                  decoration: cmsInputDecoration('Status'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: slugController,
                  style: const TextStyle(color: Colors.white),
                  decoration: cmsInputDecoration('Slug'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: tmdbController,
                  style: const TextStyle(color: Colors.white),
                  decoration: cmsInputDecoration('TMDB ID'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: traktController,
                  style: const TextStyle(color: Colors.white),
                  decoration: cmsInputDecoration('Trakt Slug'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: headerImageUrlController,
                  style: const TextStyle(color: Colors.white),
                  decoration: cmsInputDecoration('Header Image URL'),
                ),
                const SizedBox(height: 8),
                CmsColorPickerField(
                  controller: mainColorController,
                  label: 'Main Color (hex)',
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () async {
              await notifier.updateShow(
                showId: showRow['id'] as String,
                title: titleController.text.trim(),
                shortTitle: shortTitleController.text.trim(),
                description: descriptionController.text.trim(),
                genre: genreController.text.trim(),
                releaseWindow: releaseWindowController.text.trim(),
                status: statusController.text.trim(),
                slug: slugController.text.trim(),
                tmdbId: tmdbController.text.trim(),
                traktSlug: traktController.text.trim(),
                headerImageUrl: headerImageUrlController.text.trim(),
                mainColor: mainColorController.text.trim(),
              );
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
  }

  Future<void> _openSeasonTableRowEditDialog(
    Map<String, dynamic> season,
    List<Show> shows,
  ) async {
    final notifier = ref.read(contentNotifierProvider.notifier);
    final localReleaseDateTime = _parseUtcSeasonReleaseToLocal(
      season['streaming_release_date'],
      season['streaming_release_time'],
    );
    final numberController =
        TextEditingController(text: (season['season_number'] ?? '').toString());
    final episodesController = TextEditingController(
        text: (season['total_episodes'] ?? '').toString());
    final releaseTimeController = TextEditingController(
      text: localReleaseDateTime == null
          ? ''
          : '${localReleaseDateTime.hour.toString().padLeft(2, '0')}:${localReleaseDateTime.minute.toString().padLeft(2, '0')}',
    );
    final episodeLengthController = TextEditingController(
        text: (season['episode_length'] ?? '').toString());
    final streamingOptionController = TextEditingController(
        text: season['streaming_option'] as String? ?? '');
    final statusController =
        TextEditingController(text: season['status'] as String? ?? '');
    var selectedShowId = season['show_id'] as String?;
    var startDate = localReleaseDateTime == null
        ? _parseDateOnlyValue(season['streaming_release_date'])
        : DateTime(
            localReleaseDateTime.year,
            localReleaseDateTime.month,
            localReleaseDateTime.day,
          );
    var releaseFrequency =
        _normalizeFrequency(season['release_frequency'] as String? ?? 'weekly');
    final selectedDays =
        _parseMultiWeeklyDays(season['release_frequency'] as String? ?? '')
          ..addAll(releaseFrequency == 'multi_weekly' &&
                  _parseMultiWeeklyDays(
                          season['release_frequency'] as String? ?? '')
                      .isEmpty
              ? <int>{1, 4}
              : <int>{});

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1A1A1A),
              title: const Text('Staffel bearbeiten',
                  style: TextStyle(color: Colors.white)),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CmsSearchableShowField(
                        shows: shows,
                        selectedShowId: selectedShowId,
                        label: 'Show',
                        onChanged: (value) =>
                            setStateDialog(() => selectedShowId = value),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: numberController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: cmsInputDecoration('Staffel Nr.'),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: episodesController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: cmsInputDecoration('Episoden'),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        initialValue: releaseFrequency,
                        decoration: cmsInputDecoration('Release Frequency'),
                        dropdownColor: const Color(0xFF1F1F1F),
                        style: const TextStyle(color: Colors.white),
                        items: _releaseFrequencyOptions.entries
                            .map((entry) => DropdownMenuItem(
                                  value: entry.key,
                                  child: Text(entry.value),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setStateDialog(() => releaseFrequency = value);
                          }
                        },
                      ),
                      if (releaseFrequency == 'multi_weekly') ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: _weekdayLabels.entries.map((entry) {
                            final selected = selectedDays.contains(entry.key);
                            return FilterChip(
                              label: Text(entry.value),
                              selected: selected,
                              onSelected: (value) {
                                setStateDialog(() {
                                  if (value) {
                                    selectedDays.add(entry.key);
                                  } else {
                                    selectedDays.remove(entry.key);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ],
                      const SizedBox(height: 10),
                      CmsTimeTextField(
                        controller: releaseTimeController,
                        label: 'Streaming Release Time',
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: episodeLengthController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: cmsInputDecoration('Episode Length (Min)'),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: streamingOptionController,
                        style: const TextStyle(color: Colors.white),
                        decoration: cmsInputDecoration('Streaming Option'),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: statusController,
                        style: const TextStyle(color: Colors.white),
                        decoration: cmsInputDecoration('Status'),
                      ),
                      const SizedBox(height: 10),
                      CmsDatePickerField(
                        label: 'Startdatum',
                        value: startDate,
                        onChanged: (value) {
                          setStateDialog(() => startDate = value);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Abbrechen'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    var release = releaseFrequency;
                    if (releaseFrequency == 'multi_weekly' &&
                        selectedDays.isNotEmpty) {
                      final sorted = selectedDays.toList()..sort();
                      release = 'multi_weekly:${sorted.join(',')}';
                    }
                    await notifier.updateSeason(
                      seasonId: season['id'] as String,
                      showId: selectedShowId,
                      seasonNumber: int.tryParse(numberController.text),
                      totalEpisodes: int.tryParse(episodesController.text),
                      releaseFrequency: release,
                      startDate: startDate,
                      streamingReleaseTime: releaseTimeController.text.trim(),
                      episodeLength: int.tryParse(episodeLengthController.text),
                      streamingOption: streamingOptionController.text.trim(),
                      status: statusController.text.trim(),
                    );
                    if (_selectedShowTableId != null) {
                      await notifier
                          .loadSeasonsTableRowsByShowId(_selectedShowTableId!);
                    }
                    if (mounted) Navigator.pop(context);
                  },
                  child: const Text('Speichern'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _openShowEventEditDialog(Map<String, dynamic> event) async {
    final notifier = ref.read(contentNotifierProvider.notifier);
    final eventSubtypeController =
        TextEditingController(text: event['event_subtype'] as String? ?? '');
    final episodeController = TextEditingController(
        text: (event['episode_number'] as int?)?.toString() ?? '');
    final descriptionController =
        TextEditingController(text: event['description'] as String? ?? '');

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Show Event bearbeiten',
            style: TextStyle(color: Colors.white)),
        content: SizedBox(
          width: 520,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: eventSubtypeController,
                style: const TextStyle(color: Colors.white),
                decoration: cmsInputDecoration('Typ'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: episodeController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: cmsInputDecoration('Episode'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: descriptionController,
                style: const TextStyle(color: Colors.white),
                decoration: cmsInputDecoration('Beschreibung'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () async {
              await notifier.updateShowEvent(
                showEventId: event['id'] as String,
                eventSubtype: eventSubtypeController.text.trim(),
                episodeNumber: int.tryParse(episodeController.text),
                description: descriptionController.text.trim(),
              );
              if (_selectedSeasonTableId != null) {
                await notifier
                    .loadShowEventsBySeasonId(_selectedSeasonTableId!);
              }
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
  }

  Future<void> _openCalendarEventEditDialog(Map<String, dynamic> event) async {
    final notifier = ref.read(contentNotifierProvider.notifier);
    final eventTypeController =
        TextEditingController(text: event['event_type'] as String? ?? '');
    final dramaLevelController =
        TextEditingController(text: (event['drama_level'] ?? '').toString());
    final entityTypeController = TextEditingController(
        text: event['event_entity_type'] as String? ?? '');
    var startDateTime = _parseDateTimeValue(event['start_datetime']);
    var endDateTime = _parseDateTimeValue(event['end_datetime']);

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1A1A1A),
              title: const Text('Termin bearbeiten',
                  style: TextStyle(color: Colors.white)),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: eventTypeController,
                        style: const TextStyle(color: Colors.white),
                        decoration: cmsInputDecoration('Typ'),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: dramaLevelController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: cmsInputDecoration('Drama-Level'),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: entityTypeController,
                        style: const TextStyle(color: Colors.white),
                        decoration: cmsInputDecoration('Kategorie'),
                      ),
                      const SizedBox(height: 8),
                      CmsDateTimePickerField(
                        label: 'Start',
                        value: startDateTime,
                        onChanged: (value) {
                          setStateDialog(() => startDateTime = value);
                        },
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton(
                            onPressed: () {
                              if (startDateTime == null) return;
                              setStateDialog(() {
                                startDateTime = startDateTime!
                                    .subtract(const Duration(days: 1));
                              });
                            },
                            child: const Text('Start -1 Tag'),
                          ),
                          OutlinedButton(
                            onPressed: () {
                              if (startDateTime == null) return;
                              setStateDialog(() {
                                startDateTime =
                                    startDateTime!.add(const Duration(days: 1));
                              });
                            },
                            child: const Text('Start +1 Tag'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      CmsDateTimePickerField(
                        label: 'Ende',
                        value: endDateTime,
                        onChanged: (value) {
                          setStateDialog(() => endDateTime = value);
                        },
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton(
                            onPressed: () {
                              if (endDateTime == null) return;
                              setStateDialog(() {
                                endDateTime = endDateTime!
                                    .subtract(const Duration(days: 1));
                              });
                            },
                            child: const Text('Ende -1 Tag'),
                          ),
                          OutlinedButton(
                            onPressed: () {
                              if (endDateTime == null) return;
                              setStateDialog(() {
                                endDateTime =
                                    endDateTime!.add(const Duration(days: 1));
                              });
                            },
                            child: const Text('Ende +1 Tag'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Abbrechen'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await notifier.updateCalendarEvent(
                      calendarEventId: event['id'] as String,
                      startDatetime: startDateTime,
                      endDatetime: endDateTime,
                      eventType: eventTypeController.text.trim(),
                      dramaLevel: int.tryParse(dramaLevelController.text),
                      eventEntityType: entityTypeController.text.trim(),
                    );
                    if (_selectedShowEventTableId != null) {
                      await notifier.loadCalendarEventsByShowEventId(
                          _selectedShowEventTableId!);
                    }
                    if (mounted) Navigator.pop(context);
                  },
                  child: const Text('Speichern'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _openCreatorEditDialog(Map<String, dynamic> creator) async {
    final notifier = ref.read(contentNotifierProvider.notifier);
    final nameController =
        TextEditingController(text: creator['name'] as String? ?? '');
    final descriptionController =
        TextEditingController(text: creator['description'] as String? ?? '');
    final avatarController =
        TextEditingController(text: creator['avatar_url'] as String? ?? '');
    final youtubeController = TextEditingController(
        text: creator['youtube_channel_url'] as String? ?? '');
    final instagramController =
        TextEditingController(text: creator['instagram_url'] as String? ?? '');
    final tiktokController =
        TextEditingController(text: creator['tiktok_url'] as String? ?? '');

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Creator bearbeiten',
            style: TextStyle(color: Colors.white)),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: cmsInputDecoration('Name'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descriptionController,
                  style: const TextStyle(color: Colors.white),
                  decoration: cmsInputDecoration('Beschreibung'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: avatarController,
                  style: const TextStyle(color: Colors.white),
                  decoration: cmsInputDecoration('Avatar URL'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: youtubeController,
                  style: const TextStyle(color: Colors.white),
                  decoration: cmsInputDecoration('YouTube URL'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: instagramController,
                  style: const TextStyle(color: Colors.white),
                  decoration: cmsInputDecoration('Instagram URL'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: tiktokController,
                  style: const TextStyle(color: Colors.white),
                  decoration: cmsInputDecoration('TikTok URL'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () async {
              await notifier.updateCreator(
                creatorId: creator['id'] as String,
                name: nameController.text.trim(),
                description: descriptionController.text.trim(),
                avatarUrl: avatarController.text.trim(),
                youtubeChannelUrl: youtubeController.text.trim(),
                instagramUrl: instagramController.text.trim(),
                tiktokUrl: tiktokController.text.trim(),
              );
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
  }

  Future<void> _openCreatorEventEditDialog(Map<String, dynamic> event) async {
    final notifier = ref.read(contentNotifierProvider.notifier);
    final titleController =
        TextEditingController(text: event['title'] as String? ?? '');
    final descriptionController =
        TextEditingController(text: event['description'] as String? ?? '');
    final youtubeController =
        TextEditingController(text: event['youtube_url'] as String? ?? '');
    final thumbnailController =
        TextEditingController(text: event['thumbnail_url'] as String? ?? '');
    final episodeController = TextEditingController(
        text: (event['episode_number'] as int?)?.toString() ?? '');
    var kind = event['event_kind'] as String? ?? 'reaction_video';

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1A1A1A),
              title: const Text('Creator Event bearbeiten',
                  style: TextStyle(color: Colors.white)),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      CmsEventKindDropdown(
                        value: kind,
                        onChanged: (v) => setStateDialog(() => kind = v),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: titleController,
                        style: const TextStyle(color: Colors.white),
                        decoration: cmsInputDecoration('Titel'),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: descriptionController,
                        style: const TextStyle(color: Colors.white),
                        decoration: cmsInputDecoration('Beschreibung'),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: episodeController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: cmsInputDecoration('Episode Nummer'),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: youtubeController,
                        style: const TextStyle(color: Colors.white),
                        decoration: cmsInputDecoration('YouTube URL'),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: thumbnailController,
                        style: const TextStyle(color: Colors.white),
                        decoration: cmsInputDecoration('Thumbnail URL'),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Abbrechen'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await notifier.updateCreatorEvent(
                      creatorEventId: event['id'] as String,
                      eventKind: kind,
                      title: titleController.text.trim(),
                      description: descriptionController.text.trim(),
                      episodeNumber: int.tryParse(episodeController.text),
                      youtubeUrl: youtubeController.text.trim(),
                      thumbnailUrl: thumbnailController.text.trim(),
                    );
                    if (mounted) Navigator.pop(context);
                  },
                  child: const Text('Speichern'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _openTrashEventEditDialog(Map<String, dynamic> event) async {
    final notifier = ref.read(contentNotifierProvider.notifier);
    final titleController =
        TextEditingController(text: event['title'] as String? ?? '');
    final descriptionController =
        TextEditingController(text: event['description'] as String? ?? '');
    final locationController =
        TextEditingController(text: event['location'] as String? ?? '');
    final addressController =
        TextEditingController(text: event['address'] as String? ?? '');
    final organizerController =
        TextEditingController(text: event['organizer'] as String? ?? '');
    final priceController =
        TextEditingController(text: event['price'] as String? ?? '');
    final externalController =
        TextEditingController(text: event['external_url'] as String? ?? '');

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Trash Event bearbeiten',
            style: TextStyle(color: Colors.white)),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: titleController,
                  style: const TextStyle(color: Colors.white),
                  decoration: cmsInputDecoration('Titel'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descriptionController,
                  style: const TextStyle(color: Colors.white),
                  decoration: cmsInputDecoration('Beschreibung'),
                  maxLines: 2,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: locationController,
                  style: const TextStyle(color: Colors.white),
                  decoration: cmsInputDecoration('Ort'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: addressController,
                  style: const TextStyle(color: Colors.white),
                  decoration: cmsInputDecoration('Adresse'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: organizerController,
                  style: const TextStyle(color: Colors.white),
                  decoration: cmsInputDecoration('Veranstalter'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: priceController,
                  style: const TextStyle(color: Colors.white),
                  decoration: cmsInputDecoration('Preis'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: externalController,
                  style: const TextStyle(color: Colors.white),
                  decoration: cmsInputDecoration('Externe URL'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () async {
              await notifier.updateTrashEvent(
                trashEventId: event['id'] as String,
                title: titleController.text.trim(),
                description: descriptionController.text.trim(),
                location: locationController.text.trim(),
                address: addressController.text.trim(),
                organizer: organizerController.text.trim(),
                price: priceController.text.trim(),
                externalUrl: externalController.text.trim(),
              );
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
  }

  Future<void> _openFeedItemEditDialog(Map<String, dynamic> item) async {
    final notifier = ref.read(contentNotifierProvider.notifier);
    final itemTypeController =
        TextEditingController(text: item['item_type'] as String? ?? '');
    final priorityController =
        TextEditingController(text: (item['priority'] ?? '').toString());
    final timestampController =
        TextEditingController(text: (item['feed_timestamp'] ?? '').toString());

    final rawData = item['data'];
    Map<String, dynamic> dataMap = const {};
    if (rawData is Map<String, dynamic>) {
      dataMap = rawData;
    } else if (rawData is Map) {
      dataMap = Map<String, dynamic>.from(rawData);
    }
    final dataController = TextEditingController(
      text: const JsonEncoder.withIndent('  ').convert(dataMap),
    );

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'Feed-Item bearbeiten',
          style: TextStyle(color: Colors.white),
        ),
        content: SizedBox(
          width: 560,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: itemTypeController,
                  style: const TextStyle(color: Colors.white),
                  decoration: cmsInputDecoration('Item Type'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: priorityController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: cmsInputDecoration('Priority'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: timestampController,
                  style: const TextStyle(color: Colors.white),
                  decoration: cmsInputDecoration('Feed Timestamp (ISO 8601)'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: dataController,
                  style: const TextStyle(color: Colors.white),
                  decoration: cmsInputDecoration('Data JSON'),
                  maxLines: 12,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () async {
              Map<String, dynamic> parsedData;
              try {
                final decoded = jsonDecode(dataController.text.trim());
                if (decoded is! Map) {
                  throw const FormatException('JSON muss ein Objekt sein');
                }
                parsedData = Map<String, dynamic>.from(decoded);
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Ungültiges JSON: $e')),
                );
                return;
              }

              await notifier.updateFeedItem(
                feedItemId: item['id'] as String,
                itemType: itemTypeController.text.trim(),
                priority: int.tryParse(priorityController.text.trim()),
                feedTimestamp:
                    _parseDateTimeValue(timestampController.text.trim()),
                data: parsedData,
              );

              if (mounted) Navigator.pop(context);
            },
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
  }

  Future<void> _openNewsTickerItemEditDialog(Map<String, dynamic> item) async {
    final notifier = ref.read(contentNotifierProvider.notifier);
    final headlineController =
        TextEditingController(text: item['headline'] as String? ?? '');
    final priorityController = TextEditingController(
      text: (item['priority'] ?? '').toString(),
    );
    var isActive = item['is_active'] == true;

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text(
            'Newsticker-Eintrag bearbeiten',
            style: TextStyle(color: Colors.white),
          ),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    controller: headlineController,
                    style: const TextStyle(color: Colors.white),
                    maxLines: 2,
                    decoration: cmsInputDecoration('Headline'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: priorityController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: cmsInputDecoration('Priority'),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: isActive,
                    onChanged: (value) =>
                        setDialogState(() => isActive = value),
                    title: const Text(
                      'Aktiv',
                      style: TextStyle(color: Colors.white),
                    ),
                    activeThumbColor: AppColors.pop,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Abbrechen'),
            ),
            ElevatedButton(
              onPressed: () async {
                await notifier.updateNewsTickerItem(
                  newsTickerItemId: item['id'] as String,
                  headline: headlineController.text.trim(),
                  priority: int.tryParse(priorityController.text.trim()),
                  isActive: isActive,
                );

                if (mounted) Navigator.pop(context);
              },
              child: const Text('Speichern'),
            ),
          ],
        ),
      ),
    );
  }
}
