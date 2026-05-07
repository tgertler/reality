import 'package:flutter/material.dart';
import 'package:frontend/core/config/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

/// Compact one-row search + sort control used in every CMS table section.
///
/// Combines a search [TextField], a fixed-width sort [DropdownButtonFormField],
/// and an asc/desc toggle [IconButton] side by side.
class CmsSearchSortBar extends StatelessWidget {
  final String searchHint;
  final ValueChanged<String> onSearchChanged;
  final String sortKey;
  final bool ascending;
  final Map<String, String> sortOptions;
  final ValueChanged<String?> onSortChanged;
  final VoidCallback onToggleDirection;

  const CmsSearchSortBar({
    super.key,
    required this.searchHint,
    required this.onSearchChanged,
    required this.sortKey,
    required this.ascending,
    required this.sortOptions,
    required this.onSortChanged,
    required this.onToggleDirection,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 700;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: compact ? constraints.maxWidth : constraints.maxWidth - 220,
              child: TextField(
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: searchHint,
                  hintStyle:
                      GoogleFonts.dmSans(color: Colors.white38, fontSize: 13),
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
                  prefixIcon:
                      const Icon(Icons.search, color: Colors.white38, size: 18),
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
                ),
                onChanged: onSearchChanged,
              ),
            ),
            SizedBox(
              width: compact ? constraints.maxWidth - 48 : 164,
              child: DropdownButtonFormField<String>(
                initialValue: sortKey,
                isExpanded: true,
                decoration: InputDecoration(
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
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
                ),
                dropdownColor: const Color(0xFF1F1F1F),
                style: const TextStyle(color: Colors.white, fontSize: 12),
                items: sortOptions.entries
                    .map(
                      (entry) => DropdownMenuItem<String>(
                        value: entry.key,
                        child: Text(entry.value, overflow: TextOverflow.ellipsis),
                      ),
                    )
                    .toList(),
                onChanged: onSortChanged,
              ),
            ),
            SizedBox(
              width: 40,
              height: 46,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFF222834),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0x26FFFFFF)),
                ),
                child: IconButton(
                  onPressed: onToggleDirection,
                  icon: Icon(
                    ascending ? Icons.arrow_upward : Icons.arrow_downward,
                    color: AppColors.pop,
                    size: 18,
                  ),
                  tooltip: ascending ? 'Aufsteigend' : 'Absteigend',
                  padding: EdgeInsets.zero,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
