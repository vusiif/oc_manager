import 'package:oc_manager/core/storage/image_storage_service.dart';
import '../consistency_models.dart';
import '../consistency_rule.dart';

/// 4. 多媒体沙盒本地文件有效性规则 (RULE_MEDIA_FILE_INTEGRITY)
class MediaFileIntegrityRule extends ConsistencyRule {
  @override
  String get ruleId => 'RULE_MEDIA_FILE_INTEGRITY';

  @override
  String get name => '多媒体本地资源存活检查';

  @override
  String get description => '诊断角色头像、画廊立绘切片及百科封面的沙盒本地文件是否缺失或损坏。';

  @override
  IssueCategory get category => IssueCategory.media;

  @override
  IssueSeverity get defaultSeverity => IssueSeverity.error;

  @override
  Future<List<ConsistencyIssue>> evaluate(ConsistencyContext context) async {
    final issues = <ConsistencyIssue>[];
    final storage = ImageStorageService.instance;
    final targetCharId = context.targetCharacterId;

    final targetCharacters = targetCharId != null
        ? context.characters.where((c) => c.id == targetCharId).toList()
        : context.characters;

    // 1. 检查角色头像
    for (final char in targetCharacters) {
      if (char.avatarPath != null && char.avatarPath!.isNotEmpty) {
        final file = await storage.resolveImageFile(char.avatarPath);
        if (file == null || !file.existsSync()) {
          issues.add(
            ConsistencyIssue(
              id: 'media_avatar_missing_${char.id}',
              ruleId: ruleId,
              category: category,
              severity: IssueSeverity.error,
              title: '角色主头像文件丢失',
              description: '角色 “${char.name}” 绑定的本地立绘头像在沙盒磁盘上已不存在。',
              suggestion: '请重新为该角色选择并上传头像，或清除已失效的头像引用。',
              evidence: '缺失文件相对路径: ${char.avatarPath}',
              targetType: 'character',
              targetId: char.id,
              targetName: char.name,
            ),
          );
        }
      }
    }

    // 2. 检查画廊立绘
    final targetCharIds = {for (final c in targetCharacters) c.id};
    final relevantGalleries = context.galleries
        .where((g) => targetCharIds.contains(g.characterId))
        .toList();

    for (final g in relevantGalleries) {
      final file = await storage.resolveImageFile(g.imagePath);
      if (file == null || !file.existsSync()) {
        issues.add(
          ConsistencyIssue(
            id: 'media_gallery_missing_${g.id}',
            ruleId: ruleId,
            category: category,
            severity: IssueSeverity.error,
            title: '角色画廊立绘丢失',
            description: '画廊 ID #${g.id} 对应的本地差分切片文件在沙盒磁盘上已不存在。',
            suggestion: '重新导入对应的立绘切片图片，或在画廊中删除无效切片。',
            evidence: '缺失画廊切片路径: ${g.imagePath}',
            targetType: 'character',
            targetId: g.characterId,
            targetName: '画廊立绘 #${g.id}',
          ),
        );
      }
    }

    // 3. 检查百科封面（仅在全量模式）
    if (!context.isSingleCharacterMode) {
      for (final lore in context.lores) {
        if (lore.coverImagePath != null && lore.coverImagePath!.isNotEmpty) {
          final file = await storage.resolveImageFile(lore.coverImagePath);
          if (file == null || !file.existsSync()) {
            issues.add(
              ConsistencyIssue(
                id: 'media_lore_cover_missing_${lore.id}',
                ruleId: ruleId,
                category: category,
                severity: IssueSeverity.error,
                title: '百科图鉴封面丢失',
                description: '百科实体 “${lore.name}” 关联的封面图片在沙盒磁盘上已不存在。',
                suggestion: '重新上传该词条的封面图，或在词条详情中移除封面。',
                evidence: '缺失封面路径: ${lore.coverImagePath}',
                targetType: 'lore',
                targetId: lore.id,
                targetName: lore.name,
              ),
            );
          }
        }
      }
    }

    return issues;
  }
}
