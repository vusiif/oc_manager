import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' show Value;

import '../../data/database/app_database.dart';
import '../../providers/character_provider.dart';
import '../../providers/relation_provider.dart';
import '../../core/design/design_tokens.dart';
import '../../core/theme/app_theme.dart';
import '../../core/design/components/confirmation_dialog.dart';
import '../character/character_dialog.dart';
import 'graph_geometry.dart';

class RelationGraphPage extends ConsumerStatefulWidget {
  final int worldId;

  const RelationGraphPage({super.key, required this.worldId});

  @override
  ConsumerState<RelationGraphPage> createState() => _RelationGraphPageState();
}

class _RelationGraphPageState extends ConsumerState<RelationGraphPage> {
  final Map<int, Offset> _positions = {};
  final TransformationController _transformController =
      TransformationController();
  final Set<int> _loadedFromDbCharacters = {};
  int _graphRevision = 0;
  bool _showSidebar = true;
  int? _selectedRelationId;

  // 节点手柄连线交互状态
  int? _connectingFromId;
  Offset? _connectingCurrentPos;

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  void _syncPositions(List<Character> characters, List<GraphLayout> layouts) {
    if (layouts.isEmpty) return;
    final saved = {for (var l in layouts) l.characterId: Offset(l.x, l.y)};
    bool changed = false;
    for (final c in characters) {
      if (!_loadedFromDbCharacters.contains(c.id) && saved.containsKey(c.id)) {
        _positions[c.id] = saved[c.id]!;
        _loadedFromDbCharacters.add(c.id);
        changed = true;
      }
    }
    if (changed) {
      _graphRevision++;
    }
  }

  void _savePosition(int characterId, Offset pos) {
    ref.read(graphLayoutActionsProvider).savePosition(
          widget.worldId,
          characterId,
          pos.dx,
          pos.dy,
        );
  }

  void _dropCharacter(int characterId, Offset screenDropPos) {
    final inverse = Matrix4.inverted(_transformController.value);
    final canvasPos = MatrixUtils.transformPoint(inverse, screenDropPos);
    setState(() {
      _positions[characterId] = canvasPos;
      _loadedFromDbCharacters.add(characterId);
      _graphRevision++;
    });
    _savePosition(characterId, canvasPos);
  }

  void _removeFromCanvas(int characterId) {
    setState(() {
      _positions.remove(characterId);
      _loadedFromDbCharacters.remove(characterId);
      _graphRevision++;
    });
    ref.read(graphLayoutActionsProvider).removePosition(
          widget.worldId,
          characterId,
        );
  }

  /// 适应画布：将所有节点自动居中并自适应缩放到视野中
  void _fitCanvasToNodes(Size viewportSize) {
    if (_positions.isEmpty) {
      _transformController.value = Matrix4.identity();
      return;
    }

    double minX = double.infinity;
    double maxX = -double.infinity;
    double minY = double.infinity;
    double maxY = -double.infinity;

    for (final pos in _positions.values) {
      minX = min(minX, pos.dx);
      maxX = max(maxX, pos.dx);
      minY = min(minY, pos.dy);
      maxY = max(maxY, pos.dy);
    }

    const padding = 140.0;
    final contentWidth = (maxX - minX) + padding * 2;
    final contentHeight = (maxY - minY) + padding * 2;
    final contentCenterX = (minX + maxX) / 2;
    final contentCenterY = (minY + maxY) / 2;

    final scaleX = viewportSize.width / max(contentWidth, 1.0);
    final scaleY = viewportSize.height / max(contentHeight, 1.0);
    final scale = min(scaleX, scaleY).clamp(0.2, 1.5);

    final tx = viewportSize.width / 2 - contentCenterX * scale;
    final ty = viewportSize.height / 2 - contentCenterY * scale;

    // ignore: deprecated_member_use
    final matrix = Matrix4.identity()
      // ignore: deprecated_member_use
      ..translate(tx, ty)
      // ignore: deprecated_member_use
      ..scale(scale);

    setState(() {
      _transformController.value = matrix;
    });
  }

  void _onStartConnecting(int characterId, Offset startPos) {
    setState(() {
      _connectingFromId = characterId;
      _connectingCurrentPos = startPos;
    });
  }

  void _onUpdateConnecting(Offset delta) {
    if (_connectingCurrentPos == null) return;
    final scale = _transformController.value.getMaxScaleOnAxis();
    final sceneDelta = delta / (scale > 0 ? scale : 1.0);
    setState(() {
      _connectingCurrentPos = _connectingCurrentPos! + sceneDelta;
    });
  }

  void _onEndConnecting(List<Character> characters) {
    if (_connectingFromId == null || _connectingCurrentPos == null) {
      setState(() {
        _connectingFromId = null;
        _connectingCurrentPos = null;
      });
      return;
    }

    int? targetId;
    for (final entry in _positions.entries) {
      if (entry.key != _connectingFromId) {
        if ((entry.value - _connectingCurrentPos!).distance <= 45.0) {
          targetId = entry.key;
          break;
        }
      }
    }

    final sourceId = _connectingFromId;
    setState(() {
      _connectingFromId = null;
      _connectingCurrentPos = null;
    });

    if (targetId != null && sourceId != null) {
      _showAddRelationDialog(characters, fromId: sourceId, toId: targetId);
    }
  }

  // --- 添加关系对话框 ---

