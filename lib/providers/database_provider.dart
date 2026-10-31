import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database/app_database.dart';
import '../core/export/booklet_export_service.dart';
import '../core/export/oc_package_service.dart';

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
final settingsDaoProvider =
    Provider((ref) => ref.watch(databaseProvider).settingsDao);
final groupDaoProvider =
    Provider((ref) => ref.watch(databaseProvider).groupDao);
final timelineDaoProvider =
    Provider((ref) => ref.watch(databaseProvider).timelineDao);

final bookletExportServiceProvider = Provider<BookletExportService>((ref) {
  final db = ref.watch(databaseProvider);
  return BookletExportService(db);
});

final ocPackageServiceProvider = Provider<OcPackageService>((ref) {
  final db = ref.watch(databaseProvider);
  return OcPackageService(db);
});

