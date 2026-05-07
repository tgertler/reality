import '../entities/show_social_tag.dart';
import '../entities/show_social_video.dart';

abstract class ShowSocialRepository {
  Future<List<ShowSocialTag>> getTagsForShow(String showId);
  Future<List<ShowSocialVideo>> getVideosForShow(String showId);
}