  void _showAddRelationDialog(List<Character> characters,
      {int? fromId, int? toId}) {
    if (characters.length < 2) return;

    int? selectedFrom = fromId ?? characters[0].id;
    int? selectedTo = toId ??
        characters.firstWhere(
          (c) => c.id != selectedFrom,
          orElse: () => characters[0],
        ).id;
    String selectedType = '朋友';
    bool isCustomType = false;
    bool isBidirectional = true;
    final customTypeController = TextEditingController();
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('添加关系'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  initialValue: selectedFrom,
                  decoration: const InputDecoration(labelText: '起始人物'),
                  items: characters
                      .map((c) =>
                          DropdownMenuItem(value: c.id, child: Text(c.name)))
                      .toList(),
                  onChanged: (v) => setState(() => selectedFrom = v),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: selectedTo,
                  decoration: const InputDecoration(labelText: '目标人物'),
                  items: characters
                      .map((c) =>
                          DropdownMenuItem(value: c.id, child: Text(c.name)))
                      .toList(),
                  onChanged: (v) => setState(() => selectedTo = v),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('关系类型',
                      style: Theme.of(context).textTheme.bodySmall),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    for (final t in _relationTypes)
                      ChoiceChip(
                        label: Text(t, style: const TextStyle(fontSize: 12)),
                        selected: !isCustomType && selectedType == t,
                        onSelected: (_) => setState(() {
                          selectedType = t;
                          isCustomType = false;
                        }),
                      ),
                    ChoiceChip(
                      label: const Text('自定义…',
                          style: TextStyle(fontSize: 12)),
                      selected: isCustomType,
                      onSelected: (_) =>
                          setState(() => isCustomType = true),
                    ),
                  ],
                ),
                if (isCustomType) ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: customTypeController,
                    decoration: const InputDecoration(
                      labelText: '自定义关系类型',
                      hintText: '例如：宿敌、同事、师徒…',
                    ),
                    onChanged: (v) => selectedType = v.trim(),
                  ),
                ],
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('双向关系'),
                  value: isBidirectional,
                  onChanged: (v) => setState(() => isBidirectional = v),
                ),
                TextField(
                  controller: noteController,
                  decoration: const InputDecoration(labelText: '备注（可选）'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () async {
                final type = isCustomType
                    ? customTypeController.text.trim()
                    : selectedType;
                if (selectedFrom != null &&
                    selectedTo != null &&
                    selectedFrom != selectedTo &&
                    type.isNotEmpty) {
                  await ref.read(relationActionsProvider).create(
                        fromCharacterId: selectedFrom!,
                        toCharacterId: selectedTo!,
                        relationType: type,
                        isBidirectional: isBidirectional,
                        note: noteController.text.trim().isEmpty
                            ? null
                            : noteController.text.trim(),
                      );
                  ref.invalidate(
                      relationsByWorldProvider(widget.worldId));
                  if (context.mounted) Navigator.pop(context);
                }
              },
              child: const Text('添加'),
            ),
          ],
        ),
      ),
    );
  }

  // --- 管理人物关系对话框 ---

  void _showRelationManager(
      Character character, List<Character> allCharacters, List<Relation> relations) {
    String nameOf(int id) =>
        allCharacters
            .where((c) => c.id == id)
            .map((c) => c.name)
            .firstOrNull ??
        '?';

    showDialog(
      context: context,
      builder: (context) {
        List<Relation> localRelations = List.of(relations);

        return StatefulBuilder(
          builder: (context, setDialogState) {
            final myRelations = localRelations
                .where((r) =>
                    r.fromCharacterId == character.id ||
                    r.toCharacterId == character.id)
                .toList();

            return AlertDialog(
              title: Text('${character.name} 的关系'),
              content: SizedBox(
                width: 360,
                child: myRelations.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text('暂无关系',
                              style: TextStyle(color: Colors.grey)),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: myRelations.length,
                        itemBuilder: (context, index) {
                          final rel = myRelations[index];
                          final otherName = rel.fromCharacterId == character.id
                              ? nameOf(rel.toCharacterId)
                              : nameOf(rel.fromCharacterId);
                          final arrow = rel.isBidirectional ? ' ↔ ' : ' → ';
                          final direction =
                              rel.fromCharacterId == character.id
                                  ? ''
                                  : '(反向)';
                          final groupTag = rel.relationGroupId != null
                              ? ' [组]'
                              : '';

                          return ListTile(
                            dense: true,
                            title: Text(
                              '$otherName$arrow${rel.relationType}$direction$groupTag',
                              style: const TextStyle(fontSize: 14),
                            ),
                            subtitle: rel.note != null && rel.note!.isNotEmpty
                                ? Text(rel.note!,
                                    style: const TextStyle(fontSize: 12))
                                : null,
                            trailing: IconButton(
                              icon: Icon(Icons.delete_outline,
                                  size: 20,
                                  color:
                                      Theme.of(context).colorScheme.error),
                              onPressed: () async {
                                await ref
                                    .read(relationActionsProvider)
                                    .delete(rel.id);
                                setDialogState(() {
                                  localRelations.removeWhere(
                                      (r) => r.id == rel.id);
                                });
                                ref.invalidate(
                                    relationsByWorldProvider(
                                        widget.worldId));
                              },
                            ),
                          );
                        },
                      ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('关闭'),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('添加关系'),
                  onPressed: () {
                    Navigator.pop(context);
                    _showAddRelationDialog(allCharacters,
                        fromId: character.id);
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --- 家谱关系对话框 ---

  void _showFamilyRelationDialog(List<Character> characters) {
    if (characters.length < 3) return;

    List<int> parentIds = [];
    List<int> childIds = [];
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('添加家谱关系'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('父母（可多选）',
                      style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      for (final c in characters)
                        FilterChip(
                          avatar: _genderIcon(c.gender),
                          label: Text(c.name,
                              style: const TextStyle(fontSize: 12)),
                          selected: parentIds.contains(c.id),
                          onSelected: (selected) => setState(() {
                            if (selected) {
                              parentIds.add(c.id);
                              childIds.remove(c.id);
                            } else {
                              parentIds.remove(c.id);
                            }
                          }),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('子女（可多选）',
                      style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      for (final c in characters)
                        FilterChip(
                          avatar: _genderIcon(c.gender),
                          label: Text(c.name,
                              style: const TextStyle(fontSize: 12)),
                          selected: childIds.contains(c.id),
                          onSelected: (selected) => setState(() {
                            if (selected) {
                              childIds.add(c.id);
                              parentIds.remove(c.id);
                            } else {
                              childIds.remove(c.id);
                            }
                          }),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: noteController,
                    decoration:
                        const InputDecoration(labelText: '备注（可选）'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (parentIds.length < 2 || childIds.isEmpty) return;
                  await ref
                      .read(relationActionsProvider)
                      .createFamilyRelation(
                        parentIds: parentIds,
                        childIds: childIds,
                        note: noteController.text.trim().isEmpty
                            ? null
                            : noteController.text.trim(),
                      );
                  ref.invalidate(
                      relationsByWorldProvider(widget.worldId));
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('添加'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _handleCanvasTap(
    Offset tapPos,
    List<Relation> relations,
    List<Character> characters,
  ) {
    final labelCenters = calculateRelationLabelCenters(
      relations: relations,
      positions: _positions,
    );

    int? hitRelId;
    double minDistance = 28.0;

    for (final entry in labelCenters.entries) {
      final dist = (entry.value - tapPos).distance;
      if (dist <= minDistance) {
        minDistance = dist;
        hitRelId = entry.key;
      }
    }

    if (hitRelId != null) {
      final hitRel = relations.firstWhere((r) => r.id == hitRelId);
      setState(() => _selectedRelationId = hitRelId);
      _showRelationActionDialog(hitRel, characters);
    } else {
      if (_selectedRelationId != null) {
        setState(() => _selectedRelationId = null);
      }
    }
  }

  void _showRelationActionDialog(Relation rel, List<Character> characters) {
    final charMap = {for (final c in characters) c.id: c};
    final fromChar = charMap[rel.fromCharacterId];
    final toChar = charMap[rel.toCharacterId];
    final fromName = fromChar?.name ?? '未知人物';
    final toName = toChar?.name ?? '未知人物';

    showDialog(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.hub_outlined, size: 20),
              SizedBox(width: 8),
              Text('人物关系', style: TextStyle(fontSize: 18)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(fromName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(width: 10),
                    Icon(
                      rel.isBidirectional ? Icons.compare_arrows : Icons.arrow_forward,
                      size: 20,
                      color: rel.isBidirectional ? Colors.blue : Colors.orange,
                    ),
                    const SizedBox(width: 10),
                    Text(toName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Text('类型: ', style: TextStyle(fontWeight: FontWeight.w500)),
                  Chip(
                    label: Text(rel.relationType, style: const TextStyle(fontSize: 12)),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                  const Spacer(),
                  Text(
                    rel.isBidirectional ? '双向互通' : '单向指向',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              if (rel.note != null && rel.note!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('备注: ${rel.note}', style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant)),
              ],
            ],
          ),
          actions: [
            // 切换双向/单向
            TextButton.icon(
              icon: Icon(rel.isBidirectional ? Icons.arrow_forward : Icons.sync_alt, size: 16),
              label: Text(rel.isBidirectional ? '设为单向' : '设为双向'),
              onPressed: () async {
                Navigator.pop(ctx);
                await ref.read(relationActionsProvider).update(
                      rel.copyWith(isBidirectional: !rel.isBidirectional),
                    );
                ref.invalidate(relationsByWorldProvider(widget.worldId));
              },
            ),
            // 反转方向 (仅单向有效)
            if (!rel.isBidirectional)
              TextButton.icon(
                icon: const Icon(Icons.swap_horiz, size: 16),
                label: const Text('反转'),
                onPressed: () async {
                  Navigator.pop(ctx);
                  await ref.read(relationActionsProvider).update(
                        rel.copyWith(
                          fromCharacterId: rel.toCharacterId,
                          toCharacterId: rel.fromCharacterId,
                        ),
                      );
                  ref.invalidate(relationsByWorldProvider(widget.worldId));
                },
              ),
            // 编辑类型与备注
            TextButton.icon(
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: const Text('编辑'),
              onPressed: () {
                Navigator.pop(ctx);
                _showEditRelationDialog(rel, fromName, toName);
              },
            ),
            // 删除关系
            TextButton.icon(
              icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
              label: const Text('删除', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                final confirmed = await showConfirmDialog(
                  context: context,
                  title: '删除关系',
                  content: '确定要删除【$fromName】与【$toName】之间的“${rel.relationType}”关系吗？',
                  confirmLabel: '删除',
                  isDestructive: true,
                );
                if (confirmed == true) {
                  if (ctx.mounted) Navigator.pop(ctx);
                  await ref.read(relationActionsProvider).delete(rel.id);
                  ref.invalidate(relationsByWorldProvider(widget.worldId));
                  setState(() => _selectedRelationId = null);
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showEditRelationDialog(Relation rel, String fromName, String toName) {
    String currentType = rel.relationType;
    final noteController = TextEditingController(text: rel.note ?? '');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('编辑关系: $fromName ⇄ $toName'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('关系类型', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  for (final t in _relationTypes)
                    ChoiceChip(
                      label: Text(t, style: const TextStyle(fontSize: 12)),
                      selected: currentType == t,
                      onSelected: (_) => setDialogState(() => currentType = t),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(labelText: '备注（可选）'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () async {
                final note = noteController.text.trim();
                await ref.read(relationActionsProvider).update(
                      rel.copyWith(
                        relationType: currentType,
                        note: Value(note.isEmpty ? null : note),
                      ),
                    );
                ref.invalidate(relationsByWorldProvider(widget.worldId));
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportToImage(List<Character> characters, List<Relation> relations) async {
    if (_positions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('画布上暂无人物，无法导出')),
      );
      return;
    }

    double minX = double.infinity, minY = double.infinity;
    double maxX = -double.infinity, maxY = -double.infinity;
    for (final pos in _positions.values) {
      minX = min(minX, pos.dx);
      minY = min(minY, pos.dy);
      maxX = max(maxX, pos.dx);
      maxY = max(maxY, pos.dy);
    }

    const margin = 120.0;
    final exportRect = Rect.fromLTRB(
      minX - margin,
      minY - margin,
      maxX + margin,
      maxY + margin,
    );

    final width = exportRect.width;
    final height = exportRect.height;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, width, height));

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgPaint = Paint()..color = isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF8F9FA);
    canvas.drawRect(Rect.fromLTWH(0, 0, width, height), bgPaint);

    canvas.translate(-exportRect.left, -exportRect.top);

    final relPainter = _RelationPainter(
      relations: relations,
      positions: _positions,
      characters: characters,
      revision: _graphRevision,
      isDark: isDark,
    );
    relPainter.paint(canvas, Size(maxX + margin, maxY + margin));

    for (final c in characters) {
      if (!_positions.containsKey(c.id)) continue;
      final pos = _positions[c.id]!;
      final color = c.status == 1 ? Colors.grey : AppColors.brand;
      _drawNodeOnCanvas(canvas, c, pos, color, isDark);
    }

    final picture = recorder.endRecording();
    final img = await picture.toImage(width.toInt(), height.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return;
    final pngBytes = byteData.buffer.asUint8List();

    final now = DateTime.now();
    final dateStr =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
    final defaultFileName = 'relation_graph_$dateStr.png';

    final result = await FilePicker.platform.saveFile(
      dialogTitle: '选择导出图片保存位置',
      fileName: defaultFileName,
      type: FileType.custom,
      allowedExtensions: ['png'],
    );

    if (result == null) return;

    var savePath = result;
    if (!savePath.toLowerCase().endsWith('.png')) {
      savePath += '.png';
    }

    await File(savePath).writeAsBytes(pngBytes);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('关系图已成功导出至: $savePath')),
      );
    }
  }

  void _drawNodeOnCanvas(
    Canvas canvas,
    Character c,
    Offset pos,
    Color color,
    bool isDark,
  ) {
    final shapePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    const half = 24.0;
    final initial = c.name.isNotEmpty ? c.name[0] : '?';

    if (c.gender == '男') {
      final rect = Rect.fromCenter(center: pos, width: half * 2, height: half * 2);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(4)), shapePaint);
    } else if (c.gender == '女') {
      canvas.drawCircle(pos, half, shapePaint);
    } else {
      final path = Path()
        ..moveTo(pos.dx, pos.dy - half * 1.13)
        ..lineTo(pos.dx + half * 1.13, pos.dy)
        ..lineTo(pos.dx, pos.dy + half * 1.13)
        ..lineTo(pos.dx - half * 1.13, pos.dy)
        ..close();
      canvas.drawPath(path, shapePaint);
    }

    final tp = TextPainter(
      text: TextSpan(
        text: initial,
        style: AppFonts.textStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout();
    tp.paint(canvas, Offset(pos.dx - tp.width / 2, pos.dy - tp.height / 2));

    final nameTp = TextPainter(
      text: TextSpan(
        text: c.name,
        style: AppFonts.textStyle(
          color: isDark ? Colors.white : Colors.black87,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout();
    nameTp.paint(canvas, Offset(pos.dx - nameTp.width / 2, pos.dy + half + 4));
  }

  static Widget? _genderIcon(String gender) {
    if (gender == '男') return const Text('♂', style: TextStyle(fontSize: 14));
    if (gender == '女') return const Text('♀', style: TextStyle(fontSize: 14));
    if (gender.isNotEmpty) {
      return const Text('⚥', style: TextStyle(fontSize: 14));
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final charactersAsync =
        ref.watch(charactersByWorldProvider(widget.worldId));
    final relationsAsync =
        ref.watch(relationsByWorldProvider(widget.worldId));
    final layoutsAsync =
        ref.watch(graphLayoutsProvider(widget.worldId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('关系图'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_link),
            tooltip: '添加人物关系',
            onPressed: () {
              final chars = charactersAsync.valueOrNull ?? [];
              _showAddRelationDialog(chars);
            },
          ),
          IconButton(
            icon: const Icon(Icons.family_restroom),
            tooltip: '添加家谱关系',
            onPressed: () {
              final chars = charactersAsync.valueOrNull ?? [];
              _showFamilyRelationDialog(chars);
            },
          ),
          IconButton(
            icon: const Icon(Icons.crop_free),
            tooltip: '适应画布 / 查看全部',
            onPressed: () {
              final size = MediaQuery.of(context).size;
              _fitCanvasToNodes(size);
            },
          ),
          IconButton(
            icon: const Icon(Icons.download_rounded),
            tooltip: '导出为图片 (PNG)',
            onPressed: () {
              final chars = charactersAsync.valueOrNull ?? [];
              final rels = relationsAsync.valueOrNull ?? [];
              _exportToImage(chars, rels);
            },
          ),
          IconButton(
            icon: const Icon(Icons.restore),
            tooltip: '重置视图',
            onPressed: () => _transformController.value = Matrix4.identity(),
          ),
          IconButton(
            icon: Icon(_showSidebar ? Icons.chevron_left : Icons.chevron_right),
            tooltip: _showSidebar ? '隐藏侧栏' : '显示侧栏',
            onPressed: () => setState(() => _showSidebar = !_showSidebar),
          ),
        ],
      ),
      body: charactersAsync.when(
        data: (characters) {
          if (characters.isEmpty) {
            return const Center(
              child: Text('暂无人物', style: TextStyle(color: Colors.grey)),
            );
          }

          if (layoutsAsync.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final relations = relationsAsync.valueOrNull ?? [];
          final layouts = layoutsAsync.valueOrNull ?? [];

          _syncPositions(characters, layouts);

          return Row(
            children: [
              ClipRect(
                child: AnimatedAlign(
                  alignment: Alignment.centerLeft,
                  heightFactor: 1.0,
                  widthFactor: _showSidebar ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOutCubic,
                  child: ExcludeFocus(
                    excluding: !_showSidebar,
                    child: IgnorePointer(
                      ignoring: !_showSidebar,
                      child: SizedBox(
                        width: 120,
                        child: Container(
                          width: 120,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHigh,
                            border: Border(
                              right: BorderSide(
                                color: theme.colorScheme.outlineVariant,
                              ),
                            ),
                          ),
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Text(
                                  '人物列表',
                                  style: theme.textTheme.labelLarge,
                                ),
                              ),
                              const Divider(height: 1),
                              Expanded(
                                child: ListView.builder(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  itemCount: characters.length,
                                  itemBuilder: (context, index) {
                                    final c = characters[index];
                                    final placed = _positions.containsKey(c.id);
                                    final color = c.status == 1
                                        ? Colors.grey
                                        : theme.colorScheme.primary;
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      child: Draggable<int>(
                                        data: c.id,
                                        feedback: Material(
                                          elevation: 6,
                                          child: _buildShape(
                                            c.gender, 28, color, c.name),
                                        ),
                                        childWhenDragging: Opacity(
                                          opacity: 0.3,
                                          child: _SidebarItem(
                                              character: c, placed: placed),
                                        ),
                                        child: _SidebarItem(
                                            character: c, placed: placed),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final viewport = Size(
                        constraints.maxWidth, constraints.maxHeight);
                    final canvasSize = Size(
                      max(viewport.width, 2000),
                      max(viewport.height, 2000),
                    );

                    return DragTarget<int>(
                      onAcceptWithDetails: (details) {
                        final renderBox = context.findRenderObject()
                            as RenderBox;
                        final localPos =
                            renderBox.globalToLocal(details.offset);
                        _dropCharacter(details.data, localPos);
                      },
                      builder: (context, candidateData, rejectedData) {
                        return InteractiveViewer(
                          transformationController: _transformController,
                          boundaryMargin: const EdgeInsets.all(500),
                          minScale: 0.1,
                          maxScale: 3.0,
                          child: GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onTapUp: (details) {
                              _handleCanvasTap(
                                details.localPosition,
                                relations,
                                characters,
                              );
                            },
                            child: Container(
                              width: canvasSize.width,
                              height: canvasSize.height,
                              color: theme
                                  .colorScheme.surfaceContainerLowest,
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: CustomPaint(
                                      painter: _GridPainter(
                                        color: theme
                                            .colorScheme.outlineVariant
                                            .withValues(alpha: 0.3),
                                      ),
                                    ),
                                  ),
                                  CustomPaint(
                                    size: canvasSize,
                                    painter: _RelationPainter(
                                      relations: relations,
                                      positions: _positions,
                                      characters: characters,
                                      revision: _graphRevision,
                                      selectedRelationId: _selectedRelationId,
                                      isDark:
                                          theme.brightness == Brightness.dark,
                                    ),
                                  ),
                                // 拖拽创建关系时的实时连线预览
                                if (_connectingFromId != null &&
                                    _connectingCurrentPos != null &&
                                    _positions.containsKey(_connectingFromId))
                                  CustomPaint(
                                    size: canvasSize,
                                    painter: _ConnectingLinePainter(
                                      from: _positions[_connectingFromId]!,
                                      to: _connectingCurrentPos!,
                                      color: AppColors.brand,
                                    ),
                                  ),
                                for (var character in characters)
                                  if (_positions.containsKey(character.id))
                                    _DraggableNode(
                                      character: character,
                                      position:
                                          _positions[character.id]!,
                                      allCharacters: characters,
                                      relations: relations,
                                      onDragUpdate: (newPos) {
                                        setState(() {
                                          _positions[character.id] =
                                              newPos;
                                          _graphRevision++;
                                        });
                                      },
                                      onDragEnd: (newPos) {
                                        _savePosition(
                                            character.id, newPos);
                                      },
                                      onConnectStart: (startPos) =>
                                          _onStartConnecting(
                                              character.id, startPos),
                                      onConnectUpdate: _onUpdateConnecting,
                                      onConnectEnd: () =>
                                          _onEndConnecting(characters),
                                      onRemove: () =>
                                          _removeFromCanvas(character.id),
                                      onManageRelations: () =>
                                          _showRelationManager(
                                              character,
                                              characters,
                                              relations),
                                      onEdit: () {
                                        showDialog(
                                          context: context,
                                          builder: (_) => CharacterDialog(
                                            worldId: widget.worldId,
                                            character: character,
                                          ),
                                        ).then((_) {
                                          ref.invalidate(
                                              charactersByWorldProvider(
                                                  widget.worldId));
                                        });
                                      },
                                    ),
                                if (candidateData.isNotEmpty)
                                  Center(
                                    child: Container(
                                      padding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 24,
                                              vertical: 12),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary
                                            .withValues(alpha: 0.15),
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '松开放置人物',
                                        style: TextStyle(
                                          color: theme
                                              .colorScheme.primary,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('错误: $error')),
      ),
    );
  }
}

// --- 性别形状 ---

Widget _buildShape(String gender, double size, Color color, String label) {
  final half = size;
  final text = label.isNotEmpty ? label[0] : '?';

  if (gender == '男') {
    // 方形
    return Container(
      width: half * 2,
      height: half * 2,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      alignment: Alignment.center,
      child: Text(text,
          style: TextStyle(
              color: Colors.white,
              fontSize: half * 0.75,
              fontWeight: FontWeight.bold)),
    );
  } else if (gender == '女') {
    // 圆形
    return CircleAvatar(
      radius: half,
      backgroundColor: color,
      child: Text(text,
          style: TextStyle(
              color: Colors.white,
              fontSize: half * 0.75,
              fontWeight: FontWeight.bold)),
    );
  } else {
    // 菱形
    return Transform.rotate(
      angle: pi / 4,
      child: Container(
        width: half * 1.6,
        height: half * 1.6,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(3),
        ),
        alignment: Alignment.center,
        child: Transform.rotate(
          angle: -pi / 4,
          child: Text(text,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: half * 0.65,
                  fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}

// --- 侧边栏条目 ---

class _SidebarItem extends StatelessWidget {
  final Character character;
  final bool placed;

  const _SidebarItem({required this.character, required this.placed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = character.status == 1
        ? Colors.grey
        : theme.colorScheme.primary;

    return Opacity(
      opacity: placed ? 0.4 : 1.0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildShape(character.gender, 22, color, character.name),
          const SizedBox(height: 4),
          Text(
            character.name,
            style: TextStyle(
              fontSize: 11,
              color: placed
                  ? theme.colorScheme.onSurfaceVariant
                  : null,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// --- 画布上可拖拽节点 ---

class _DraggableNode extends StatefulWidget {
  final Character character;
  final Offset position;
  final List<Character> allCharacters;
  final List<Relation> relations;
  final ValueChanged<Offset> onDragUpdate;
  final ValueChanged<Offset> onDragEnd;
  final ValueChanged<Offset>? onConnectStart;
  final ValueChanged<Offset>? onConnectUpdate;
  final VoidCallback? onConnectEnd;
  final VoidCallback onRemove;
  final VoidCallback onManageRelations;
  final VoidCallback onEdit;

  const _DraggableNode({
    required this.character,
    required this.position,
    required this.allCharacters,
    required this.relations,
    required this.onDragUpdate,
    required this.onDragEnd,
    this.onConnectStart,
    this.onConnectUpdate,
    this.onConnectEnd,
    required this.onRemove,
    required this.onManageRelations,
    required this.onEdit,
  });

  @override
  State<_DraggableNode> createState() => _DraggableNodeState();
}

class _DraggableNodeState extends State<_DraggableNode> {
  late Offset _pos;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _pos = widget.position;
  }

  @override
  void didUpdateWidget(_DraggableNode old) {
    super.didUpdateWidget(old);
    if (old.position != widget.position) {
      _pos = widget.position;
    }
  }

  void _showContextMenu(TapDownDetails details) {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        details.globalPosition.dx,
        details.globalPosition.dy,
        details.globalPosition.dx,
        details.globalPosition.dy,
      ),
      items: [
        PopupMenuItem(
          height: 36,
          onTap: widget.onEdit,
          child: const Row(
            children: [
              Icon(Icons.edit, size: 18),
              SizedBox(width: 8),
              Text('编辑人物'),
            ],
          ),
        ),
        PopupMenuItem(
          height: 36,
          onTap: widget.onManageRelations,
          child: const Row(
            children: [
              Icon(Icons.hub, size: 18),
              SizedBox(width: 8),
              Text('管理关系'),
            ],
          ),
        ),
        PopupMenuItem(
          height: 36,
          onTap: widget.onRemove,
          child: Row(
            children: [
              Icon(Icons.remove_circle_outline,
                  size: 18,
                  color: Theme.of(context).colorScheme.error),
              const SizedBox(width: 8),
              const Text('移回侧栏'),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.character.name;
    final color = widget.character.status == 1
        ? Colors.grey
        : Theme.of(context).colorScheme.primary;

    return Positioned(
      left: _pos.dx - 30,
      top: _pos.dy - 30,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            GestureDetector(
              onSecondaryTapDown: _showContextMenu,
              onLongPressStart: (details) => _showContextMenu(
                TapDownDetails(
                  globalPosition: details.globalPosition,
                  localPosition: details.localPosition,
                ),
              ),
              onPanUpdate: (details) {
                setState(() {
                  _pos += details.delta;
                });
                widget.onDragUpdate(_pos);
              },
              onPanEnd: (_) {
                widget.onDragEnd(_pos);
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildShape(widget.character.gender, 24, color, name),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: 64,
                    child: Text(
                      name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            // 节点连接手柄：鼠标悬停在节点上时浮现
            if (_isHovered)
              Positioned(
                right: -6,
                top: 15,
                child: Tooltip(
                  message: '拖拽到另一人物创建关系',
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onPanStart: (details) {
                      widget.onConnectStart?.call(_pos);
                    },
                    onPanUpdate: (details) {
                      widget.onConnectUpdate?.call(details.delta);
                    },
                    onPanEnd: (_) {
                      widget.onConnectEnd?.call();
                    },
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: AppColors.brand,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.add,
                        size: 11,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// --- 实时连接预览线 ---

class _ConnectingLinePainter extends CustomPainter {
  final Offset from;
  final Offset to;
  final Color color;

  _ConnectingLinePainter({
    required this.from,
    required this.to,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final haloPaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..strokeWidth = 6.0
      ..style = PaintingStyle.stroke;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    canvas.drawLine(from, to, haloPaint);
    canvas.drawLine(from, to, paint);

    final endCircle = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(to, 5.0, endCircle);
  }

  @override
  bool shouldRepaint(covariant _ConnectingLinePainter old) =>
      old.from != from || old.to != to || old.color != color;
}

// --- 网格背景 ---

class _GridPainter extends CustomPainter {
  final Color color;

  _GridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.5;

    const step = 40.0;
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter old) => old.color != color;
}

// --- 关系连线绘制 ---

// --- 关系连线绘制 ---

class _RelationPainter extends CustomPainter {
  final List<Relation> relations;
  final Map<int, Offset> positions;
  final List<Character> characters;
  final int revision;
  final int? selectedRelationId;
  final bool isDark;

  _RelationPainter({
    required this.relations,
    required this.positions,
    required this.characters,
    required this.revision,
    this.selectedRelationId,
    this.isDark = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    final characterMap = {for (final c in characters) c.id: c};

    // 分离家谱组和普通组
    final familyGroups = <String, List<Relation>>{};
    final normalGroups = <String, List<Relation>>{};

    for (final rel in relations) {
      if (!positions.containsKey(rel.fromCharacterId) ||
          !positions.containsKey(rel.toCharacterId)) {
        continue;
      }
      final key = _pairKey(rel.fromCharacterId, rel.toCharacterId);
      if (rel.relationGroupId != null &&
          _familyTypes.contains(rel.relationType)) {
        familyGroups
            .putIfAbsent(rel.relationGroupId!, () => [])
            .add(rel);
      } else {
        normalGroups.putIfAbsent(key, () => []).add(rel);
      }
    }

    // 绘制家谱
    for (final entry in familyGroups.entries) {
      _drawFamilyGroup(canvas, textPainter, linePaint, entry.value, characterMap);
    }

    // 绘制普通关系
    for (final entry in normalGroups.entries) {
      _drawNormalGroup(canvas, textPainter, linePaint, entry.value, characterMap);
    }
  }

  // --- 家谱图：遗传图风格 ---

  void _drawFamilyGroup(
    Canvas canvas,
    TextPainter tp,
    Paint paint,
    List<Relation> group,
    Map<int, Character> characterMap,
  ) {
    // 收集父母和子女
    final parentIds = <int>{};
    final childIds = <int>{};

    for (final rel in group) {
      // fromCharacterId = 父母, toCharacterId = 子女
      if (rel.fromCharacterId != rel.toCharacterId) {
        parentIds.add(rel.fromCharacterId);
        childIds.add(rel.toCharacterId);
      }
    }

    final parents =
        parentIds.map((id) => positions[id]).whereType<Offset>().toList();
    final children =
        childIds.map((id) => positions[id]).whereType<Offset>().toList();

    if (parents.isEmpty || children.isEmpty) return;

    final color = Colors.blue.shade300;
    paint.color = color;
    paint.strokeWidth = 2.0;

    final childYs = children.map((c) => c.dy).toList();
    final minChildY = childYs.reduce(min);

    final Offset parentMid;
    if (parents.length >= 2) {
      final p1 = parents[0];
      final p2 = parents[1];
      final p1Id = parentIds.first;
      final p2Id = parentIds.skip(1).first;

      final edge1 = GraphGeometry.getExitPoint(
        fromCenter: p1,
        toCenter: p2,
        fromGender: characterMap[p1Id]?.gender ?? '',
      );
      final edge2 = GraphGeometry.getEntryPoint(
        fromCenter: p1,
        toCenter: p2,
        toGender: characterMap[p2Id]?.gender ?? '',
      );
      canvas.drawLine(edge1, edge2, paint);

      // 父母中点
      parentMid = Offset((edge1.dx + edge2.dx) / 2, (edge1.dy + edge2.dy) / 2);

      // 更多父母连到中点
      for (var i = 2; i < parents.length; i++) {
        final pi = parents[i];
        final pid = parentIds.skip(i).first;
        final edge = GraphGeometry.getExitPoint(
          fromCenter: pi,
          toCenter: parentMid,
          fromGender: characterMap[pid]?.gender ?? '',
        );
        canvas.drawLine(edge, parentMid, paint);
      }
    } else {
      // 单亲家庭支持
      parentMid = parents[0];
    }

    // 确定 busY：在 parentMid 下方
    double busY;
    if (minChildY > parentMid.dy) {
      busY = parentMid.dy + (minChildY - parentMid.dy) * 0.4;
    } else {
      busY = parentMid.dy + 50;
    }

    final busStart = Offset(parentMid.dx, busY);
    final topPoint = parents.length >= 2
        ? parentMid
        : GraphGeometry.calculateBoundaryIntersection(
            nodeCenter: parentMid,
            gender: characterMap[parentIds.first]?.gender ?? '',
            angle: pi / 2,
          );
    canvas.drawLine(topPoint, busStart, paint);

    if (children.length == 1) {
      final child = children[0];
      final childId = childIds.first;
      final junction = Offset(busStart.dx, busStart.dy);
      final midPoint = Offset(child.dx, busY);
      final cEdge = GraphGeometry.getEntryPoint(
        fromCenter: midPoint,
        toCenter: child,
        toGender: characterMap[childId]?.gender ?? '',
      );

      canvas.drawLine(junction, midPoint, paint);
      canvas.drawLine(midPoint, cEdge, paint);

      final childDir = (child - midPoint).direction;
      _drawArrowDir(canvas, cEdge, childDir, color);
    } else {
      final childXs = children.map((c) => c.dx).toList()..sort();
      final busLeft = Offset(childXs.first, busY);
      final busRight = Offset(childXs.last, busY);

      canvas.drawLine(
        Offset(min(busStart.dx, busLeft.dx), busY),
        Offset(max(busStart.dx, busRight.dx), busY),
        paint,
      );

      for (var i = 0; i < children.length; i++) {
        final child = children[i];
        final childId = childIds.skip(i).first;
        final junction = Offset(child.dx, busY);
        final cEdge = GraphGeometry.getEntryPoint(
          fromCenter: junction,
          toCenter: child,
          toGender: characterMap[childId]?.gender ?? '',
        );
        canvas.drawLine(junction, cEdge, paint);
        final childDir = (child - junction).direction;
        _drawArrowDir(canvas, cEdge, childDir, color);
      }
    }

    final isSelected = group.any((r) => r.id == selectedRelationId);
    final relType = group.first.relationType;
    _drawLabel(
      canvas,
      tp,
      relType,
      Offset(parentMid.dx, parentMid.dy + 16),
      isSelected: isSelected,
      isDark: isDark,
    );
  }

  // --- 普通关系：弧线/直线 ---

  void _drawNormalGroup(
    Canvas canvas,
    TextPainter tp,
    Paint paint,
    List<Relation> group,
    Map<int, Character> characterMap,
  ) {
    final baseFromId = group.first.fromCharacterId;
    final baseToId = group.first.toCharacterId;
    final from = positions[baseFromId]!;
    final to = positions[baseToId]!;
    final fromGender = characterMap[baseFromId]?.gender ?? '';
    final toGender = characterMap[baseToId]?.gender ?? '';
    final count = group.length;

    for (var i = 0; i < count; i++) {
      final rel = group[i];
      final isSelected = (rel.id == selectedRelationId);
      final color = isSelected
          ? AppColors.brand
          : (rel.isBidirectional
              ? Colors.blue.shade300
              : Colors.orange.shade300);
      paint.color = color;
      paint.strokeWidth = isSelected ? 3.0 : 2.0;

      final isReversed = (rel.fromCharacterId != baseFromId);

      final offset = count == 1 ? 0.0 : (i - (count - 1) / 2) * 40.0;
      final dx = to.dx - from.dx;
      final dy = to.dy - from.dy;
      final dist = sqrt(dx * dx + dy * dy);
      final nx = dist > 0 ? -dy / dist : 0.0;
      final ny = dist > 0 ? dx / dist : 0.0;

      if (count == 1) {
        final p1 = GraphGeometry.getExitPoint(
          fromCenter: from,
          toCenter: to,
          fromGender: fromGender,
        );
        final p2 = GraphGeometry.getEntryPoint(
          fromCenter: from,
          toCenter: to,
          toGender: toGender,
        );

        if (isSelected) {
          final haloPaint = Paint()
            ..color = AppColors.brand.withValues(alpha: 0.35)
            ..strokeWidth = 7.0
            ..style = PaintingStyle.stroke;
          canvas.drawLine(p1, p2, haloPaint);
        }

        canvas.drawLine(p1, p2, paint);

        if (rel.isBidirectional) {
          _drawArrow(canvas, p1, p2, color);
          _drawArrow(canvas, p2, p1, color);
        } else {
          if (isReversed) {
            _drawArrow(canvas, p2, p1, color);
          } else {
            _drawArrow(canvas, p1, p2, color);
          }
        }

        final mid = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);
        _drawLabel(
          canvas,
          tp,
          rel.relationType,
          mid,
          isSelected: isSelected,
          isDark: isDark,
        );
      } else {
        final cp = Offset(
          (from.dx + to.dx) / 2 + nx * offset,
          (from.dy + to.dy) / 2 + ny * offset,
        );

        final tStart = Offset(cp.dx - from.dx, cp.dy - from.dy).direction;
        final tEnd = Offset(to.dx - cp.dx, to.dy - cp.dy).direction;

        final p1 = GraphGeometry.calculateBoundaryIntersection(
          nodeCenter: from,
          gender: fromGender,
          angle: tStart,
        );
        final p2 = GraphGeometry.calculateBoundaryIntersection(
          nodeCenter: to,
          gender: toGender,
          angle: tEnd + pi,
        );

        final adjCp = Offset(
          (p1.dx + p2.dx) / 2 + nx * offset,
          (p1.dy + p2.dy) / 2 + ny * offset,
        );

        final path = Path()
          ..moveTo(p1.dx, p1.dy)
          ..quadraticBezierTo(adjCp.dx, adjCp.dy, p2.dx, p2.dy);

        if (isSelected) {
          final haloPaint = Paint()
            ..color = AppColors.brand.withValues(alpha: 0.35)
            ..strokeWidth = 7.0
            ..style = PaintingStyle.stroke;
          canvas.drawPath(path, haloPaint);
        }

        canvas.drawPath(path, paint);

        if (rel.isBidirectional) {
          _drawArrowDir(canvas, p2, tEnd, color);
          _drawArrowDir(canvas, p1, tStart + pi, color);
        } else {
          if (isReversed) {
            _drawArrowDir(canvas, p1, tStart + pi, color);
          } else {
            _drawArrowDir(canvas, p2, tEnd, color);
          }
        }

        const t = 0.5;
        final labelX = (1 - t) * (1 - t) * p1.dx +
            2 * (1 - t) * t * adjCp.dx +
            t * t * p2.dx;
        final labelY = (1 - t) * (1 - t) * p1.dy +
            2 * (1 - t) * t * adjCp.dy +
            t * t * p2.dy;
        _drawLabel(
          canvas,
          tp,
          rel.relationType,
          Offset(labelX, labelY),
          isSelected: isSelected,
          isDark: isDark,
        );
      }
    }
  }

  String _pairKey(int a, int b) {
    final minId = a < b ? a : b;
    final maxId = a < b ? b : a;
    return '$minId-$maxId';
  }

  void _drawLabel(
    Canvas canvas,
    TextPainter tp,
    String text,
    Offset center, {
    bool isSelected = false,
    bool isDark = false,
  }) {
    final textColor = isSelected
        ? AppColors.brand
        : (isDark ? Colors.white70 : Colors.grey.shade800);
    final bgColor = isSelected
        ? (isDark ? AppColors.brand.withValues(alpha: 0.25) : AppColors.brandLight)
        : (isDark ? const Color(0xFF2C2C2E) : Colors.white);
    final borderColor = isSelected
        ? AppColors.brand
        : (isDark ? const Color(0xFF3A3A3C) : Colors.grey.shade300);

    tp.text = TextSpan(
      text: text,
      style: AppFonts.textStyle(
        color: textColor,
        fontSize: 11,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
    tp.layout();

    final rect = Rect.fromCenter(
      center: center,
      width: tp.width + 12,
      height: tp.height + 6,
    );
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(4));

    if (isSelected) {
      final shadowPaint = Paint()
        ..color = AppColors.brand.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 4);
      canvas.drawRRect(rrect, shadowPaint);
    }

    // Badge background
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = bgColor
        ..style = PaintingStyle.fill,
    );

    // Badge border
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 1.5 : 1.0,
    );

    // Label text
    tp.paint(
      canvas,
      Offset(center.dx - tp.width / 2, center.dy - tp.height / 2),
    );
  }

  void _drawArrow(Canvas canvas, Offset from, Offset to, Color color) {
    _drawArrowDir(canvas, to, (to - from).direction, color);
  }

  void _drawArrowDir(
      Canvas canvas, Offset pos, double direction, Color color) {
    const arrowSize = 10.0;
    const arrowAngle = 0.5;

    final path = Path()
      ..moveTo(pos.dx, pos.dy)
      ..lineTo(
        pos.dx - arrowSize * cos(direction - arrowAngle),
        pos.dy - arrowSize * sin(direction - arrowAngle),
      )
      ..moveTo(pos.dx, pos.dy)
      ..lineTo(
        pos.dx - arrowSize * cos(direction + arrowAngle),
        pos.dy - arrowSize * sin(direction + arrowAngle),
      );

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _RelationPainter old) =>
      old.revision != revision ||
      old.relations != relations ||
      old.positions != positions ||
      old.selectedRelationId != selectedRelationId ||
      old.isDark != isDark;
}

/// Helper function to calculate label centers for each relation in scene space.
Map<int, Offset> calculateRelationLabelCenters({
  required List<Relation> relations,
  required Map<int, Offset> positions,
}) {
  final centers = <int, Offset>{};
  final familyGroups = <String, List<Relation>>{};
  final normalGroups = <String, List<Relation>>{};

  for (final rel in relations) {
    if (!positions.containsKey(rel.fromCharacterId) ||
        !positions.containsKey(rel.toCharacterId)) {
      continue;
    }
    final minId = min(rel.fromCharacterId, rel.toCharacterId);
    final maxId = max(rel.fromCharacterId, rel.toCharacterId);
    final key = '$minId-$maxId';

    if (rel.relationGroupId != null && _familyTypes.contains(rel.relationType)) {
      familyGroups.putIfAbsent(rel.relationGroupId!, () => []).add(rel);
    } else {
      normalGroups.putIfAbsent(key, () => []).add(rel);
    }
  }

  for (final entry in familyGroups.entries) {
    final group = entry.value;
    final parentIds = <int>{};
    for (final rel in group) {
      if (rel.fromCharacterId != rel.toCharacterId) {
        parentIds.add(rel.fromCharacterId);
      }
    }
    final parents = parentIds.map((id) => positions[id]).whereType<Offset>().toList();
    if (parents.isEmpty) continue;

    final parentMid = parents.length >= 2
        ? Offset((parents[0].dx + parents[1].dx) / 2, (parents[0].dy + parents[1].dy) / 2)
        : parents[0];
    final labelOffset = Offset(parentMid.dx, parentMid.dy + 16);
    for (final rel in group) {
      centers[rel.id] = labelOffset;
    }
  }

  for (final entry in normalGroups.entries) {
    final group = entry.value;
    final baseFromId = group.first.fromCharacterId;
    final baseToId = group.first.toCharacterId;
    final from = positions[baseFromId]!;
    final to = positions[baseToId]!;
    final count = group.length;

    for (var i = 0; i < count; i++) {
      final rel = group[i];
      final offset = count == 1 ? 0.0 : (i - (count - 1) / 2) * 40.0;
      final dx = to.dx - from.dx;
      final dy = to.dy - from.dy;
      final dist = sqrt(dx * dx + dy * dy);
      final nx = dist > 0 ? -dy / dist : 0.0;
      final ny = dist > 0 ? dx / dist : 0.0;

      if (count == 1) {
        centers[rel.id] = Offset((from.dx + to.dx) / 2, (from.dy + to.dy) / 2);
      } else {
        final cp = Offset(
          (from.dx + to.dx) / 2 + nx * offset,
          (from.dy + to.dy) / 2 + ny * offset,
        );
        const t = 0.5;
        final labelX = (1 - t) * (1 - t) * from.dx + 2 * (1 - t) * t * cp.dx + t * t * to.dx;
        final labelY = (1 - t) * (1 - t) * from.dy + 2 * (1 - t) * t * cp.dy + t * t * to.dy;
        centers[rel.id] = Offset(labelX, labelY);
      }
    }
  }

  return centers;
}

const _familyTypes = ['亲子', '父母', '父女', '父子', '母子', '母女', '家人'];

const _relationTypes = [
  '亲属',
  '朋友',
  '恋人',
  '师徒',
  '敌对',
  '宿敌',
  '同事',
  '其他',
];
