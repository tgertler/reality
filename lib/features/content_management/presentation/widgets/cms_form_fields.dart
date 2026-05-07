import 'package:flutter/material.dart';
import 'package:frontend/core/config/app_colors.dart';
import 'package:frontend/features/content_management/domain/entities/season.dart';
import 'package:frontend/features/content_management/domain/entities/show.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────
// Shared InputDecoration factory
// ─────────────────────────────────────────────

InputDecoration cmsInputDecoration(String label) {
  return InputDecoration(
    labelText: label,
    labelStyle: GoogleFonts.dmSans(color: Colors.white54),
    filled: true,
    fillColor: const Color(0xFF222834),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0x26FFFFFF)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.pop, width: 1.2),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
  );
}

String _two(int v) => v.toString().padLeft(2, '0');

String cmsFormatDate(DateTime value) {
  return '${_two(value.day)}.${_two(value.month)}.${value.year}';
}

String cmsFormatDateTime(DateTime value) {
  return '${cmsFormatDate(value)} ${_two(value.hour)}:${_two(value.minute)}';
}

String cmsFormatTimeOfDay(TimeOfDay value) {
  return '${_two(value.hour)}:${_two(value.minute)}';
}

class CmsDatePickerField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;

  const CmsDatePickerField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? now,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (picked != null) {
          onChanged(picked);
        }
      },
      child: InputDecorator(
        decoration: cmsInputDecoration(label).copyWith(
          suffixIcon: value == null
              ? const Icon(Icons.calendar_today, color: Colors.white54)
              : IconButton(
                  icon: const Icon(Icons.clear, color: Colors.white54),
                  tooltip: 'Zuruecksetzen',
                  onPressed: () => onChanged(null),
                ),
        ),
        child: Text(
          value == null ? 'Datum waehlen' : cmsFormatDate(value!),
          style: TextStyle(
            color: value == null ? Colors.white54 : Colors.white,
          ),
        ),
      ),
    );
  }
}

class CmsDateTimePickerField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;

  const CmsDateTimePickerField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final now = DateTime.now();
        final date = await showDatePicker(
          context: context,
          initialDate: value ?? now,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (date == null || !context.mounted) return;

        final time = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(value ?? now),
        );
        if (time == null) return;

        onChanged(DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        ));
      },
      child: InputDecorator(
        decoration: cmsInputDecoration(label).copyWith(
          suffixIcon: value == null
              ? const Icon(Icons.schedule, color: Colors.white54)
              : IconButton(
                  icon: const Icon(Icons.clear, color: Colors.white54),
                  tooltip: 'Zuruecksetzen',
                  onPressed: () => onChanged(null),
                ),
        ),
        child: Text(
          value == null ? 'Datum und Zeit waehlen' : cmsFormatDateTime(value!),
          style: TextStyle(
            color: value == null ? Colors.white54 : Colors.white,
          ),
        ),
      ),
    );
  }
}

class CmsTimeTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;

  const CmsTimeTextField({
    super.key,
    required this.label,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      readOnly: true,
      style: const TextStyle(color: Colors.white),
      decoration: cmsInputDecoration(label).copyWith(
        hintText: 'HH:mm',
        suffixIcon: IconButton(
          icon: const Icon(Icons.access_time, color: Colors.white54),
          tooltip: 'Zeit waehlen',
          onPressed: () async {
            TimeOfDay initial = const TimeOfDay(hour: 20, minute: 15);
            final raw = controller.text.trim();
            final parts = raw.split(':');
            if (parts.length == 2) {
              final h = int.tryParse(parts[0]);
              final m = int.tryParse(parts[1]);
              if (h != null && m != null && h >= 0 && h < 24 && m >= 0 && m < 60) {
                initial = TimeOfDay(hour: h, minute: m);
              }
            }
            final picked = await showTimePicker(
              context: context,
              initialTime: initial,
            );
            if (picked != null) {
              controller.text = cmsFormatTimeOfDay(picked);
            }
          },
        ),
      ),
    );
  }
}

class CmsColorPickerField extends StatelessWidget {
  final String label;
  final TextEditingController controller;

