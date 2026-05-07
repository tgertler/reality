/// Flat entity from the `calendar_event_resolved` database view.
///
/// Each row represents exactly one calendar_event and is exactly one of:
/// show_event, creator_event, or trash_event.
///
/// Use [isShowEvent], [isCreatorEvent], [isTrashEvent] to determine the type
/// and access the corresponding data fields.
class ResolvedCalendarEvent {
  final String calendarEventId;
  final DateTime startDatetime;
  final DateTime endDatetime;

  // ── Type flags ────────────────────────────────────────────────────────────
  final bool isShowEvent;
  final bool isCreatorEvent;
  final bool isTrashEvent;

  // ── SHOW EVENT DATA ───────────────────────────────────────────────────────
  final String? showEventId;
  final String? showEventSubtype; // 'premiere' | 'episode' | 'finale'
  final int? showEventEpisodeNumber;
  final String? showEventDescription;
  final String? showEventShowId;
  final String? showEventSeasonId;
  final String? showEventShowTitle;
  final String? showEventShowShortTitle;
  final String? showEventShowDescription;
  final String? showEventGenre;
  final String? showEventStreamingOption;
  final int? showEventSeasonNumber;

  // ── CREATOR EVENT DATA ────────────────────────────────────────────────────
  final String? creatorId;
  final String? creatorEventId;
  final String? creatorEventKind;
  final String? creatorEventYoutubeUrl;
  final String? creatorEventThumbnailUrl;
  final int? creatorEventEpisodeNumber;
  final String? creatorEventTitle;
  final String? creatorEventDescription;
  final String? creatorName;
  final String? creatorAvatarUrl;
  final String? creatorYoutubeChannelUrl;
  final String? creatorInstagramUrl;
  final String? creatorTiktokUrl;
  final String? creatorRelatedShowId;
  final String? creatorRelatedSeasonId;

  // ── TRASH EVENT DATA ──────────────────────────────────────────────────────
  final String? trashEventId;
  final String? trashEventTitle;
  final String? trashEventDescription;
  final String? trashEventImageUrl;
  final String? trashEventLocation;
  final String? trashEventAddress;
  final String? trashEventOrganizer;
  final String? trashEventPrice;
  final String? trashEventExternalUrl;
  final String? trashRelatedShowId;
  final String? trashRelatedSeasonId;

  const ResolvedCalendarEvent({
    required this.calendarEventId,
    required this.startDatetime,
    required this.endDatetime,
    required this.isShowEvent,
    required this.isCreatorEvent,
    required this.isTrashEvent,
    this.showEventId,
    this.showEventSubtype,
    this.showEventEpisodeNumber,
    this.showEventDescription,
    this.showEventShowId,
    this.showEventSeasonId,
    this.showEventShowTitle,
    this.showEventShowShortTitle,
    this.showEventShowDescription,
    this.showEventGenre,
    this.showEventStreamingOption,
    this.showEventSeasonNumber,
    this.creatorId,
    this.creatorEventId,
    this.creatorEventKind,
    this.creatorEventYoutubeUrl,
    this.creatorEventThumbnailUrl,
    this.creatorEventEpisodeNumber,
    this.creatorEventTitle,
    this.creatorEventDescription,
    this.creatorName,
    this.creatorAvatarUrl,
    this.creatorYoutubeChannelUrl,
    this.creatorInstagramUrl,
    this.creatorTiktokUrl,
    this.creatorRelatedShowId,
    this.creatorRelatedSeasonId,
    this.trashEventId,
    this.trashEventTitle,
    this.trashEventDescription,
    this.trashEventImageUrl,
    this.trashEventLocation,
    this.trashEventAddress,
    this.trashEventOrganizer,
    this.trashEventPrice,
    this.trashEventExternalUrl,
    this.trashRelatedShowId,
    this.trashRelatedSeasonId,
  });

  /// The show ID related to this event — used for favourites filtering.
  String? get relatedShowId =>
      showEventShowId ?? creatorRelatedShowId ?? trashRelatedShowId;
}
