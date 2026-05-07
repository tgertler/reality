import 'package:supabase_flutter/supabase_flutter.dart';

class ShowDataSource {
  final supabaseClient = Supabase.instance.client;
  String? _categoryColumn;
  String? _headerImageColumn;
  String? _mainColorColumn;

  Future<String?> _resolveCategoryColumn() async {
    if (_categoryColumn != null) {
      return _categoryColumn;
    }

    try {
      await supabaseClient.from('shows').select('genre').limit(1);
      _categoryColumn = 'genre';
      return _categoryColumn;
    } catch (_) {
      // Continue with fallback.
    }

    try {
      await supabaseClient.from('shows').select('kategorie').limit(1);
      _categoryColumn = 'kategorie';
      return _categoryColumn;
    } catch (_) {
      _categoryColumn = null;
      return null;
    }
  }

  Future<String?> _resolveColumn(List<String> candidates) async {
    for (final column in candidates) {
      try {
        await supabaseClient.from('shows').select(column).limit(1);
        return column;
      } catch (_) {
        // Try next candidate.
      }
    }
    return null;
  }

  Future<String?> _resolveHeaderImageColumn() async {
    if (_headerImageColumn != null) {
      return _headerImageColumn;
    }

    _headerImageColumn = await _resolveColumn([
      'header_image_url',
      'header_image',
      'image_url',
      'image',
      'banner_url',
    ]);
    return _headerImageColumn;
  }

  Future<String?> _resolveMainColorColumn() async {
    if (_mainColorColumn != null) {
      return _mainColorColumn;
    }

    _mainColorColumn = await _resolveColumn([
      'main_color',
      'primary_color',
      'brand_color',
    ]);
    return _mainColorColumn;
  }

  Future<List<Map<String, dynamic>>> search(String query) async {
    final escaped = query.replaceAll(',', r'\,');
    final categoryColumn = await _resolveCategoryColumn();
    final headerImageColumn = await _resolveHeaderImageColumn();
    final mainColorColumn = await _resolveMainColorColumn();

    final selectParts = <String>[
      'id',
      'title',
      'short_title',
      'description',
      'release_window',
      if (categoryColumn != null) categoryColumn,
      if (headerImageColumn != null) headerImageColumn,
      if (mainColorColumn != null) mainColorColumn,
    ];
    final selectColumns = selectParts.join(', ');

    final response = await supabaseClient
      .from('shows')
      .select(selectColumns)
      .or('title.ilike.%$escaped%,short_title.ilike.%$escaped%');

    final results = response as List<dynamic>;

    return results
        .map((show) => {
              'id': show['id'],
              'title': show['title'],
              'short_title': show['short_title'],
              'description': show['description'],
              'release_window': show['release_window'],
              'genre': categoryColumn == null ? null : show[categoryColumn],
              'header_image_url':
                  headerImageColumn == null ? null : show[headerImageColumn],
              'main_color':
                  mainColorColumn == null ? null : show[mainColorColumn],
              'type': 'show',
            })
        .toList();
  }

  Future<Map<String, dynamic>?> getShowById(String id) async {
    final categoryColumn = await _resolveCategoryColumn();
    final headerImageColumn = await _resolveHeaderImageColumn();
    final mainColorColumn = await _resolveMainColorColumn();

    final selectParts = <String>[
      'id',
      'title',
      'short_title',
      'description',
      'release_window',
      if (categoryColumn != null) categoryColumn,
      if (headerImageColumn != null) headerImageColumn,
      if (mainColorColumn != null) mainColorColumn,
    ];
    final selectColumns = selectParts.join(', ');

    final response = await supabaseClient
      .from('shows')
      .select(selectColumns)
      .eq('id', id)
      .single();

    final show = response;

    return {
      'id': show['id'],
      'title': show['title'],
      'short_title': show['short_title'],
      'description': show['description'],
      'release_window': show['release_window'],
      'genre': categoryColumn == null ? null : show[categoryColumn],
      'header_image_url':
          headerImageColumn == null ? null : show[headerImageColumn],
      'main_color': mainColorColumn == null ? null : show[mainColorColumn],
    };
  }
}
