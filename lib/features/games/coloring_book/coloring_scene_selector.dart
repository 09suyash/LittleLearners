import 'package:flutter/material.dart';
import 'coloring_models.dart';

class ColoringCurrentSceneBadge extends StatelessWidget {
  final ColoringScene scene;
  final VoidCallback onTap;

  const ColoringCurrentSceneBadge({
    super.key,
    required this.scene,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(18),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withAlpha(30)),
          ),
          child: Row(
            children: [
              Text(scene.emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Text(
                scene.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              if (scene.completed) ...[
                const SizedBox(width: 6),
                const Text('✅', style: TextStyle(fontSize: 12)),
              ],
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD93D),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.grid_view_rounded,
                      size: 14,
                      color: Color(0xFF1a0533),
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Choose Design',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1a0533),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ColoringSceneSelectorOverlay extends StatelessWidget {
  final List<ColoringScene> scenes;
  final int currentSceneIdx;
  final String filter;
  final void Function(String) onFilterChanged;
  final void Function(int) onSelectScene;
  final VoidCallback onClose;

  const ColoringSceneSelectorOverlay({
    super.key,
    required this.scenes,
    required this.currentSceneIdx,
    required this.filter,
    required this.onFilterChanged,
    required this.onSelectScene,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    List<int> filteredIndices() {
      switch (filter) {
        case 'todo':
          return [
            for (int i = 0; i < scenes.length; i++)
              if (!scenes[i].completed) i,
          ];
        case 'done':
          return [
            for (int i = 0; i < scenes.length; i++)
              if (scenes[i].completed) i,
          ];
        default:
          return List.generate(scenes.length, (i) => i);
      }
    }

    final indices = filteredIndices();

    return Container(
      color: const Color(0xFF1a0533).withAlpha(245),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
              child: Row(
                children: [
                  const Text('🎨', style: TextStyle(fontSize: 28)),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Choose a Design',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: onClose,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(20),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.close_rounded,
                          color: Colors.white70,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            // Filter chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                children: [
                  for (final (key, label) in [
                    ('all', 'All'),
                    ('todo', 'To Do'),
                    ('done', 'Done ✅'),
                  ]) ...[
                    GestureDetector(
                      onTap: () => onFilterChanged(key),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: filter == key
                              ? const Color(0xFFFFD93D)
                              : Colors.white.withAlpha(18),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: filter == key
                                ? const Color(0xFF1a0533)
                                : Colors.white70,
                          ),
                        ),
                      ),
                    ),
                    if (key != 'done') const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Grid
            Expanded(
              child: indices.isEmpty
                  ? Center(
                      child: Text(
                        filter == 'done'
                            ? 'No scenes completed yet — start coloring!'
                            : 'All scenes completed! 🎉',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white60,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                            childAspectRatio: 1.15,
                          ),
                      itemCount: indices.length,
                      itemBuilder: (_, i) => _sceneCard(indices[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sceneCard(int sceneIdx) {
    final scene = scenes[sceneIdx];
    final isCurrent = sceneIdx == currentSceneIdx;
    final grad = coloringCardGrads[sceneIdx % coloringCardGrads.length];

    return GestureDetector(
      onTap: () => onSelectScene(sceneIdx),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: grad,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isCurrent ? Colors.white : Colors.white.withAlpha(40),
            width: isCurrent ? 3 : 1.5,
          ),
          boxShadow: isCurrent
              ? [
                  BoxShadow(
                    color: grad[0].withAlpha(100),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Stack(
          children: [
            if (scene.completed)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(200),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('✅', style: TextStyle(fontSize: 14)),
                ),
              ),
            if (isCurrent)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(200),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'NOW',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1a0533),
                    ),
                  ),
                ),
              ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(scene.emoji, style: const TextStyle(fontSize: 48)),
                  const SizedBox(height: 8),
                  Text(
                    scene.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1a0533),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
