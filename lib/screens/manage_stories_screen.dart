import 'package:flutter/material.dart';
import '../models/story_data.dart';
import '../utils/story_repository.dart';

// ── Page-entry helper (temporary controllers for the form) ───────────────────

class _PE {
  final TextEditingController scene;
  final TextEditingController text;
  _PE({String sc = '', String tx = ''})
      : scene = TextEditingController(text: sc),
        text  = TextEditingController(text: tx);
  void dispose() { scene.dispose(); text.dispose(); }
}

// ── Manage-list screen ────────────────────────────────────────────────────────

class ManageStoriesScreen extends StatefulWidget {
  const ManageStoriesScreen({super.key});
  @override
  State<ManageStoriesScreen> createState() => _ManageStoriesScreenState();
}

class _ManageStoriesScreenState extends State<ManageStoriesScreen> {
  final _repo = StoryRepository();
  List<StoryData> _list = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final l = await _repo.getAll();
    if (mounted) setState(() { _list = l; _loading = false; });
  }

  Future<void> _openForm({StoryData? story}) async {
    await Navigator.push(context,
        MaterialPageRoute(builder: (_) => _FormScreen(story: story)));
    _load();
  }

  Future<void> _confirmDelete(StoryData s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16213e),
        title: Text('Delete "${s.en.title}"?',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        content: const Text('This story will be permanently removed.',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
          TextButton(onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete',
                  style: TextStyle(color: Color(0xFFFF6B6B), fontWeight: FontWeight.w800))),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await _repo.delete(s.id);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final builtin = _list.where((s) =>  _repo.isBuiltin(s.id)).toList();
    final custom  = _list.where((s) => !_repo.isBuiltin(s.id)).toList();

    return Material(
      type: MaterialType.transparency,
      child: Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF0d001f), Color(0xFF2d1b69), Color(0xFF0a1f3d)],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
      child: SafeArea(
        child: Column(children: [
          _header(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: Colors.white54))
                : ListView(
                    padding: const EdgeInsets.fromLTRB(14, 8, 14, 32),
                    children: [
                      _label('📚 BUILT-IN STORIES (${builtin.length})'),
                      ...builtin.map((s) => _tile(s, canEdit: false)),
                      const SizedBox(height: 20),
                      Row(children: [
                        Expanded(child: _label('✏️ MY STORIES (${custom.length})')),
                        GestureDetector(
                          onTap: () => _openForm(),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFD93D),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text('+ Add Story',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800,
                                    color: Color(0xFF0d1b2a))),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 8),
                      if (custom.isEmpty) _emptyState(),
                      ...custom.map((s) => _tile(s, canEdit: true)),
                    ],
                  ),
          ),
        ]),
      ),
    ),  // Container
    );  // Material
  }

  Widget _header() => Padding(
    padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
    child: Row(children: [
      GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(18),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Text('←', style: TextStyle(color: Colors.white70, fontSize: 18)),
        ),
      ),
      const SizedBox(width: 12),
      const Text('📖', style: TextStyle(fontSize: 20)),
      const SizedBox(width: 8),
      const Expanded(
        child: Text('Manage Stories',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Colors.white)),
      ),
    ]),
  );

  Widget _label(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(t,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
            color: Colors.white.withAlpha(130), letterSpacing: 0.8)),
  );

  Widget _tile(StoryData s, {required bool canEdit}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withAlpha(26)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
            color: s.color.withAlpha(50),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(child: FittedBox(fit: BoxFit.scaleDown, child: Text(s.icon, style: const TextStyle(fontSize: 22)))),
        ),
        title: Text(s.en.title,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
            maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text('${s.en.pages.length} pages  •  ${s.en.tag}',
            style: TextStyle(fontSize: 11, color: Colors.white.withAlpha(100)),
            maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: canEdit
            ? Row(mainAxisSize: MainAxisSize.min, children: [
                _iconBtn(Icons.edit_outlined, () => _openForm(story: s)),
                const SizedBox(width: 4),
                _iconBtn(Icons.delete_outline, () => _confirmDelete(s),
                    color: const Color(0xFFFF6B6B)),
              ])
            : Icon(Icons.lock_outline, size: 14, color: Colors.white.withAlpha(50)),
        onTap: canEdit ? () => _openForm(story: s) : null,
      ),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap, {Color? color}) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(14),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 16, color: color ?? Colors.white.withAlpha(160)),
    ),
  );

  Widget _emptyState() => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Colors.white.withAlpha(8),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Colors.white.withAlpha(20)),
    ),
    child: Center(child: Column(children: [
      const Text('📖', style: TextStyle(fontSize: 36)),
      const SizedBox(height: 10),
      Text('No custom stories yet.\nTap "Add Story" to create your first one.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: Colors.white.withAlpha(120), height: 1.5)),
    ])),
  );
}

