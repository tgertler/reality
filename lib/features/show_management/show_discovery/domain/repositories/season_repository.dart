import 'package:frontend/features/show_management/show_discovery/domain/entities/season.dart';

abstract class SeasonRepository {

  Future<List<Season>> getSeasonsByShow(String showId);
    Future<Season> getSeasonById(String id);


}