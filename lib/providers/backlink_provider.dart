import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database/app_database.dart';
import '../core/util/wiki_link_parser.dart';
import 'character_provider.dart';

/// 反向引用查询参数
class BacklinkQuery {
  final int worldId;
  final int characterId;
  final String characterName;

  const BacklinkQuery({
    required this.worldId,
    required this.characterId,
    required this.characterName,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BacklinkQuery &&
          runtimeType == other.runtimeType &&
          worldId == other.worldId &&
          characterId == other.characterId &&
          characterName == other.characterName;

  @override
  int get hashCode => Object.hash(worldId, characterId, characterName);
}

/// 反向引用结果条目
class BacklinkItem {
  final Character sourceCharacter;
  final List<String> snippets;

  const BacklinkItem({
    required this.sourceCharacter,
    required this.snippets,
  });
}

/// 衍生 Provider：根据当前世界观与角色信息，自动聚合出所有提及了当前角色的其他 OC 及上下文
final characterBacklinksProvider =
    Provider.family<List<BacklinkItem>, BacklinkQuery>((ref, query) {
  final charactersAsync = ref.watch(charactersByWorldProvider(query.worldId));
  final allChars = charactersAsync.valueOrNull ?? [];
  final targetName = query.characterName.trim();
  if (targetName.isEmpty || allChars.isEmpty) return const [];

  final results = <BacklinkItem>[];
  for (final other in allChars) {
    if (other.id == query.characterId) continue;
    final desc = other.description;
    if (WikiLinkParser.hasReferenceTo(desc, targetName)) {
      final snippets = WikiLinkParser.extractContextSnippets(desc, targetName);
      results.add(BacklinkItem(
        sourceCharacter: other,
        snippets: snippets,
      ));
    }
  }
  return results;
});
