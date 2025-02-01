import '../entities/season.dart';

abstract class SeasonRepository {
  Future<List<Season>> getSeasonsForShow(String showId);
}