// ── Add / Edit form ───────────────────────────────────────────────────────────

class _FormScreen extends StatefulWidget {
  final StoryData? story;
  const _FormScreen({this.story});
  @override
  State<_FormScreen> createState() => _FormScreenState();
}

class _FormScreenState extends State<_FormScreen> {
  final _repo = StoryRepository();
  bool _saving = false;
  String? _error;

  late final TextEditingController _iconCtrl;
  Color _color = const Color(0xFF4CAF50);
  late final TextEditingController _enTitle;
  late final TextEditingController _enTag;
  late final TextEditingController _enMoral;
  late List<_PE> _enPages;

  bool _hasHindi = false;
  late final TextEditingController _hiTitle;
  late final TextEditingController _hiTag;
  late final TextEditingController _hiMoral;
  late List<_PE> _hiPages;

  static const _palette = [
    Color(0xFFc4855a), Color(0xFF4CAF50), Color(0xFF9C27B0), Color(0xFF2196F3),
    Color(0xFFFF9800), Color(0xFFF44336), Color(0xFF607D8B), Color(0xFFE6B800),
    Color(0xFF009688), Color(0xFFE91E63), Color(0xFF3F51B5), Color(0xFF00BCD4),
  ];

  @override
  void initState() {
    super.initState();
    final s = widget.story;
    _iconCtrl = TextEditingController(text: s?.icon ?? '📖');
    _color    = s?.color ?? const Color(0xFF4CAF50);
    _enTitle  = TextEditingController(text: s?.en.title ?? '');
    _enTag    = TextEditingController(text: s?.en.tag ?? '');
    _enMoral  = TextEditingController(text: s?.en.moral ?? '');
    _enPages  = s != null && s.en.pages.isNotEmpty
        ? s.en.pages.map((pg) => _PE(sc: pg.scene, tx: pg.text)).toList()
        : [_PE()];
    final hasHi = s != null && s.hi.title.isNotEmpty && s.hi.title != s.en.title;
    _hasHindi = hasHi;
    _hiTitle  = TextEditingController(text: hasHi ? s.hi.title : '');
    _hiTag    = TextEditingController(text: hasHi ? s.hi.tag : '');
    _hiMoral  = TextEditingController(text: hasHi ? s.hi.moral : '');
    _hiPages  = hasHi && s.hi.pages.isNotEmpty
        ? s.hi.pages.map((pg) => _PE(sc: pg.scene, tx: pg.text)).toList()
        : [_PE()];
  }

  @override
  void dispose() {
    _iconCtrl.dispose();
    _enTitle.dispose(); _enTag.dispose(); _enMoral.dispose();
    for (final e in _enPages) { e.dispose(); }
    _hiTitle.dispose(); _hiTag.dispose(); _hiMoral.dispose();
    for (final e in _hiPages) { e.dispose(); }
    super.dispose();
  }