  const CmsColorPickerField({
    super.key,
    required this.label,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    Color current = _parseHexColor(controller.text.trim()) ?? AppColors.pop;

    Future<void> openPicker() async {
      await showDialog<void>(
        context: context,
        builder: (context) {
          var draft = current;
          return StatefulBuilder(
            builder: (context, setStateDialog) {
              return AlertDialog(
                backgroundColor: const Color(0xFF171D28),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: Color(0x26FFFFFF)),
                ),
                title: const Text(
                  'Farbe waehlen',
                  style: TextStyle(color: Colors.white),
                ),
                content: SizedBox(
                  width: 420,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: double.infinity,
                        height: 54,
                        decoration: BoxDecoration(
                          color: draft,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0x40FFFFFF)),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _colorSlider(
                        label: 'R',
                        value: draft.red.toDouble(),
                        activeColor: Colors.red,
                        onChanged: (v) => setStateDialog(() {
                          draft = draft.withRed(v.toInt());
                        }),
                      ),
                      _colorSlider(
                        label: 'G',
                        value: draft.green.toDouble(),
                        activeColor: Colors.green,
                        onChanged: (v) => setStateDialog(() {
                          draft = draft.withGreen(v.toInt());
                        }),
                      ),
                      _colorSlider(
                        label: 'B',
                        value: draft.blue.toDouble(),
                        activeColor: Colors.blue,
                        onChanged: (v) => setStateDialog(() {
                          draft = draft.withBlue(v.toInt());
                        }),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _quickColor(const Color(0xFFE85D9E), setStateDialog, (c) => draft = c),
                          _quickColor(const Color(0xFF4DA3FF), setStateDialog, (c) => draft = c),
                          _quickColor(const Color(0xFF4DD4AC), setStateDialog, (c) => draft = c),
                          _quickColor(const Color(0xFFFFB347), setStateDialog, (c) => draft = c),
                          _quickColor(const Color(0xFFFF6B6B), setStateDialog, (c) => draft = c),
                          _quickColor(const Color(0xFF9C7CFF), setStateDialog, (c) => draft = c),
                        ],
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
                    onPressed: () {
                      controller.text = _toHex(draft);
                      Navigator.pop(context);
                    },
                    child: const Text('Uebernehmen'),
                  ),
                ],
              );
            },
          );
        },
      );
    }

    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: cmsInputDecoration(label).copyWith(
        hintText: '#RRGGBB',
        prefixIcon: Container(
          margin: const EdgeInsets.all(10),
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: current,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: const Color(0x50FFFFFF)),
          ),
        ),
        suffixIcon: IconButton(
          icon: const Icon(Icons.palette_outlined, color: Colors.white54),
          tooltip: 'Farbpicker',
          onPressed: openPicker,
        ),
      ),
      onTapOutside: (_) {},
    );
  }
}

Widget _colorSlider({
  required String label,
  required double value,
  required Color activeColor,
  required ValueChanged<double> onChanged,
}) {
  return Row(
    children: [
      SizedBox(
        width: 20,
        child: Text(
          label,
          style: const TextStyle(color: Colors.white70),
        ),
      ),
      Expanded(
        child: Slider(
          value: value,
          min: 0,
          max: 255,
          activeColor: activeColor,
          onChanged: onChanged,
        ),
      ),
      SizedBox(
        width: 34,
        child: Text(
          value.toInt().toString(),
          textAlign: TextAlign.right,
          style: const TextStyle(color: Colors.white60),
        ),
      ),
    ],
  );
}

Widget _quickColor(
  Color color,
  void Function(void Function()) setStateDialog,
  void Function(Color) apply,
) {
  return GestureDetector(
    onTap: () => setStateDialog(() => apply(color)),
    child: Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0x70FFFFFF)),
      ),
    ),
  );
}

Color? _parseHexColor(String input) {
  final normalized = input.trim().replaceAll('#', '');
  if (normalized.length != 6) return null;
  final value = int.tryParse(normalized, radix: 16);
  if (value == null) return null;
  return Color(0xFF000000 | value);
}

String _toHex(Color color) {
  final r = color.red.toRadixString(16).padLeft(2, '0');
  final g = color.green.toRadixString(16).padLeft(2, '0');
  final b = color.blue.toRadixString(16).padLeft(2, '0');
  return '#${(r + g + b).toUpperCase()}';
}

// ─────────────────────────────────────────────
// Show search dialog (shared across forms)
// ─────────────────────────────────────────────

