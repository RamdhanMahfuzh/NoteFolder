import 'package:notefolder/data/datasource/folder_local_data_source.dart';
import 'package:notefolder/data/models/folder_model.dart';
import 'package:notefolder/domain/entities/folder_entity.dart';
import 'package:notefolder/domain/repositories/folder_repository.dart';

class FolderRepositoryImpl implements FolderRepository {
  FolderRepositoryImpl({required this.localDataSource});

  final FolderLocalDataSource localDataSource;

  @override
  Future<List<FolderEntity>> getFolders() => localDataSource.getFolders();

  @override
  Future<void> addFolder(FolderEntity folder) =>
      localDataSource.addFolder(_model(folder));

  @override
  Future<void> updateFolder(FolderEntity folder) =>
      localDataSource.updateFolder(_model(folder));

  @override
  Future<void> deleteFolder(String id) => localDataSource.deleteFolder(id);

  FolderModel _model(FolderEntity folder) => FolderModel(
    id: folder.id,
    name: folder.name,
    createdAt: folder.createdAt,
  );
}
