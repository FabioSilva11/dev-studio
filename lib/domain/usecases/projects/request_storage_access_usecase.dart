import 'package:dev_studio/core/result/result.dart';
import 'package:dev_studio/data/repositories/project/project_repository.dart';

class RequestStorageAccessUseCase {
  final ProjectRepository repository;

  RequestStorageAccessUseCase(this.repository);

  Future<Result<bool>> call() async {
    return await repository.requestStorageAccess();
  }
}
