import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/utils/supabase_provider.dart';

import '../../data/repositories/show_social_repository_impl.dart';
import '../../data/sources/show_social_datasource.dart';
import '../../domain/entities/show_social_tag.dart';
import '../../domain/entities/show_social_video.dart';
import '../../domain/use_cases/get_show_social_tags_use_case.dart';
import '../../domain/use_cases/get_show_social_videos_use_case.dart';

final _showSocialDataSourceProvider = Provider<ShowSocialDataSource>((ref) {
  return ShowSocialDataSource(ref.read(supabaseClientProvider));
});

final _showSocialRepositoryProvider =
    Provider<ShowSocialRepositoryImpl>((ref) {
  return ShowSocialRepositoryImpl(ref.read(_showSocialDataSourceProvider));
});

/// TikTok tags for a specific show (keyed by showId)
final showSocialTagsProvider =
    FutureProvider.family<List<ShowSocialTag>, String>((ref, showId) async {
  final useCase =
      GetShowSocialTagsUseCase(ref.read(_showSocialRepositoryProvider));
  return useCase.execute(showId);
});

/// TikTok videos for a specific show (keyed by showId)
final showSocialVideosProvider =
    FutureProvider.family<List<ShowSocialVideo>, String>((ref, showId) async {
  final useCase =
      GetShowSocialVideosUseCase(ref.read(_showSocialRepositoryProvider));
  return useCase.execute(showId);
});
