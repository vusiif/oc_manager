import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/database_provider.dart';
import '../../data/database/app_database.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _searchController = TextEditingController();
  List<_SearchResult> _results = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: '搜索人物...',
            border: InputBorder.none,
          ),
          autofocus: true,
          onChanged: _onSearch,
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                setState(() => _results = []);
              },
            ),
        ],
      ),
      body: _isSearching
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
                            ? '输入关键字搜索人物'
                            : '没有找到匹配的人物',
                        style:
                            const TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _results.length,
                  itemBuilder: (context, index) {
                    final result = _results[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              Theme.of(context).colorScheme.primaryContainer,
                          child: Text(
                            result.character.name.isNotEmpty
                                ? result.character.name[0]
                                : '?',
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                            ),
                          ),
                        ),
                        title: Text(result.character.name),
                        subtitle: Text(result.worldName),
                        trailing: result.character.status == 1
                            ? const Chip(
                                label: Text('草稿',
                                    style: TextStyle(fontSize: 12)),
                                padding: EdgeInsets.zero,
                              )
                            : null,
                        onTap: () => context.push(
                          '/world/${result.character.worldId}/character/${result.character.id}',
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  void _onSearch(String keyword) {
    if (keyword.trim().isEmpty) {
      setState(() => _results = []);
      return;
    }

    setState(() => _isSearching = true);

    _searchCharacters(keyword.trim()).then((results) {
      if (mounted) {
        setState(() {
          _results = results;
          _isSearching = false;
        });
      }
    });
  }

  Future<List<_SearchResult>> _searchCharacters(String keyword) async {
    final db = ref.read(databaseProvider);
    final characters = await db.characterDao.searchCharacters(keyword);
    final worlds = await db.worldDao.getAllWorlds();

    final worldMap = {for (var w in worlds) w.id: w};

    return characters.map((c) {
      final world = worldMap[c.worldId];
      return _SearchResult(
        character: c,
        worldName: world?.name ?? '未知世界观',
      );
    }).toList();
  }
}

class _SearchResult {
  final Character character;
  final String worldName;

  _SearchResult({required this.character, required this.worldName});
}
