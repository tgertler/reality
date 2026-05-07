import '../entities/show_social_tag.dart';
import '../repositories/show_social_repository.dart';

class GetShowSocialTagsUseCase {
  final ShowSocialRepository repository;

  GetShowSocialTagsUseCase(this.repository);

  Future<List<ShowSocialTag>> execute(String showId) =>
      repository.getTagsForShow(showId);
}
