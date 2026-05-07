import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/utils/supabase_provider.dart';

final newsTickerHeadlinesProvider = FutureProvider<List<String>>((ref) async {
  final supabase = ref.read(supabaseClientProvider);

  try {
    final response = await supabase
        .from('news_ticker_items')
        .select('headline, is_active, priority, updated_at')
        .eq('is_active', true)
        .order('priority', ascending: true)
        .order('updated_at', ascending: false)
        .limit(100);

    final rows = (response as List<dynamic>).cast<Map<String, dynamic>>();
    final headlines = rows
        .map((row) => (row['headline'] as String? ?? '').trim())
        .where((headline) => headline.isNotEmpty)
        .toList();

    if (headlines.isNotEmpty) {
      return headlines;
    }
  } catch (_) {
    // Fall back to a neutral placeholder headline when table/permissions are
    // not available yet.
  }

  return const ['Willkommen bei Reality'];
});