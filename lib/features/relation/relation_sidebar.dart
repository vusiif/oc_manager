import 'package:flutter/material.dart';

import '../../data/database/app_database.dart';
import 'relation_graph_node.dart';

/// Animated drawer showing characters that can be dragged onto the canvas.
class RelationCharacterDrawer extends StatelessWidget {
  final bool showSidebar;
  final List<Character> characters;
  final Map<int, Offset> positions;

  const RelationCharacterDrawer({
    super.key,
    required this.showSidebar,
    required this.characters,
    required this.positions,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ClipRect(
      child: AnimatedAlign(
        alignment: Alignment.centerLeft,
        heightFactor: 1.0,
        widthFactor: showSidebar ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOutCubic,
        child: ExcludeFocus(
          excluding: !showSidebar,
          child: IgnorePointer(
            ignoring: !showSidebar,
            child: SizedBox(
              width: 120,
              child: Container(
                width: 120,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHigh,
                  border: Border(
                    right: BorderSide(color: theme.colorScheme.outlineVariant),
                  ),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text('人物列表', style: theme.textTheme.labelLarge),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: characters.length,
                        itemBuilder: (context, index) {
                          final c = characters[index];
                          final placed = positions.containsKey(c.id);
                          final color = c.status == 1
                              ? Colors.grey
                              : theme.colorScheme.primary;
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            child: Draggable<int>(
                              data: c.id,
                              feedback: Material(
                                elevation: 8,
                                color: Colors.transparent,
                                child: buildCharacterAvatar(
                                  character: c,
                                  size: 48,
                                  color: color,
                                  isHighlighted: true,
                                ),
                              ),
                              childWhenDragging: Opacity(
                                opacity: 0.3,
                                child: RelationSidebarItem(
                                  character: c,
                                  placed: placed,
                                ),
                              ),
                              child: RelationSidebarItem(
                                character: c,
                                placed: placed,
                              ),
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
    );
  }
}
