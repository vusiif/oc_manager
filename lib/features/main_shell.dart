import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'sidebar/tree_sidebar.dart';
import 'world/world_detail_page.dart';
import 'character/character_detail_page.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int? _selectedWorldId;
  int? _selectedGroupId;
  int? _selectedCharacterId;
  bool _sidebarVisible = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(_sidebarVisible ? Icons.menu_open : Icons.menu),
          tooltip: _sidebarVisible ? '收起侧栏' : '展开侧栏',
          onPressed: () {
            setState(() {
              _sidebarVisible = !_sidebarVisible;
            });
          },
        ),
        title: _buildTitle(),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: '搜索',
            onPressed: () => context.push('/search'),
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'tags',
                child: ListTile(
                  leading: Icon(Icons.label),
                  title: Text('标签管理'),
                ),
              ),
              const PopupMenuItem(
                value: 'drafts',
                child: ListTile(
                  leading: Icon(Icons.drafts),
                  title: Text('草稿箱'),
                ),
              ),
              const PopupMenuItem(
                value: 'trash',
                child: ListTile(
                  leading: Icon(Icons.delete),
                  title: Text('回收站'),
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: ListTile(
                  leading: Icon(Icons.settings),
                  title: Text('设置'),
                ),
              ),
              const PopupMenuItem(
                value: 'templates',
                child: ListTile(
                  leading: Icon(Icons.description),
                  title: Text('模板管理'),
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'tags') {
                context.push('/tags');
              } else if (value == 'drafts') {
                context.push('/drafts');
              } else if (value == 'trash') {
                context.push('/trash');
              } else if (value == 'settings') {
                context.push('/settings');
              } else if (value == 'templates') {
                context.push('/templates');
              }
            },
          ),
        ],
      ),
      body: Row(
        children: [
          // 侧栏
          if (_sidebarVisible)
            TreeSidebar(
              selectedWorldId: _selectedWorldId,
              selectedGroupId: _selectedGroupId,
              selectedCharacterId: _selectedCharacterId,
              onWorldSelected: (worldId) {
                setState(() {
                  _selectedWorldId = worldId;
                });
              },
              onGroupSelected: (groupId) {
                setState(() {
                  _selectedGroupId = groupId;
                });
              },
              onCharacterSelected: (characterId) {
                setState(() {
                  _selectedCharacterId = characterId;
                });
              },
            ),
          // 内容区
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    if (_selectedCharacterId != null && _selectedWorldId != null) {
      return const Text('人物详情');
    }
    if (_selectedWorldId != null) {
      return const Text('世界观');
    }
    return const Text('OC Manager');
  }

  Widget _buildContent() {
    // 没有选中世界观时显示欢迎页
    if (_selectedWorldId == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.public, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              '选择或创建一个世界观',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              '在左侧侧栏中操作',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // 选中了人物，显示人物详情
    if (_selectedCharacterId != null) {
      return CharacterDetailPage(
        worldId: _selectedWorldId!,
        characterId: _selectedCharacterId!,
      );
    }

    // 选中了世界观（或分组），显示人物列表
    return WorldDetailPage(
      worldId: _selectedWorldId!,
      selectedGroupId: _selectedGroupId,
      onCharacterSelected: (characterId) {
        setState(() {
          _selectedCharacterId = characterId;
        });
      },
    );
  }
}
