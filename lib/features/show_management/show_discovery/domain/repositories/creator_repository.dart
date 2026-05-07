import '../entities/creator.dart';

abstract class CreatorRepository {
  Future<List<Creator>> search(String query);
}