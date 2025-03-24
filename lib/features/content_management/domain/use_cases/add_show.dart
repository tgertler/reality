import '../repositories/content_repository.dart';
import '../entities/show.dart';

class AddShow {
  final ContentRepository repository;

  AddShow(this.repository);

  Future<void> call(Show show) async {
    await repository.addShow(show);
  }
}