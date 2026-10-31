import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/database/app_database.dart';
import '../../../core/constants/character_status.dart';
import '../../../core/design/components/oc_avatar.dart';
import '../../../providers/character_provider.dart';

enum TableSortColumn {
  name,
  gender,
  status,
  updatedAt,
}

/// 世界观多维表格矩阵视图 (Interactive Table / Matrix View)
class WorldTableView extends ConsumerStatefulWidget {
  final int worldId;
  final List<Character> characters;
  final void Function(int characterId)? onCharacterSelected;

  const WorldTableView({
    super.key,
    required this.worldId,
    required this.characters,
    this.onCharacterSelected,
  });

  @override
  ConsumerState<WorldTableView> createState() => _WorldTableViewState();
}

class _WorldTableViewState extends ConsumerState<WorldTableView> {
  String _searchQuery = '';
  String? _genderFilter;
  int? _statusFilter;
  bool _onlyFavorite = false;
  bool _onlyPinned = false;

  TableSortColumn _sortColumn = TableSortColumn.updatedAt;
  bool _sortAscending = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 1. 过滤逻辑
    final filtered = widget.characters.where((c) {
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchName = c.name.toLowerCase().contains(query);
        final matchDesc = c.description.toLowerCase().contains(query);
        if (!matchName && !matchDesc) return false;
      }
      if (_genderFilter != null && c.gender != _genderFilter) {
        return false;
      }
      if (_statusFilter != null && c.status != _statusFilter) {
        return false;
      }
      if (_onlyFavorite && !c.isFavorite) {
        return false;
      }
      if (_onlyPinned && !c.isPinned) {
        return false;
      }
      return true;
    }).toList();

    // 2. 排序逻辑
    filtered.sort((a, b) {
      int cmp = 0;
      switch (_sortColumn) {
        case TableSortColumn.name:
          cmp = a.name.compareTo(b.name);
          break;
        case TableSortColumn.gender:
          cmp = a.gender.compareTo(b.gender);
          break;
        case TableSortColumn.status:
          cmp = a.status.compareTo(b.status);
          break;
        case TableSortColumn.updatedAt:
          cmp = a.updatedAt.compareTo(b.updatedAt);
          break;
      }
      return _sortAscending ? cmp : -cmp;
    });

    final allGenders = widget.characters
        .map((c) => c.gender.trim())
        .where((g) => g.isNotEmpty)
        .toSet()
        .toList();

    return Column(
      children: [
        // 顶部筛选与搜索栏
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
          child: Column(
            children: [
              Row(
                children: [
                  // 搜索框
                  Expanded(
                    flex: 3,
                    child: SizedBox(
                      height: 36,
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: '搜索人物姓名或小传…',
                          prefixIcon: const Icon(Icons.search, size: 16),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 16),
                                  onPressed: () =>
                                      setState(() => _searchQuery = ''),
                                )
                              : null,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onChanged: (val) =>
                            setState(() => _searchQuery = val.trim()),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // 性别筛选
                  DropdownButton<String?>(
                    value: _genderFilter,
                    hint: const Text('全部性别', style: TextStyle(fontSize: 13)),
                    underline: const SizedBox.shrink(),
                    items: [
                      const DropdownMenuItem(
                          value: null, child: Text('全部性别')),
                      for (final g in allGenders)
                        DropdownMenuItem(value: g, child: Text(g)),
                    ],
                    onChanged: (val) => setState(() => _genderFilter = val),
                  ),
                  const SizedBox(width: 12),

                  // 状态筛选
                  DropdownButton<int?>(
                    value: _statusFilter,
                    hint: const Text('全部状态', style: TextStyle(fontSize: 13)),
                    underline: const SizedBox.shrink(),
                    items: [
                      const DropdownMenuItem(
                          value: null, child: Text('全部状态')),
                      for (final s in CharacterCreationStatus.all)
                        DropdownMenuItem(
                          value: s.code,
                          child: Row(
                            children: [
                              Icon(s.icon, size: 14, color: s.color),
                              const SizedBox(width: 6),
                              Text(s.label),
                            ],
                          ),
                        ),
                    ],
                    onChanged: (val) => setState(() => _statusFilter = val),
                  ),
                  const SizedBox(width: 12),

                  // 收藏 / 置顶 FilterChips
                  FilterChip(
                    avatar: const Icon(Icons.star_rounded,
                        size: 14, color: Color(0xFFF59E0B)),
                    label: const Text('仅收藏'),
                    selected: _onlyFavorite,
                    visualDensity: VisualDensity.compact,
                    onSelected: (sel) => setState(() => _onlyFavorite = sel),
                  ),
                  const SizedBox(width: 6),
                  FilterChip(
                    avatar: Icon(Icons.push_pin_rounded,
                        size: 14, color: theme.colorScheme.primary),
                    label: const Text('仅置顶'),
                    selected: _onlyPinned,
                    visualDensity: VisualDensity.compact,
                    onSelected: (sel) => setState(() => _onlyPinned = sel),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // 表格主体
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.table_rows_outlined,
                        size: 48,
                        color: theme.colorScheme.outline,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '无匹配人物记录',
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: DataTable(
                      sortColumnIndex: _getSortIndex(),
                      sortAscending: _sortAscending,
                      headingRowColor: WidgetStatePropertyAll(
                        theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.4),
                      ),
                      columns: [
                        const DataColumn(label: Text('立绘/头像')),
                        DataColumn(
                          label: const Text('姓名'),
                          onSort: (idx, asc) => _changeSort(
                              TableSortColumn.name, idx, asc),
                        ),
                        DataColumn(
                          label: const Text('性别'),
                          onSort: (idx, asc) => _changeSort(
                              TableSortColumn.gender, idx, asc),
                        ),
                        DataColumn(
                          label: const Text('创作阶段'),
                          onSort: (idx, asc) => _changeSort(
                              TableSortColumn.status, idx, asc),
                        ),
                        const DataColumn(label: Text('快捷标记')),
                        DataColumn(
                          label: const Text('最近更新'),
                          onSort: (idx, asc) => _changeSort(
                              TableSortColumn.updatedAt, idx, asc),
                        ),
                        const DataColumn(label: Text('操作')),
                      ],
                      rows: filtered.map((c) {
                        return DataRow(
                          onSelectChanged: (_) =>
                              widget.onCharacterSelected?.call(c.id),
                          cells: [
                            // 1. 头像
                            DataCell(
                              OcAvatar(
                                avatarPath: c.avatarPath,
                                name: c.name,
                                gender: c.gender,
                                size: 28,
                              ),
                            ),
                            // 2. 姓名
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    c.name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 11,
                                    color: theme.colorScheme.primary
                                        .withValues(alpha: 0.6),
                                  ),
                                ],
                              ),
                            ),
                            // 3. 性别
                            DataCell(Text(c.gender.isEmpty ? '-' : c.gender)),
                            // 4. 状态（就地切换）
                            DataCell(
                              DropdownButton<int>(
                                value: c.status,
                                underline: const SizedBox.shrink(),
                                isDense: true,
                                items: [
                                  for (final s in CharacterCreationStatus.all)
                                    DropdownMenuItem(
                                      value: s.code,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(s.icon,
                                              size: 13, color: s.color),
                                          const SizedBox(width: 6),
                                          Text(
                                            s.label,
                                            style: TextStyle(
                                              fontSize: 12.5,
                                              color: s.color,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                                onChanged: (newVal) {
                                  if (newVal != null && newVal != c.status) {
                                    ref
                                        .read(characterActionsProvider)
                                        .updateStatus(c.id, newVal);
                                  }
                                },
                              ),
                            ),
                            // 5. 快捷置顶/收藏
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      c.isPinned
                                          ? Icons.push_pin_rounded
                                          : Icons.push_pin_outlined,
                                      size: 16,
                                      color: c.isPinned
                                          ? theme.colorScheme.primary
                                          : theme.colorScheme.outline,
                                    ),
                                    tooltip: c.isPinned ? '取消置顶' : '设为置顶',
                                    onPressed: () {
                                      ref
                                          .read(characterActionsProvider)
                                          .togglePin(c);
                                    },
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      c.isFavorite
                                          ? Icons.star_rounded
                                          : Icons.star_outline_rounded,
                                      size: 17,
                                      color: c.isFavorite
                                          ? const Color(0xFFF59E0B)
                                          : theme.colorScheme.outline,
                                    ),
                                    tooltip: c.isFavorite ? '取消收藏' : '加入收藏',
                                    onPressed: () {
                                      ref
                                          .read(characterActionsProvider)
                                          .toggleFavorite(c);
                                    },
                                  ),
                                ],
                              ),
                            ),
                            // 6. 最近更新时间
                            DataCell(
                              Text(
                                '${c.updatedAt.year}-${c.updatedAt.month.toString().padLeft(2, '0')}-${c.updatedAt.day.toString().padLeft(2, '0')}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            // 7. 操作
                            DataCell(
                              IconButton(
                                icon: const Icon(Icons.arrow_circle_right_outlined,
                                    size: 18),
                                tooltip: '打开人物详情档案',
                                onPressed: () =>
                                    widget.onCharacterSelected?.call(c.id),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  int _getSortIndex() {
    switch (_sortColumn) {
      case TableSortColumn.name:
        return 1;
      case TableSortColumn.gender:
        return 2;
      case TableSortColumn.status:
        return 3;
      case TableSortColumn.updatedAt:
        return 5;
    }
  }

  void _changeSort(TableSortColumn column, int idx, bool ascending) {
    setState(() {
      _sortColumn = column;
      _sortAscending = ascending;
    });
  }
}
