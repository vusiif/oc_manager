import 'package:drift/drift.dart';

import '../../data/database/app_database.dart';
import 'models/export_bundle.dart';
import 'booklet/booklet_html_builder.dart';
import 'booklet/booklet_markdown_builder.dart';

class BookletExportOptions {
  final bool includeWorldOverview;
  final bool includeGroups;
  final bool includeTimeline;
  final bool includeCharacters;
  final bool includeRelations;
  final bool includeGalleries;
  final bool includeRadarStats;
  final Set<int>? selectedCharacterIds;
  final BookletFormat format;

  const BookletExportOptions({
    this.includeWorldOverview = true,
    this.includeGroups = true,
    this.includeTimeline = true,
    this.includeCharacters = true,
    this.includeRelations = true,
    this.includeGalleries = true,
    this.includeRadarStats = true,
    this.selectedCharacterIds,
    this.format = BookletFormat.html,
  });
}

/// Service that compiles world data into standalone publications (HTML / Markdown ZIP)
class BookletExportService {
  final AppDatabase db;

  BookletExportService(this.db);

  /// Compiles and exports the world booklet to [outputPath]
  Future<void> exportBooklet({
    required int worldId,
    required String outputPath,
    required BookletExportOptions options,
  }) async {
    // 1. Load world entity
    final world = await (db.select(
      db.worlds,
    )..where((t) => t.id.equals(worldId))).getSingleOrNull();
    if (world == null) {
      throw Exception('World not found with ID: $worldId');
    }

    // 2. Load characters
    var charQuery = db.select(db.characters)
      ..where((t) => t.worldId.equals(worldId));
    final allCharacters = await charQuery.get();
    final characters = options.selectedCharacterIds != null
        ? allCharacters
              .where((c) => options.selectedCharacterIds!.contains(c.id))
              .toList()
        : allCharacters;
    final characterIds = characters.map((c) => c.id).toSet();

    // 3. Load groups and memberships
    final groups =
        await (db.select(db.groups)
              ..where((t) => t.worldId.equals(worldId))
              ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
            .get();
    final characterGroups = await db.select(db.characterGroups).get();
    final charGroupMap = <int, List<int>>{};
    for (final cg in characterGroups) {
      if (characterIds.contains(cg.characterId)) {
        charGroupMap.putIfAbsent(cg.characterId, () => []).add(cg.groupId);
      }
    }

    // 4. Load stats
    final allStats = await (db.select(
      db.characterStats,
    )..orderBy([(t) => OrderingTerm.asc(t.sortOrder)])).get();
    final statsMap = <int, List<CharacterStat>>{};
    for (final s in allStats) {
      if (characterIds.contains(s.characterId)) {
        statsMap.putIfAbsent(s.characterId, () => []).add(s);
      }
    }

    // 5. Load galleries
    final allGalleries = await (db.select(
      db.characterGalleries,
    )..orderBy([(t) => OrderingTerm.asc(t.sortOrder)])).get();
    final galleriesMap = <int, List<CharacterGallery>>{};
    for (final g in allGalleries) {
      if (characterIds.contains(g.characterId)) {
        galleriesMap.putIfAbsent(g.characterId, () => []).add(g);
      }
    }

    // 6. Load timeline events
    final timelineEvents =
        await (db.select(db.timelineEvents)
              ..where((t) => t.worldId.equals(worldId))
              ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
            .get();

    // 7. Load relations
    final allRelations = await db.select(db.relations).get();
    final relations = allRelations
        .where(
          (r) =>
              characterIds.contains(r.fromCharacterId) &&
              characterIds.contains(r.toCharacterId),
        )
        .toList();

    // 8. Generate output according to chosen format
    if (options.format == BookletFormat.html) {
      await exportHtmlBooklet(
        world: world,
        characters: characters,
        groups: groups,
        charGroupMap: charGroupMap,
        statsMap: statsMap,
        galleriesMap: galleriesMap,
        timelineEvents: timelineEvents,
        relations: relations,
        options: options,
        outputPath: outputPath,
      );
    } else {
      await exportMarkdownZipBooklet(
        world: world,
        characters: characters,
        groups: groups,
        charGroupMap: charGroupMap,
        statsMap: statsMap,
        galleriesMap: galleriesMap,
        timelineEvents: timelineEvents,
        relations: relations,
        options: options,
        outputPath: outputPath,
      );
    }
  }
}
