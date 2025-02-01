import '../entities/show.dart';

abstract class ShowRepository {
  Future<List<Show>> getShows();

}