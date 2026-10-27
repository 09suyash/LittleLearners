import 'package:flutter/material.dart';
import 'coloring_models.dart';

class ColoringToolBar extends StatelessWidget {
  final ColoringTool tool;
  final int brushSizeIdx;
  final bool canUndo;
  final void Function(ColoringTool) onSelectTool;
  final void Function(int) onSelectBrushSize;
  final VoidCallback onUndo;

  const ColoringToolBar({
    super.key,
    required this.tool,
    required this.brushSizeIdx,
    required this.canUndo,
    required this.onSelectTool,
    required this.onSelectBrushSize,
    required this.onUndo,
  });

  Widget _toolBtn(IconData icon, String label, ColoringTool t) {
    final sel = tool == t;
    return GestureDetector(
      onTap: () => onSelectTool(t),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: sel ? const Color(0xFFFFD93D) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: sel ? const Color(0xFF1a0533) : Colors.white60,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: sel ? const Color(0xFF1a0533) : Colors.white60,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _brushSizeDot(int idx) {
    final sel = brushSizeIdx == idx;
    final dotSize = 8.0 + idx * 5.0;
    return GestureDetector(
      onTap: () => onSelectBrushSize(idx),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: sel ? Colors.white.withAlpha(30) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: sel
              ? Border.all(color: const Color(0xFFFFD93D), width: 1.5)
              : null,
        ),
        child: Center(
          child: Container(
            width: dotSize,
            height: dotSize,
            decoration: BoxDecoration(
              color: sel ? Colors.white : Colors.white54,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(14),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withAlpha(24)),
        ),
        child: Row(
          children: [
            Flexible(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _toolBtn(Icons.brush_rounded, 'Brush', ColoringTool.brush),
                    const SizedBox(width: 6),
                    _toolBtn(
                      Icons.format_color_fill_rounded,
                      'Fill',
                      ColoringTool.fill,
                    ),
                    const SizedBox(width: 6),
                    _toolBtn(
                      Icons.auto_fix_high_rounded,
                      'Eraser',
                      ColoringTool.eraser,
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 1,
                      height: 28,
                      color: Colors.white.withAlpha(30),
                    ),
                    const SizedBox(width: 10),
                    if (tool != ColoringTool.fill) ...[
                      for (int i = 0; i < coloringBrushSizes.length; i++) ...[
                        _brushSizeDot(i),
                        if (i < coloringBrushSizes.length - 1)
                          const SizedBox(width: 6),
                      ],
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: onUndo,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: canUndo
                      ? Colors.white.withAlpha(22)
                      : Colors.white.withAlpha(8),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.undo_rounded,
                      size: 16,
                      color: canUndo ? Colors.white70 : Colors.white24,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Undo',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: canUndo ? Colors.white70 : Colors.white24,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ColoringPaletteBar extends StatelessWidget {
  final Color selectedColor;
  final void Function(Color) onSelectColor;

  const ColoringPaletteBar({
    super.key,
    required this.selectedColor,
    required this.onSelectColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        separatorBuilder: (_, i) => const SizedBox(width: 8),
        itemCount: coloringPalette.length,
        itemBuilder: (_, i) {
          final color = coloringPalette[i];
          final sel = color.toARGB32() == selectedColor.toARGB32();
          return GestureDetector(
            onTap: () => onSelectColor(color),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: sel ? 46 : 36,
              height: sel ? 46 : 36,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: sel ? Colors.white : Colors.white.withAlpha(80),
                  width: sel ? 3 : 1.5,
                ),
                boxShadow: sel
                    ? [
                        BoxShadow(
                          color: color.withAlpha(130),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: color.toARGB32() == Colors.white.toARGB32()
                  ? const Center(
                      child: Text('🗑', style: TextStyle(fontSize: 14)),
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }
}
