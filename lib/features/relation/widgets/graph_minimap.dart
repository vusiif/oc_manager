import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/design/design_tokens.dart';
import '../../../data/database/app_database.dart';

/// Floating interactive Mini-map for relationship graph navigation (GRAPH-005).
class GraphMinimap extends StatefulWidget {
  final Map<int, Offset> positions;
  final List<Character> characters;
  final List<Relation> relations;
  final TransformationController transformController;
  final Size viewportSize;
  final bool isDark;
  final ValueChanged<Offset> onNavigate;
  final double width;
  final double height;

  const GraphMinimap({
    super.key,
    required this.positions,
    required this.characters,
    required this.relations,
    required this.transformController,
    required this.viewportSize,
    required this.isDark,
    required this.onNavigate,
    this.width = 190.0,
    this.height = 130.0,
  });

  @override
  State<GraphMinimap> createState() => _GraphMinimapState();
}

class _GraphMinimapState extends State<GraphMinimap> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    if (!_isExpanded) {
      return Container(
        decoration: BoxDecoration(
          color: widget.isDark
              ? const Color(0xFF1E1E22).withValues(alpha: 0.9)
              : Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: widget.isDark ? Colors.white12 : Colors.black12,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: widget.isDark ? 0.3 : 0.08),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: IconButton(
          icon: const Icon(Icons.map_outlined, size: 20),
          tooltip: '展开导航小地图',
          onPressed: () => setState(() => _isExpanded = true),
        ),
      );
    }

    final theme = Theme.of(context);
    final bgColor = widget.isDark
        ? const Color(0xFF1E1E24).withValues(alpha: 0.92)
        : Colors.white.withValues(alpha: 0.95);
    final borderColor = widget.isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.1);

    return Container(
      width: widget.width,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: widget.isDark ? 0.4 : 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: widget.isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : Colors.black.withValues(alpha: 0.03),
              border: Border(bottom: BorderSide(color: borderColor)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.map_rounded,
                  size: 14,
                  color: widget.isDark ? Colors.white70 : Colors.black87,
                ),
                const SizedBox(width: 4),
                Text(
                  '全局导览',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
                const Spacer(),
                Text(
                  '${widget.positions.length} 节点',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: widget.isDark ? Colors.white38 : Colors.black45,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(width: 2),
                InkWell(
                  onTap: () => setState(() => _isExpanded = false),
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.all(2.0),
                    child: Icon(
                      Icons.close_fullscreen_rounded,
                      size: 13,
                      color: widget.isDark ? Colors.white54 : Colors.black54,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Mini-map Canvas
          SizedBox(
            width: widget.width,
            height: widget.height,
            child: widget.positions.isEmpty
                ? Center(
                    child: Text(
                      '暂无节点',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: widget.isDark ? Colors.white38 : Colors.black38,
                        fontSize: 11,
                      ),
                    ),
                  )
                : _MinimapInteractiveBody(
                    positions: widget.positions,
                    characters: widget.characters,
                    relations: widget.relations,
                    transformController: widget.transformController,
                    viewportSize: widget.viewportSize,
                    isDark: widget.isDark,
                    onNavigate: widget.onNavigate,
                    width: widget.width,
                    height: widget.height,
                  ),
          ),
        ],
      ),
    );
  }
}

class _MinimapInteractiveBody extends StatelessWidget {
  final Map<int, Offset> positions;
  final List<Character> characters;
  final List<Relation> relations;
  final TransformationController transformController;
  final Size viewportSize;
  final bool isDark;
  final ValueChanged<Offset> onNavigate;
  final double width;
  final double height;

  const _MinimapInteractiveBody({
    required this.positions,
    required this.characters,
    required this.relations,
    required this.transformController,
    required this.viewportSize,
    required this.isDark,
    required this.onNavigate,
    required this.width,
    required this.height,
  });

  Rect _calculateBounds() {
    double minX = double.infinity, minY = double.infinity;
    double maxX = -double.infinity, maxY = -double.infinity;

    for (final pos in positions.values) {
      minX = min(minX, pos.dx);
      minY = min(minY, pos.dy);
      maxX = max(maxX, pos.dx);
      maxY = max(maxY, pos.dy);
    }

    const padding = 150.0;
    return Rect.fromLTRB(
      minX - padding,
      minY - padding,
      maxX + padding,
      maxY + padding,
    );
  }

