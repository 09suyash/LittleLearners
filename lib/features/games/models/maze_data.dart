import 'dart:collection';
import 'dart:math';

enum CellType { wall, path, start, goal, star }

class MazeData {
  final int id;
  final int size;
  final List<List<CellType>> grid;
  final int moveTarget;
  const MazeData({required this.id, required this.size, required this.grid, required this.moveTarget});
}

List<List<CellType>> _parse(List<String> rows) {
  return rows
      .map((r) => r.split('').map((ch) {
            switch (ch) {
              case '#': return CellType.wall;
              case 'S': return CellType.start;
              case 'G': return CellType.goal;
              case '*': return CellType.star;
              default: return CellType.path;
            }
          }).toList())
      .toList();
}

// Grids are hand-authored perfect mazes (exactly one route between any two
// cells), verified reachable start→goal and star→goal via BFS.
final List<MazeData> mazes = [
  MazeData(id: 1, size: 5, moveTarget: 12, grid: _parse([
    "S#...",
    ".###.",
    ".#...",
    ".#.#.",
    "...#G",
  ])),
  MazeData(id: 2, size: 5, moveTarget: 12, grid: _parse([
    "S....",
    "####.",
    ".#...",
    ".#.##",
    "....G",
  ])),
  MazeData(id: 3, size: 7, moveTarget: 20, grid: _parse([
    "S..#...",
    "##.#.#.",
    "...#*#.",
    ".#####.",
    ".#*....",
    ".###.#.",
    ".....#G",
  ])),
  MazeData(id: 4, size: 7, moveTarget: 24, grid: _parse([
    "S....#*",
    "####.#.",
    "*#...#.",
    ".#.###.",
    "...#...",
    ".###.#.",
    ".....#G",
  ])),
  MazeData(id: 5, size: 9, moveTarget: 16, grid: _parse([
    "S#......*",
    ".#.###.##",
    ".#..*#...",
    ".#####.#.",
    ".....#*#.",
    "####.###.",
    "...#.....",
    ".#.#####.",
    ".#......G",
  ])),
  MazeData(id: 6, size: 9, moveTarget: 40, grid: _parse([
    "S....#...",
    "####.#.#.",
    "*#...#.#.",
    ".#.###.#.",
    "...#*..#.",
    ".#####.#.",
    "...#...#.",
    "##.#.###.",
    "*....#..G",
  ])),
];

// ── Endless mode ─────────────────────────────────────────────────────────
// Procedurally generated mazes for levels beyond the 6 curated ones, using a
// recursive-backtracker (perfect maze) algorithm — guarantees exactly one
// route between any two cells, so start→goal and every star are always
// reachable. Deterministic per level (same seed → same maze).
MazeData generateMaze(int level) {
  final cellsN = (3 + (level - 1) ~/ 2).clamp(3, 6);
  final size = cellsN * 2 - 1;
  final rng = Random(4200 + level);
  final grid = List.generate(size, (_) => List.filled(size, CellType.wall));
  final visited = List.generate(cellsN, (_) => List.filled(cellsN, false));

  (int, int) toGrid(int r, int c) => (2 * r, 2 * c);

  final stack = <(int, int)>[(0, 0)];
  visited[0][0] = true;
  final startCell = toGrid(0, 0);
  grid[startCell.$1][startCell.$2] = CellType.path;

  while (stack.isNotEmpty) {
    final (cr, cc) = stack.last;
    final neighbors = <(int, int, int, int)>[];
    for (final (dr, dc) in const [(-1, 0), (1, 0), (0, -1), (0, 1)]) {
      final nr = cr + dr, nc = cc + dc;
      if (nr >= 0 && nr < cellsN && nc >= 0 && nc < cellsN && !visited[nr][nc]) {
        neighbors.add((nr, nc, dr, dc));
      }
    }
    if (neighbors.isNotEmpty) {
      final (nr, nc, dr, dc) = neighbors[rng.nextInt(neighbors.length)];
      final (wr, wc) = toGrid(cr, cc);
      grid[wr + dr][wc + dc] = CellType.path;
      final (gr2, gc2) = toGrid(nr, nc);
      grid[gr2][gc2] = CellType.path;
      visited[nr][nc] = true;
      stack.add((nr, nc));
    } else {
      stack.removeLast();
    }
  }

  const start = (0, 0);
  final goal = (size - 1, size - 1);
  final dist = _bfsDist(grid, size, start);
  // Cells reachable WITHOUT passing through goal — a star must be reachable
  // here, otherwise the only way in is through goal, which ends the round
  // before the star can be collected.
  final distNoGoal = _bfsDist(grid, size, start, avoid: goal);

  int openNeighbors(int r, int c) {
    int n = 0;
    for (final (dr, dc) in const [(-1, 0), (1, 0), (0, -1), (0, 1)]) {
      final nr = r + dr, nc = c + dc;
      if (nr >= 0 && nr < size && nc >= 0 && nc < size && grid[nr][nc] != CellType.wall) n++;
    }
    return n;
  }

  final deadEnds = <(int, int)>[];
  for (int r = 0; r < size; r++) {
    for (int c = 0; c < size; c++) {
      if (grid[r][c] == CellType.path && (r, c) != start && (r, c) != goal &&
          openNeighbors(r, c) == 1 && distNoGoal.containsKey((r, c))) {
        deadEnds.add((r, c));
      }
    }
  }
  deadEnds.sort((a, b) => dist[b]!.compareTo(dist[a]!));
  final starCount = (2 + level ~/ 3).clamp(2, 5);
  for (final s in deadEnds.take(starCount)) {
    grid[s.$1][s.$2] = CellType.star;
  }
  grid[start.$1][start.$2] = CellType.start;
  grid[goal.$1][goal.$2] = CellType.goal;

  return MazeData(id: 6 + level, size: size, grid: grid, moveTarget: dist[goal] ?? size * size);
}

Map<(int, int), int> _bfsDist(List<List<CellType>> grid, int size, (int, int) start, {(int, int)? avoid}) {
  final dist = <(int, int), int>{start: 0};
  final q = Queue<(int, int)>()..add(start);
  while (q.isNotEmpty) {
    final cur = q.removeFirst();
    for (final (dr, dc) in const [(-1, 0), (1, 0), (0, -1), (0, 1)]) {
      final nr = cur.$1 + dr, nc = cur.$2 + dc;
      if (nr >= 0 && nr < size && nc >= 0 && nc < size && grid[nr][nc] != CellType.wall && (nr, nc) != avoid) {
        final key = (nr, nc);
        if (!dist.containsKey(key)) {
          dist[key] = dist[cur]! + 1;
          q.add(key);
        }
      }
    }
  }
  return dist;
}
