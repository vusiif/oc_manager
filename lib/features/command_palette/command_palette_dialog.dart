import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/design_tokens.dart';
import '../../providers/world_provider.dart';
import 'command_palette_model.dart';
import 'command_palette_service.dart';
import 'widgets/command_category_filter_bar.dart';
import 'widgets/command_palette_footer.dart';
import 'widgets/command_palette_item_tile.dart';

bool _isCommandPaletteShowing = false;

/// Opens the global Command Palette modal dialog safely without duplicate overlays.
Future<void> showCommandPalette(BuildContext context) async {
  if (_isCommandPaletteShowing) return;
  _isCommandPaletteShowing = true;
  try {
    await showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withAlpha(120),
      builder: (_) => const CommandPaletteDialog(),
    );
  } finally {
    _isCommandPaletteShowing = false;
  }
}

class CommandPaletteDialog extends ConsumerStatefulWidget {
  const CommandPaletteDialog({super.key});

  @override
  ConsumerState<CommandPaletteDialog> createState() =>
      _CommandPaletteDialogState();
}

class _CommandPaletteDialogState extends ConsumerState<CommandPaletteDialog> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  final _scrollController = ScrollController();

  List<CommandPaletteItem> _allItems = [];
  List<CommandPaletteItem> _displayItems = [];
  String _selectedCategory =
      'all'; // 'all', 'command', 'world', 'character', 'lore'
  int _selectedIndex = 0;
  bool _isLoading = true;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _loadInitialItems();
  }

  Future<void> _loadInitialItems() async {
    setState(() => _isLoading = true);
    final activeId = ref.read(activeWorldIdProvider);
    final items = await CommandPaletteService.searchItems(
      ref,
      '',
      activeWorldId: activeId,
    );
    if (mounted) {
      setState(() {
        _allItems = items;
        _isLoading = false;
      });
      _applyFilter();
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 150), () async {
      final activeId = ref.read(activeWorldIdProvider);
      setState(() => _isLoading = true);
      final items = await CommandPaletteService.searchItems(
        ref,
        query,
        activeWorldId: activeId,
      );
      if (mounted) {
        setState(() {
          _allItems = items;
          _isLoading = false;
        });
        _applyFilter();
      }
    });
  }

  void _applyFilter() {
    List<CommandPaletteItem> filtered = _allItems;
    if (_selectedCategory != 'all') {
      filtered = _allItems.where((item) {
        return item.category.name == _selectedCategory;
      }).toList();
    }

    setState(() {
      _displayItems = filtered;
      _selectedIndex = 0;
    });
  }

  void _moveSelection(int delta) {
    if (_displayItems.isEmpty) return;
    setState(() {
      _selectedIndex =
          (_selectedIndex + delta + _displayItems.length) %
          _displayItems.length;
    });
    _scrollToIndex(_selectedIndex);
  }

  void _scrollToIndex(int index) {
    if (!_scrollController.hasClients) return;
    const itemHeight = 60.0;
    final targetOffset = (index * itemHeight).clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );
    _scrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOut,
    );
  }

  Future<void> _executeCurrent() async {
    if (_displayItems.isEmpty || _selectedIndex >= _displayItems.length) return;
    final item = _displayItems[_selectedIndex];
    _executeItem(item);
  }

  Future<void> _executeItem(CommandPaletteItem item) async {
    // Pop dialog first to release modal focus cleanly
    Navigator.of(context).pop();
    // Allow small frame gap then trigger execution
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        item.onExecute(context, ref);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenSize = MediaQuery.of(context).size;
    final dialogWidth = min(screenSize.width * 0.85, 680.0);

    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
            _moveSelection(1);
            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
            _moveSelection(-1);
            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.numpadEnter) {
            _executeCurrent();
            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.escape) {
            Navigator.of(context).pop();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Center(
        child: Container(
          width: dialogWidth,
          constraints: const BoxConstraints(maxHeight: 540),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(isDark ? 90 : 40),
                blurRadius: 32,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSearchHeader(theme, isDark),
                CommandCategoryFilterBar(
                  selectedCategory: _selectedCategory,
                  isDark: isDark,
                  onSelectCategory: (cat) {
                    setState(() => _selectedCategory = cat);
                    _applyFilter();
                  },
                ),
                const Divider(height: 1, thickness: 1),
                Expanded(
                  child: _isLoading && _displayItems.isEmpty
                      ? const Center(
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : _displayItems.isEmpty
                      ? _buildEmptyState(theme, isDark)
                      : _buildResultsList(theme, isDark),
                ),
                const Divider(height: 1, thickness: 1),
                CommandPaletteFooter(
                  itemCount: _displayItems.length,
                  isDark: isDark,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchHeader(ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.brand.withAlpha(isDark ? 50 : 25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.terminal_rounded,
              color: AppColors.brand,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _focusNode,
              autofocus: true,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : Colors.black87,
              ),
              decoration: InputDecoration(
                hintText: '输入命令、角色、世界观或词条... (↑↓ 移动, ↵ 执行)',
                hintStyle: TextStyle(
                  fontSize: 14,
                  color: isDark
                      ? const Color(0xFF64748B)
                      : const Color(0xFF94A3B8),
                  fontWeight: FontWeight.normal,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_rounded, size: 18),
              tooltip: '清空输入',
              onPressed: () {
                _searchController.clear();
                _onSearchChanged('');
              },
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF475569)
                    : const Color(0xFFCBD5E1),
                width: 0.8,
              ),
            ),
            child: Text(
              'ESC',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF64748B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList(ThemeData theme, bool isDark) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 6),
      itemCount: _displayItems.length,
      itemBuilder: (context, index) {
        final item = _displayItems[index];
        final isSelected = index == _selectedIndex;

        return CommandPaletteItemTile(
          item: item,
          isSelected: isSelected,
          isDark: isDark,
          onTap: () => _executeItem(item),
          onHover: () {
            setState(() => _selectedIndex = index);
          },
        );
      },
    );
  }

  Widget _buildEmptyState(ThemeData theme, bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 42,
            color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
          ),
          const SizedBox(height: 12),
          Text(
            '未找到匹配的命令或项目',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '试着搜索世界观、角色名，或输入拼音关键字',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }
}
