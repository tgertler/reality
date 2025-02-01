import '../../domain/entities/show.dart';

abstract class ShowRepository {

  Future<List<Show>> search(String query);

  Future<Show> getShowById(String id);

}