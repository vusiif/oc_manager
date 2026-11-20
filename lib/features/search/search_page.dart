import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/character_status.dart';
import '../../data/database/app_database.dart';
import '../../data/database/daos/character_dao.dart';
import '../../providers/database_provider.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _searchController = TextEditingController();
  List<_SearchResultItem> _results = [];
  List<World> _worlds = [];
  bool _isSearching = false;

  Timer? _debounceTimer;
  int _queryVersion = 0;

  int? _selectedWorldId;
  int? _selectedStatusCode;

  @override
  void initState() {
    super.initState();
    _loadWorlds();
  }

  Future<void> _loadWorlds() async {
    final db = ref.read(databaseProvider);
    final worlds = await db.worldDao.getAllWorlds();
    if (mounted) {
      setState(() => _worlds = worlds);
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 250), () {
      _executeSearch();
    });
  }

  Future<void> _executeSearch() async {
    final keyword = _searchController.text.trim();
    if (keyword.isEmpty) {
      setState(() {
        _results = [];
        _isSearching = false;
      });
      return;
    }

    final currentVersion = ++_queryVersion;
    setState(() => _isSearching = true);

    try {
      final db = ref.read(databaseProvider);
      final rawResults = await db.characterDao.searchCharactersDeep(
        keyword,
        worldId: _selectedWorldId,
        status: _selectedStatusCode,
      );

      final worldMap = {for (final w in _worlds) w.id: w.name};

      final items = rawResults.map((r) {
        return _SearchResultItem(
          searchResult: r,
          worldName: worldMap[r.character.worldId] ?? '未知世界观',
        );
      }).toList();

      if (mounted && currentVersion == _queryVersion) {
        setState(() {
          _results = items;
          _isSearching = false;
        });
      }
    } catch (_) {
      if (mounted && currentVersion == _queryVersion) {
        setState(() => _isSearching = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: '搜索人物、小传、标签、自定义字段、阵营...',
            border: InputBorder.none,
          ),
          autofocus: true,
          onChanged: _onSearchChanged,
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                _debounceTimer?.cancel();
                setState(() => _results = []);
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips Section
          _buildFilterChipsBar(),

          const Divider(height: 1),

          // Content Area
          Expanded(
            child: _isSearching
                ? const Center(child: CircularProgressIndicator())
                : _results.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _searchController.text.isEmpty
                              ? Icons.search
                              : Icons.search_off,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchController.text.isEmpty
                              ? '输入关键字（姓名、小传、自定义字段、标签、阵营）检索'
                              : '没有找到匹配的人物',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _results.length,
                    itemBuilder: (context, index) {
                      final item = _results[index];
                      final char = item.searchResult.character;
                      final statusConfig = CharacterCreationStatus.find(
                        char.status,
                      );

                      return Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: Theme.of(
                              context,
                            ).colorScheme.outlineVariant.withValues(alpha: 0.5),
                          ),
                        ),
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primaryContainer,
                            child: Text(
                              char.name.isNotEmpty ? char.name[0] : '?',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                          title: Row(
                            children: [
                              Text(
                                char.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  item.worldName,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    item.searchResult.matchedField,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    item.searchResult.matchedSnippet,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: statusConfig.color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: statusConfig.color.withValues(
                                  alpha: 0.4,
                                ),
                              ),
                            ),
                            child: Text(
                              statusConfig.label,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: statusConfig.color,
                              ),
                            ),
                          ),
                          onTap: () => context.push(
                            '/world/${char.worldId}/character/${char.id}',
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChipsBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // World filter chips
          Text(
            '世界观：',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          FilterChip(
            label: const Text('全部', style: TextStyle(fontSize: 12)),
            selected: _selectedWorldId == null,
            onSelected: (_) {
              setState(() => _selectedWorldId = null);
              _executeSearch();
            },
          ),
          const SizedBox(width: 6),
          for (final w in _worlds) ...[
            FilterChip(
              label: Text(w.name, style: const TextStyle(fontSize: 12)),
              selected: _selectedWorldId == w.id,
              onSelected: (selected) {
                setState(() => _selectedWorldId = selected ? w.id : null);
                _executeSearch();
              },
            ),
            const SizedBox(width: 6),
          ],

          const SizedBox(width: 12),
          Text(
            '状态：',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          FilterChip(
            label: const Text('全部', style: TextStyle(fontSize: 12)),
            selected: _selectedStatusCode == null,
            onSelected: (_) {
              setState(() => _selectedStatusCode = null);
              _executeSearch();
            },
          ),
          const SizedBox(width: 6),
          for (final s in CharacterCreationStatus.all) ...[
            FilterChip(
              label: Text(s.label, style: const TextStyle(fontSize: 12)),
              selected: _selectedStatusCode == s.code,
              onSelected: (selected) {
                setState(() => _selectedStatusCode = selected ? s.code : null);
                _executeSearch();
              },
            ),
            const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }
}

class _SearchResultItem {
  final CharacterSearchResult searchResult;
  final String worldName;

  _SearchResultItem({required this.searchResult, required this.worldName});
}
