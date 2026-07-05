import 'package:dev_studio/core/result/result.dart';
import 'package:dev_studio/data/repositories/project/project_repository.dart';

class HasStorageAccessUseCase {
  final ProjectRepository repository;

  HasStorageAccessUseCase(this.repository);

  Future<Result<bool>> call() async {
    return await repository.hasStorageAccess();
  }
}
