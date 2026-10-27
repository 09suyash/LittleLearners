import 'package:flutter/material.dart';
import '../models/math_models.dart';

class MathSettingsView extends StatelessWidget {
  final MathMode mode;
  final MathOp op;
  final void Function(MathOp) onOpChanged;
  final Difficulty diff;
  final void Function(Difficulty) onDiffChanged;
  final int totalQ;
  final void Function(int) onTotalQChanged;
  final String missingMode;
  final void Function(String) onMissingModeChanged;
  final int table;
  final void Function(int) onTableChanged;
  final Difficulty blitzDiff;
  final void Function(Difficulty) onBlitzDiffChanged;
  final Set<MathOp> blitzOps;
  final void Function(MathOp) onToggleBlitzOp;
  final VoidCallback onBack;
  final VoidCallback onStart;

  const MathSettingsView({
    super.key,
    required this.mode,
    required this.op,
    required this.onOpChanged,
    required this.diff,
    required this.onDiffChanged,
    required this.totalQ,
    required this.onTotalQChanged,
    required this.missingMode,
    required this.onMissingModeChanged,
    required this.table,
    required this.onTableChanged,
    required this.blitzDiff,
    required this.onBlitzDiffChanged,
    required this.blitzOps,
    required this.onToggleBlitzOp,
    required this.onBack,
    required this.onStart,
  });

  Widget _settingsLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: Colors.white.withAlpha(115),
          letterSpacing: 0.7,
        ),
      ),
    );
  }

  Widget _optRow(
    List<String> labels,
    List<String> values,
    String selected,
    void Function(String) onSelect,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 0),
      child: Row(
        children: List.generate(
          labels.length,
          (i) => Expanded(
            child: GestureDetector(
              onTap: () => onSelect(values[i]),
              child: Container(
                margin: EdgeInsets.only(right: i < labels.length - 1 ? 7 : 0),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected == values[i]
                      ? const Color(0xFFFFD93D).withAlpha(33)
                      : Colors.white.withAlpha(13),
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(
                    color: selected == values[i]
                        ? const Color(0xFFFFD93D)
                        : Colors.white.withAlpha(26),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    labels[i],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: selected == values[i]
                          ? const Color(0xFFFFD93D)
                          : Colors.white60,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = mode == MathMode.practice
        ? '🎯 Practice Settings'
        : mode == MathMode.tables
            ? '📊 Times Tables'
            : '⚡ Blitz Settings';

    return Container(
      color: const Color(0xFF0d1b2a),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 490),
              decoration: BoxDecoration(
                color: const Color(0xFF16213e),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: Colors.white.withAlpha(18)),
              ),
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: onBack,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.arrow_back,
                          color: Colors.white70,
                          size: 24,
                        ),
                        const SizedBox(width: 7),
                        Text(
                          'Back to Modes',
                          style: TextStyle(
                            color: Colors.white.withAlpha(115),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Center(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (mode == MathMode.practice) ...[
                    _settingsLabel('Operation'),
                    _optRow(
                      ['➕ Add', '➖ Sub', '✖️ Mul'],
                      ['add', 'sub', 'mul'],
                      op == MathOp.add
                          ? 'add'
                          : op == MathOp.sub
                              ? 'sub'
                              : 'mul',
                      (v) => onOpChanged(
                        v == 'add'
                            ? MathOp.add
                            : v == 'sub'
                                ? MathOp.sub
                                : MathOp.mul,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _settingsLabel('Difficulty'),
                    _optRow(
                      ['😊 Easy', '😐 Medium', '😤 Hard'],
                      ['easy', 'med', 'hard'],
                      diff == Difficulty.easy
                          ? 'easy'
                          : diff == Difficulty.med
                              ? 'med'
                              : 'hard',
                      (v) => onDiffChanged(
                        v == 'easy'
                            ? Difficulty.easy
                            : v == 'med'
                                ? Difficulty.med
                                : Difficulty.hard,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _settingsLabel('Questions'),
                    _optRow(
                      ['5 Qs', '10 Qs', '15 Qs'],
                      ['5', '10', '15'],
                      totalQ.toString(),
                      (v) => onTotalQChanged(int.parse(v)),
                    ),
                    const SizedBox(height: 14),
                    _settingsLabel('Missing Number Mode'),
                    _optRow(
                      ['Off', 'On'],
                      ['no', 'yes'],
                      missingMode,
                      (v) => onMissingModeChanged(v),
                    ),
                  ],
                  if (mode == MathMode.tables) ...[
                    _settingsLabel('Choose Table to Practice'),
                    GridView.count(
                      crossAxisCount: 4,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 7,
                      mainAxisSpacing: 7,
                      childAspectRatio: 1.4,
                      children: List.generate(11, (i) {
                        final t = i + 2;
                        return GestureDetector(
                          onTap: () => onTableChanged(t),
                          child: Container(
                            decoration: BoxDecoration(
                              color: table == t
                                  ? const Color(0xFFFFD93D).withAlpha(38)
                                  : Colors.white.withAlpha(15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: table == t
                                    ? const Color(0xFFFFD93D)
                                    : Colors.white.withAlpha(26),
                                width: 1.5,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '$t×',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: table == t
                                      ? const Color(0xFFFFD93D)
                                      : Colors.white60,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                  if (mode == MathMode.blitz) ...[
                    _settingsLabel('Difficulty'),
                    _optRow(
                      ['😊 Easy', '😐 Medium', '😤 Hard'],
                      ['easy', 'med', 'hard'],
                      blitzDiff == Difficulty.easy
                          ? 'easy'
                          : blitzDiff == Difficulty.med
                              ? 'med'
                              : 'hard',
                      (v) => onBlitzDiffChanged(
                        v == 'easy'
                            ? Difficulty.easy
                            : v == 'med'
                                ? Difficulty.med
                                : Difficulty.hard,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _settingsLabel('Operations (tap to toggle)'),
                    Row(
                      children: [
                        for (final entry in [
                          (MathOp.add, '➕ Add'),
                          (MathOp.sub, '➖ Sub'),
                          (MathOp.mul, '✖️ Mul'),
                        ]) ...[
                          Expanded(
                            child: GestureDetector(
                              onTap: () => onToggleBlitzOp(entry.$1),
                              child: Container(
                                margin: EdgeInsets.only(
                                  right: entry.$1 != MathOp.mul ? 7 : 0,
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: blitzOps.contains(entry.$1)
                                      ? const Color(0xFFFFD93D).withAlpha(33)
                                      : Colors.white.withAlpha(13),
                                  borderRadius: BorderRadius.circular(11),
                                  border: Border.all(
                                    color: blitzOps.contains(entry.$1)
                                        ? const Color(0xFFFFD93D)
                                        : Colors.white.withAlpha(26),
                                    width: 1.5,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    entry.$2,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: blitzOps.contains(entry.$1)
                                          ? const Color(0xFFFFD93D)
                                          : Colors.white60,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                  const SizedBox(height: 6),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onStart,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: const Color(0xFFFF6B6B),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 6,
                      ),
                      child: const Text(
                        '🚀 Start!',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
