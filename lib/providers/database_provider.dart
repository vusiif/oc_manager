import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database/app_database.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

final worldDaoProvider = Provider((ref) => ref.watch(databaseProvider).worldDao);
final characterDaoProvider =
    Provider((ref) => ref.watch(databaseProvider).characterDao);
final relationDaoProvider =
    Provider((ref) => ref.watch(databaseProvider).relationDao);
final templateDaoProvider =
    Provider((ref) => ref.watch(databaseProvider).templateDao);
final tagDaoProvider = Provider((ref) => ref.watch(databaseProvider).tagDao);
final trashDaoProvider =
    Provider((ref) => ref.watch(databaseProvider).trashDao);