  void _handleInteraction(Offset localPos) {
    final bounds = _calculateBounds();
    final scaleX = width / max(bounds.width, 1.0);
    final scaleY = height / max(bounds.height, 1.0);
    final s = min(scaleX, scaleY);

    final offsetX = (width - bounds.width * s) / 2 - bounds.left * s;
    final offsetY = (height - bounds.height * s) / 2 - bounds.top * s;

    final targetWorldX = (localPos.dx - offsetX) / s;
    final targetWorldY = (localPos.dy - offsetY) / s;

    onNavigate(Offset(targetWorldX, targetWorldY));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (details) => _handleInteraction(details.localPosition),
      onPanUpdate: (details) => _handleInteraction(details.localPosition),
      child: ListenableBuilder(
        listenable: transformController,
        builder: (context, _) {
          return CustomPaint(
            size: Size(width, height),
            painter: _MinimapPainter(
              positions: positions,
              characters: characters,
              relations: relations,
              transformMatrix: transformController.value,
              viewportSize: viewportSize,
              isDark: isDark,
              bounds: _calculateBounds(),
            ),
          );
        },
      ),
    );
  }
}

class _MinimapPainter extends CustomPainter {
  final Map<int, Offset> positions;
  final List<Character> characters;
  final List<Relation> relations;
  final Matrix4 transformMatrix;
  final Size viewportSize;
  final bool isDark;
  final Rect bounds;

  _MinimapPainter({
    required this.positions,
    required this.characters,
    required this.relations,
    required this.transformMatrix,
    required this.viewportSize,
    required this.isDark,
    required this.bounds,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (positions.isEmpty) return;

    final scaleX = size.width / max(bounds.width, 1.0);
    final scaleY = size.height / max(bounds.height, 1.0);
    final s = min(scaleX, scaleY);

    final offsetX = (size.width - bounds.width * s) / 2 - bounds.left * s;
    final offsetY = (size.height - bounds.height * s) / 2 - bounds.top * s;

    Offset toMinimap(Offset world) {
      return Offset(world.dx * s + offsetX, world.dy * s + offsetY);
    }

    // 1. Draw Relations
    final linePaint = Paint()
      ..color = isDark ? Colors.white24 : Colors.black12
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    for (final rel in relations) {
      final from = positions[rel.fromCharacterId];
      final to = positions[rel.toCharacterId];
      if (from != null && to != null) {
        canvas.drawLine(toMinimap(from), toMinimap(to), linePaint);
      }
    }

    // 2. Draw Nodes
    final nodePaint = Paint()..style = PaintingStyle.fill;
    final deadPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.grey;

    final charMap = {for (final c in characters) c.id: c};
    for (final entry in positions.entries) {
      final cid = entry.key;
      final worldPos = entry.value;
      final mPos = toMinimap(worldPos);
      final character = charMap[cid];
      final isDead = character?.status == 1;

      if (isDead) {
        canvas.drawCircle(mPos, 2.8, deadPaint);
      } else {
        nodePaint.color = AppColors.brand;
        canvas.drawCircle(mPos, 3.2, nodePaint);
      }
    }

    // 3. Draw Viewport Box (what is visible on screen)
    try {
      final inverse = Matrix4.inverted(transformMatrix);
      final tlScreen = Offset.zero;
      final brScreen = Offset(viewportSize.width, viewportSize.height);

      final tlWorld = MatrixUtils.transformPoint(inverse, tlScreen);
      final brWorld = MatrixUtils.transformPoint(inverse, brScreen);

      final tlM = toMinimap(tlWorld);
      final brM = toMinimap(brWorld);

      final viewportRect = Rect.fromPoints(tlM, brM);

      final boxFillPaint = Paint()
        ..color = AppColors.brand.withValues(alpha: 0.18)
        ..style = PaintingStyle.fill;
      final boxStrokePaint = Paint()
        ..color = AppColors.brand.withValues(alpha: 0.75)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;

      canvas.drawRRect(
        RRect.fromRectAndRadius(viewportRect, const Radius.circular(3)),
        boxFillPaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(viewportRect, const Radius.circular(3)),
        boxStrokePaint,
      );
    } catch (_) {
      // Silently guard against singular/uninvertible matrix
    }
  }

  @override
  bool shouldRepaint(covariant _MinimapPainter oldDelegate) {
    return oldDelegate.transformMatrix != transformMatrix ||
        oldDelegate.positions != positions ||
        oldDelegate.relations != relations ||
        oldDelegate.viewportSize != viewportSize;
  }
}