  Future<void> _save() async {
    final title = _enTitle.text.trim();
    if (title.isEmpty) {
      setState(() => _error = 'Story title is required.');
      return;
    }
    final enPages = _enPages
        .where((e) => e.text.text.trim().isNotEmpty)
        .map((e) => StoryPage(scene: e.scene.text.trim(), text: e.text.text.trim()))
        .toList();
    if (enPages.isEmpty) {
      setState(() => _error = 'Add at least one page with story text.');
      return;
    }
    setState(() { _saving = true; _error = null; });

    final hiPages = _hasHindi
        ? _hiPages
            .where((e) => e.text.text.trim().isNotEmpty)
            .map((e) => StoryPage(scene: e.scene.text.trim(), text: e.text.text.trim()))
            .toList()
        : <StoryPage>[];

    final story = StoryData(
      id: widget.story?.id ?? -1,
      icon: _iconCtrl.text.trim().isNotEmpty ? _iconCtrl.text.trim() : '📖',
      color: _color,
      en: StoryVersion(
        title: title,
        tag: _enTag.text.trim(),
        pages: enPages,
        moral: _enMoral.text.trim(),
      ),
      hi: StoryVersion(
        title: _hasHindi ? _hiTitle.text.trim() : '',
        tag: _hasHindi ? _hiTag.text.trim() : '',
        pages: hiPages,
        moral: _hasHindi ? _hiMoral.text.trim() : '',
      ),
    );

    try {
      if (widget.story == null) {
        await _repo.add(story);
      } else {
        await _repo.update(story);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() { _saving = false; _error = 'Save failed: $e'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF0d001f), Color(0xFF2d1b69), Color(0xFF0a1f3d)],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
      child: SafeArea(
        child: Column(children: [
          _header(),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B6B).withAlpha(30),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFF6B6B).withAlpha(80)),
                ),
                child: Text(_error!,
                    style: const TextStyle(color: Color(0xFFFF6B6B), fontSize: 12)),
              ),
            ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 40),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _iconColorRow(),
                const SizedBox(height: 20),
                _sectionTitle('📖 English Version'),
                _fieldBlock('Story Title *', _enTitle),
                const SizedBox(height: 10),
                _fieldBlock('Subtitle / Lesson tag (optional)', _enTag),
                const SizedBox(height: 16),
                _pagesSection(_enPages,
                    onAdd: () => setState(() => _enPages.add(_PE())),
                    onRemove: (i) => setState(() { _enPages[i].dispose(); _enPages.removeAt(i); })),
                const SizedBox(height: 16),
                _fieldBlock('Closing moral (optional)', _enMoral, lines: 3),
                const SizedBox(height: 24),
                _hindiToggle(),
                if (_hasHindi) ...[
                  const SizedBox(height: 20),
                  _sectionTitle('🇮🇳 Hindi Version'),
                  _fieldBlock('Hindi Title', _hiTitle),
                  const SizedBox(height: 10),
                  _fieldBlock('Hindi Subtitle (optional)', _hiTag),
                  const SizedBox(height: 16),
                  _pagesSection(_hiPages,
                      onAdd: () => setState(() => _hiPages.add(_PE())),
                      onRemove: (i) => setState(() { _hiPages[i].dispose(); _hiPages.removeAt(i); })),
                  const SizedBox(height: 16),
                  _fieldBlock('Hindi Moral (optional)', _hiMoral, lines: 3),
                ],
              ]),
            ),
          ),
        ]),
      ),
    ),  // Container
    );  // Material
  }

  Widget _header() => Padding(
    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
    child: Row(children: [
      GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(18),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Text('←', style: TextStyle(color: Colors.white70, fontSize: 18)),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Text(widget.story == null ? 'Add Story' : 'Edit Story',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Colors.white)),
      ),
      GestureDetector(
        onTap: _saving ? null : _save,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
          decoration: BoxDecoration(
            color: _saving ? Colors.white.withAlpha(20) : const Color(0xFFFFD93D),
            borderRadius: BorderRadius.circular(12),
          ),
          child: _saving
              ? const SizedBox(width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Save',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800,
                      color: Color(0xFF0d1b2a))),
        ),
      ),
    ]),
  );

  Widget _iconColorRow() {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _fieldLabel('Icon'),
        Container(
          width: 68,
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(14),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withAlpha(36)),
          ),
          child: TextField(
            controller: _iconCtrl,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, color: Colors.white),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            ),
          ),
        ),
      ]),
      const SizedBox(width: 16),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _fieldLabel('Colour'),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: _palette.map((c) {
            final sel = c.toARGB32() == _color.toARGB32();
            return GestureDetector(
              onTap: () => setState(() => _color = c),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: sel ? 32 : 26,
                height: sel ? 32 : 26,
                decoration: BoxDecoration(
                  color: c,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: sel ? Colors.white : Colors.transparent,
                    width: 2.5,
                  ),
                  boxShadow: sel
                      ? [BoxShadow(color: c.withAlpha(120), blurRadius: 8)]
                      : null,
                ),
              ),
            );
          }).toList(),
        ),
      ])),
    ]);
  }

  Widget _sectionTitle(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(t,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white)),
  );

  Widget _fieldLabel(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(t,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
            color: Colors.white.withAlpha(160), letterSpacing: 0.3)),
  );

  Widget _fieldBlock(String label, TextEditingController ctrl, {int lines = 1}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _fieldLabel(label),
      Container(
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withAlpha(36)),
        ),
        child: TextField(
          controller: ctrl,
          maxLines: lines,
          style: const TextStyle(fontSize: 13, color: Colors.white, height: 1.4),
          decoration: const InputDecoration(
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          ),
        ),
      ),
    ]);
  }

  Widget _pagesSection(List<_PE> pages,
      {required VoidCallback onAdd, required void Function(int) onRemove}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text('PAGES (${pages.length})',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                color: Colors.white.withAlpha(160), letterSpacing: 0.8)),
        const Spacer(),
        GestureDetector(
          onTap: onAdd,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(18),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('+ Add Page',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                    color: Colors.white.withAlpha(180))),
          ),
        ),
      ]),
      const SizedBox(height: 8),
      ...pages.asMap().entries.map(
        (e) => _pageCard(e.key, e.value, canRemove: pages.length > 1,
            onRemove: () => onRemove(e.key)),
      ),
    ]);
  }

  Widget _pageCard(int idx, _PE entry,
      {required bool canRemove, required VoidCallback onRemove}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withAlpha(28)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(18),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text('Page ${idx + 1}',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                    color: Colors.white.withAlpha(160))),
          ),
          const Spacer(),
          if (canRemove)
            GestureDetector(
              onTap: onRemove,
              child: Icon(Icons.close, size: 16, color: Colors.white.withAlpha(100)),
            ),
        ]),
        const SizedBox(height: 10),
        _fieldLabel('Scene Emoji (optional)'),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(10),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withAlpha(26)),
          ),
          child: TextField(
            controller: entry.scene,
            style: const TextStyle(fontSize: 20, color: Colors.white),
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: '🌟🦁✨',
              hintStyle: TextStyle(color: Colors.white38),
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
          ),
        ),
        const SizedBox(height: 8),
        _fieldLabel('Story Text *'),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(10),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withAlpha(26)),
          ),
          child: TextField(
            controller: entry.text,
            maxLines: 4,
            style: const TextStyle(fontSize: 13, color: Colors.white, height: 1.5),
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: 'Write the story text for this page...',
              hintStyle: TextStyle(color: Colors.white38, fontSize: 12),
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _hindiToggle() {
    return GestureDetector(
      onTap: () {
        if (!_hasHindi) {
          // Pre-fill Hindi page count to match English
          for (final e in _hiPages) { e.dispose(); }
          _hiPages = List.generate(_enPages.length, (_) => _PE());
        }
        setState(() => _hasHindi = !_hasHindi);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _hasHindi
              ? const Color(0xFF0d3b6e).withAlpha(80)
              : Colors.white.withAlpha(10),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _hasHindi
                ? const Color(0xFF74C0FC).withAlpha(80)
                : Colors.white.withAlpha(28),
          ),
        ),
        child: Row(children: [
          const Text('🇮🇳', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Add Hindi Version',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                    color: _hasHindi ? Colors.white : Colors.white.withAlpha(160))),
            Text('Shows when Hindi language is selected in Stories',
                style: TextStyle(fontSize: 11, color: Colors.white.withAlpha(100))),
          ])),
          // Toggle switch
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 40, height: 22,
            decoration: BoxDecoration(
              color: _hasHindi ? const Color(0xFF74C0FC) : Colors.white.withAlpha(30),
              borderRadius: BorderRadius.circular(11),
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 200),
              alignment: _hasHindi ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.all(3),
                width: 16, height: 16,
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