Future<String?> showCmsShowSearchDialog(
  BuildContext context,
  List<Show> shows,
) async {
  var query = '';
  return showDialog<String>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setStateDialog) {
          final filtered = shows
              .where(
                (s) =>
                    s.displayTitle
                        .toLowerCase()
                        .contains(query.toLowerCase()) ||
                    s.title.toLowerCase().contains(query.toLowerCase()),
              )
              .toList();
          return AlertDialog(
            backgroundColor: const Color(0xFF171D28),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: Color(0x26FFFFFF)),
            ),
            title: Text(
              'Show suchen',
              style: GoogleFonts.montserrat(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            content: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    style: const TextStyle(color: Colors.white),
                    decoration: cmsInputDecoration('Suche'),
                    onChanged: (value) =>
                        setStateDialog(() => query = value),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 300,
                    child: ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final show = filtered[index];
                        return ListTile(
                          title: Text(
                            show.displayTitle,
                            style: const TextStyle(color: Colors.white),
                          ),
                          subtitle: show.shortTitle != null &&
                                  show.shortTitle!.trim().isNotEmpty &&
                                  show.shortTitle != show.title
                              ? Text(
                                  show.title,
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 11,
                                  ),
                                )
                              : null,
                          tileColor: const Color(0x14000000),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          onTap: () =>
                              Navigator.of(context).pop(show.showId),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

// ─────────────────────────────────────────────
// CmsSearchableShowField
// ─────────────────────────────────────────────

class CmsSearchableShowField extends StatelessWidget {
  final List<Show> shows;
  final String? selectedShowId;
  final String label;
  final ValueChanged<String?> onChanged;

  const CmsSearchableShowField({
    super.key,
    required this.shows,
    required this.selectedShowId,
    required this.label,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selectedTitle = shows
        .where((s) => s.showId == selectedShowId)
        .map((s) => s.displayTitle)
        .cast<String?>()
        .firstWhere((_) => true, orElse: () => null);

    return InkWell(
      onTap: () async {
        final picked = await showCmsShowSearchDialog(context, shows);
        if (picked != null) onChanged(picked);
      },
      child: InputDecorator(
        decoration: cmsInputDecoration(label),
        child: Row(
          children: [
            Expanded(
              child: Text(
                selectedTitle ?? 'Show wählen und suchen',
                style: TextStyle(
                  color: selectedTitle == null ? Colors.white54 : Colors.white,
                ),
              ),
            ),
            if (selectedTitle != null)
              IconButton(
                visualDensity: VisualDensity.compact,
                splashRadius: 18,
                tooltip: 'Auswahl löschen',
                onPressed: () => onChanged(null),
                icon: const Icon(Icons.clear, color: Colors.white54, size: 18),
              ),
            const Icon(Icons.search, color: Colors.white54),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// CmsSeasonDropdown
// ─────────────────────────────────────────────

class CmsSeasonDropdown extends StatelessWidget {
  final List<Season> seasons;
  final String? value;
  final ValueChanged<String?> onChanged;
  final String label;

  const CmsSeasonDropdown({
    super.key,
    required this.seasons,
    required this.value,
    required this.onChanged,
    this.label = 'Staffel',
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: cmsInputDecoration(label),
      dropdownColor: const Color(0xFF1F1F1F),
      style: const TextStyle(color: Colors.white),
      items: seasons
          .map(
            (s) => DropdownMenuItem(
              value: s.seasonId,
              child: Text('Staffel ${s.seasonNumber ?? '-'}'),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}

// ─────────────────────────────────────────────
// CmsCreatorDropdown
// ─────────────────────────────────────────────

class CmsCreatorDropdown extends StatelessWidget {
  final List<Map<String, dynamic>> creators;
  final String? value;
  final ValueChanged<String?> onChanged;

  const CmsCreatorDropdown({
    super.key,
    required this.creators,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: cmsInputDecoration('Creator'),
      dropdownColor: const Color(0xFF1F1F1F),
      style: const TextStyle(color: Colors.white),
      items: creators
          .map(
            (c) => DropdownMenuItem(
              value: c['id'] as String,
              child: Text((c['name'] as String?) ?? ''),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}

// ─────────────────────────────────────────────
// CmsEventKindDropdown
// ─────────────────────────────────────────────

class CmsEventKindDropdown extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const CmsEventKindDropdown({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: cmsInputDecoration('Event Typ'),
      dropdownColor: const Color(0xFF1F1F1F),
      style: const TextStyle(color: Colors.white),
      items: const [
        DropdownMenuItem(
          value: 'reaction_video',
          child: Text('Reaction Video'),
        ),
        DropdownMenuItem(
          value: 'reaction_premiere',
          child: Text('Reaction Premiere'),
        ),
        DropdownMenuItem(value: 'livestream', child: Text('Livestream')),
        DropdownMenuItem(value: 'recap', child: Text('Recap')),
      ],
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}
