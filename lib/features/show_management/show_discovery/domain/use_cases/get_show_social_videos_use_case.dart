import '../entities/show_social_video.dart';
import '../repositories/show_social_repository.dart';

class GetShowSocialVideosUseCase {
  final ShowSocialRepository repository;

  GetShowSocialVideosUseCase(this.repository);

  Future<List<ShowSocialVideo>> execute(String showId) =>
      repository.getVideosForShow(showId);
}
