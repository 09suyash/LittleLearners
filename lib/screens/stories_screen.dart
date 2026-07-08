import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/story_data.dart';
import '../utils/tts_service.dart';
import '../utils/badge_service.dart';
import '../utils/fx.dart';
import '../utils/app_state.dart';
import '../utils/story_repository.dart';

class StoriesScreen extends StatefulWidget {
  final VoidCallback? onGoHome;
  const StoriesScreen({super.key, this.onGoHome});

  @override
  State<StoriesScreen> createState() => _StoriesScreenState();
}

class _StoriesScreenState extends State<StoriesScreen> {
  final TtsService _tts = TtsService();
  final BadgeService _bs = BadgeService();
  final _repo = StoryRepository();
  String _lang = 'en';
  String _searchQuery = '';
  StoryData? _openStory;
  int _page = 0;
  bool _playing = false;
  double _speed = 0.5;
  bool _autoAdvance = false;
  final Set<int> _done = {};
  List<StoryData> _stories = [];
  bool _storiesLoading = true;

  // Word highlight: list of words with their char positions
  List<_Word> _words = [];
  int _highlightIdx = -1;

  @override
  void initState() {
    super.initState();
    _repo.addListener(_onRepoChanged);
    _loadStories();
    _loadDone();
    _tts.setCompletionHandler(_onSpeechDone);
    _tts.setProgressHandler((text, start, end, word) {
      // Find word index matching char position
      final idx = _words.indexWhere((w) => w.start <= start && start < w.end);
      if (idx >= 0 && mounted) setState(() => _highlightIdx = idx);
    });
  }

  void _onRepoChanged() => _loadStories();

  Future<void> _loadStories() async {
    try {
      final list = await _repo.getAll();
      if (mounted) setState(() { _stories = list; _storiesLoading = false; });
    } catch (_) {
      if (mounted) setState(() { _storiesLoading = false; });
    }
  }

  Future<void> _loadDone() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final ids = prefs.getStringList('stories_done') ?? [];
    setState(() {
      for (final id in ids) {
        _done.add(int.tryParse(id) ?? -1);
      }
    });
  }

  Future<void> _saveDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('stories_done', _done.map((i) => '$i').toList());
  }

  @override
  void dispose() {
    _repo.removeListener(_onRepoChanged);
    _tts.dispose();
    super.dispose();
  }

  void _onSpeechDone() {
    if (!mounted) return;
    setState(() { _playing = false; _highlightIdx = -1; });
    if (_autoAdvance && _openStory != null) {
      final total = _openStory!.forLang(_lang).pages.length;
      if (_page < total) {
        Future.delayed(const Duration(milliseconds: 900), () {
          if (mounted) _goPage(1, autoPlay: true);
        });
      }
    }
  }

  void _buildWords(String text) {
    _words = [];
    for (final match in RegExp(r'\S+').allMatches(text)) {
      _words.add(_Word(text: match.group(0)!, start: match.start, end: match.end));
    }
  }

  void _startSpeech() {
    if (_openStory == null) return;
    final version = _openStory!.forLang(_lang);
    final isEnd = _page >= version.pages.length;
    if (isEnd) return;
    final text = version.pages[_page].text;
    _buildWords(text);
    setState(() { _playing = true; _highlightIdx = -1; });
    _tts.speak(text, lang: _lang, rate: _speed);
  }

  void _stopSpeech() {
    _tts.stop();
    setState(() { _playing = false; _highlightIdx = -1; });
  }

  Future<void> _goPage(int dir, {bool autoPlay = false}) async {
    if (_openStory == null) return;
    final total = _openStory!.forLang(_lang).pages.length;
    final next = _page + dir;
    if (next < 0 || next > total) return;
    final wasPlaying = _playing;
    _stopSpeech();
    setState(() { _page = next; });
    if (next < total && (autoPlay || (wasPlaying && _autoAdvance))) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _startSpeech();
      });
    }
    if (next >= total) {
      _done.add(_openStory!.id);
      _saveDone();
      await AppState.addStars(10);
      if (!mounted) return;
      await awardWithToast(context, _bs, 'story_first');
      if (_lang == 'hi' && mounted) await awardWithToast(context, _bs, 'story_hindi');
      if (_done.length >= 4 && mounted) await awardWithToast(context, _bs, 'story_half');
      if (_done.length >= _stories.length && mounted) await awardWithToast(context, _bs, 'story_all', stars: 50);
      _checkExplorerBadge();
    }
  }

  Future<void> _checkExplorerBadge() async {
    final p = await SharedPreferences.getInstance();
    final hasAbc  = (p.getInt('abc_learned') ?? 0) > 0;
    final hasMath = (p.getInt('math_best') ?? -1) >= 0;
    if (hasAbc && hasMath && _done.isNotEmpty && mounted) {
      await awardWithToast(context, _bs, 'all_apps', stars: 50);
    }
  }

  StoryData? _getNextStory() {
    if (_openStory == null || _stories.isEmpty) return null;
    final idx = _stories.indexOf(_openStory!);
    for (int i = 1; i <= _stories.length; i++) {
      final s = _stories[(idx + i) % _stories.length];
      if (!_done.contains(s.id)) return s;
    }
    return _stories[(idx + 1) % _stories.length];
  }

  List<StoryData> get _filteredStories {
    if (_searchQuery.isEmpty) return _stories;
    final q = _searchQuery.toLowerCase();
    return _stories.where((s) {
      final v = s.forLang(_lang);
      return v.title.toLowerCase().contains(q) || v.tag.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return _openStory == null ? _buildGrid() : _buildReader();
  }

  // ── Story Grid ──
  Widget _buildGrid() {
    if (_storiesLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFc4855a)));
    }
    final filtered = _filteredStories;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFfff4e6), Color(0xFFffe8cc), Color(0xFFfff8f2)],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
      child: Stack(children: [
        // Decorative blobs
        Positioned(top: -30, right: -30,
            child: Opacity(opacity: 0.07,
                child: const Text('📚', style: TextStyle(fontSize: 160)))),
        Positioned(top: 220, left: -25,
            child: Opacity(opacity: 0.05,
                child: const Text('⭐', style: TextStyle(fontSize: 110)))),
        Positioned(bottom: 120, right: -20,
            child: Opacity(opacity: 0.05,
                child: const Text('🌟', style: TextStyle(fontSize: 120)))),
        // Main content — Positioned.fill gives SafeArea tight constraints
        Positioned.fill(child: SafeArea(
          child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
              child: Column(
                children: [
                  if (widget.onGoHome != null)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
                        onTap: widget.onGoHome,
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(color: const Color(0xFFecdcc8), borderRadius: BorderRadius.circular(10)),
                            child: const Center(child: Icon(Icons.arrow_back, color: Color(0xFF7B3F00), size: 24)),
                          ),
                          const SizedBox(width: 7),
                          const Text('Home', style: TextStyle(color: Color(0xFFa08060), fontSize: 13, fontWeight: FontWeight.w700)),
                        ]),
                      ),
                    ),
                  if (widget.onGoHome != null) const SizedBox(height: 12),
                  RichText(
                    text: const TextSpan(children: [
                      TextSpan(text: '📚 ', style: TextStyle(fontSize: 26)),
                      TextSpan(text: 'Moral Stories', style: TextStyle(fontFamily: 'serif', fontSize: 26, fontWeight: FontWeight.w700, color: Color(0xFF7B3F00))),
                    ]),
                  ),
                  const SizedBox(height: 4),
                  Text('${_stories.length} stories • Hindi & English voice narration',
                      style: TextStyle(color: const Color(0xFFa08060).withAlpha(204), fontSize: 13)),
                  const SizedBox(height: 16),
                  // Language toggle
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFf0e6d3),
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(color: const Color(0xFFecdcc8), width: 1.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _langBtn('🇬🇧 English', 'en'),
                        const SizedBox(width: 4),
                        _langBtn('🇮🇳 हिंदी', 'hi'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Info note
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFc4855a).withAlpha(26),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFecdcc8)),
                    ),
                    child: const Row(children: [
                      Text('🔊 ', style: TextStyle(fontSize: 13)),
                      Expanded(child: Text('Tap any story → press ▶ to hear it read aloud. Word-by-word highlighting follows along.',
                          style: TextStyle(fontSize: 12, color: Color(0xFFa08060)))),
                    ]),
                  ),
                  const SizedBox(height: 16),
                  // Search
                  TextField(
                    onChanged: (v) => setState(() => _searchQuery = v),
                    style: const TextStyle(color: Color(0xFF3a2c1a), fontSize: 15),
                    decoration: InputDecoration(
                      hintText: '🔍 Search stories...',
                      hintStyle: const TextStyle(color: Color(0xFFa08060)),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFecdcc8))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFecdcc8))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF7B3F00))),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            // Story cards
            Expanded(
              child: filtered.isEmpty
                  ? Center(child: Text('No stories found matching "$_searchQuery"', style: const TextStyle(color: Color(0xFFa08060))))
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 24),
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 11),
                      itemBuilder: (_, i) => _storyCard(filtered[i]),
                    ),
            ),
          ],
        ))),  // Column, SafeArea, Positioned.fill
      ]),    // Stack children
    );       // Container
  }

  Widget _langBtn(String label, String value) {
    final active = _lang == value;
    return GestureDetector(
      onTap: () => setState(() => _lang = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 9),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF7B3F00) : Colors.transparent,
          borderRadius: BorderRadius.circular(50),
          boxShadow: active ? [const BoxShadow(color: Color(0x5A7B3F00), blurRadius: 12)] : null,
        ),
        child: Text(label,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: active ? Colors.white : const Color(0xFFa08060))),
      ),
    );
  }

  Widget _storyCard(StoryData s) {
    final v = s.forLang(_lang);
    final isDone = _done.contains(s.id);
    return GestureDetector(
      onTap: () {
        _stopSpeech();
        setState(() { _openStory = s; _page = 0; });
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFecdcc8), width: 2),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 8)],
        ),
        child: Stack(
          children: [
            Positioned(left: 0, top: 0, bottom: 0,
              child: Container(
                width: 4,
                decoration: BoxDecoration(
                  color: s.color,
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 15, 16, 15),
              child: Row(children: [
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFFf0e6d3),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFecdcc8), width: 1.5),
                  ),
                  child: Center(child: FittedBox(fit: BoxFit.scaleDown, child: Text(s.icon, style: const TextStyle(fontSize: 28)))),
                ),
                const SizedBox(width: 13),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(v.title,
                      style: const TextStyle(fontFamily: 'serif', fontSize: 14, color: Color(0xFF7B3F00), fontWeight: FontWeight.w700),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 1),
                  Text(v.tag, style: const TextStyle(fontSize: 12, color: Color(0xFFa08060))),
                  const SizedBox(height: 5),
                  Wrap(spacing: 5, children: [
                    _badge('${v.pages.length} pages'),
                    _badge('🔊 Voice'),
                    if (isDone) _badge('✓ Done', done: true),
                  ]),
                ])),
                const Text('›', style: TextStyle(fontSize: 20, color: Color(0xFFc4855a))),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(String text, {bool done = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: done ? const Color(0xFFe8f5e9) : const Color(0xFFf0e6d3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: done ? const Color(0xFFa5d6a7) : const Color(0xFFecdcc8)),
      ),
      child: Text(text,
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: done ? const Color(0xFF388E3C) : const Color(0xFFa08060))),
    );
  }

  // ── Story Reader ──
  Widget _buildReader() {
    final s = _openStory!;
    final v = s.forLang(_lang);
    final total = v.pages.length;
    final isEnd = _page >= total;

    return Container(
      color: const Color(0xFFfdf6ec),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Back button
            GestureDetector(
              onTap: () { _stopSpeech(); setState(() { _openStory = null; }); },
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.arrow_back, color: Color(0xFFa08060), size: 24),
                  SizedBox(width: 6),
                  Text('Back to Stories', style: TextStyle(color: Color(0xFFa08060), fontSize: 13, fontWeight: FontWeight.w700)),
                ]),
              ),
            ),
            // Header
            Center(child: Column(children: [
              Text(_playing ? s.icon : s.icon,
                  style: TextStyle(fontSize: 48, shadows: _playing ? [const Shadow(color: Color(0xFF7B3F00), blurRadius: 8)] : null)),
              const SizedBox(height: 6),
              Text(v.title,
                  style: const TextStyle(fontFamily: 'serif', fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF7B3F00))),
              const SizedBox(height: 2),
              Text(
                isEnd ? (_lang == 'hi' ? 'कहानी पूरी हुई 🎉' : 'Story Complete! 🎉')
                    : '${_lang == 'hi' ? 'पृष्ठ' : 'Page'} ${_page + 1} ${_lang == 'hi' ? 'में से' : 'of'} $total',
                style: const TextStyle(color: Color(0xFFa08060), fontSize: 13),
              ),
            ])),
            const SizedBox(height: 14),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                value: isEnd ? 1.0 : (_page + 1) / total,
                minHeight: 8,
                backgroundColor: const Color(0xFFf0e6d3),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFc4855a)),
              ),
            ),
            const SizedBox(height: 14),
            // Page card or moral/completion
            if (!isEnd) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFfff9f2),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFecdcc8), width: 1.5),
                  boxShadow: [BoxShadow(color: Colors.black.withAlpha(18), blurRadius: 24)],
                ),
                child: Column(children: [
                  Text(v.pages[_page].scene, style: const TextStyle(fontSize: 36)),
                  const SizedBox(height: 11),
                  _HighlightedText(text: v.pages[_page].text, words: _words, highlightIdx: _highlightIdx, isHindi: _lang == 'hi'),
                ]),
              ),
              const SizedBox(height: 12),
              // Audio controls
              Container(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFecdcc8), width: 1.5),
                  boxShadow: [BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 10)],
                ),
                child: Column(children: [
                  Row(children: [
                    GestureDetector(
                      onTap: _playing ? _stopSpeech : _startSpeech,
                      child: Container(
                        width: 46, height: 46,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: _playing ? [const Color(0xFFc0392b), const Color(0xFFe74c3c)] : [const Color(0xFF7B3F00), const Color(0xFFc4855a)],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: const Color(0x4C7B3F00), blurRadius: 14)],
                        ),
                        child: Center(child: Text(_playing ? '■' : '▶', style: const TextStyle(color: Colors.white, fontSize: 16))),
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(_playing ? (_lang == 'hi' ? '🎙️ सुन रहे हैं…' : '🎙️ Narrating…') : (_lang == 'hi' ? '▶ सुनने के लिए दबाएँ' : '▶ Tap to listen'),
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF3a2c1a))),
                      Text(_lang == 'hi' ? 'हिंदी आवाज़ उपलब्ध' : 'Hindi & English voice',
                          style: const TextStyle(fontSize: 11, color: Color(0xFFa08060))),
                    ])),
                  ]),
                  const SizedBox(height: 10),
                  // Speed buttons on their own row — prevents overflow on narrow screens
                  Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                    Text(_lang == 'hi' ? 'गति:' : 'Speed:',
                        style: const TextStyle(fontSize: 11, color: Color(0xFFa08060))),
                    const SizedBox(width: 6),
                    _spdBtn('0.5×', 0.5),
                    const SizedBox(width: 4),
                    _spdBtn('0.7×', 0.7),
                    const SizedBox(width: 4),
                    _spdBtn('1×', 1.0),
                    const SizedBox(width: 4),
                    _spdBtn('1.3×', 1.3),
                  ]),
                ]),
              ),
              const SizedBox(height: 12),
              // Auto-advance toggle
              GestureDetector(
                onTap: () => setState(() => _autoAdvance = !_autoAdvance),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: const Color(0xFFecdcc8), width: 1.5),
                  ),
                  child: Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Auto-advance pages', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF3a2c1a))),
                      Text('Go to next page when narration ends', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                    ])),
                    Switch(
                      value: _autoAdvance,
                      onChanged: (v) => setState(() => _autoAdvance = v),
                      activeThumbColor: const Color(0xFF7B3F00),
                      activeTrackColor: const Color(0xFF7B3F00),
                    ),
                  ]),
                ),
              ),
            ],
            if (isEnd) ...[
              // Moral card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: [Color(0xFF7B3F00), Color(0xFFc4855a)],
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [const BoxShadow(color: Color(0x527B3F00), blurRadius: 24)],
                ),
                child: Column(children: [
                  Text('✨ ${_lang == 'hi' ? 'कहानी की सीख' : 'Moral of the Story'}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1, color: Colors.white70)),
                  const SizedBox(height: 8),
                  const Text('🌿', style: TextStyle(fontSize: 28)),
                  const SizedBox(height: 8),
                  Text(v.moral,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: _lang == 'hi' ? 16 : 15, fontWeight: FontWeight.w600, color: Colors.white, height: _lang == 'hi' ? 1.9 : 1.75)),
                  const SizedBox(height: 14),
                  GestureDetector(
                    onTap: () => _tts.speak(v.moral, lang: _lang),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(51),
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(color: Colors.white.withAlpha(102), width: 1.5),
                      ),
                      child: Text(_lang == 'hi' ? '🔊 नीति सुनें' : '🔊 Read Moral Aloud',
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 12),
              // Completion card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFfff9f2),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFecdcc8), width: 2),
                ),
                child: Column(children: [
                  const Text('🎉', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 7),
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(fontFamily: 'serif', fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF7B3F00)),
                      children: [
                        TextSpan(text: _lang == 'hi' ? 'बहुत बढ़िया! ' : 'Well done! '),
                        const TextSpan(text: '🎉', style: TextStyle(fontFamily: null)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(_lang == 'hi' ? 'आपने यह कहानी पूरी की!' : 'You finished this story!',
                      style: const TextStyle(color: Color(0xFFa08060), fontSize: 13)),
                  const SizedBox(height: 12),
                  const Text('⭐⭐⭐', style: TextStyle(fontSize: 28, letterSpacing: 4)),
                ]),
              ),
            ],
            const SizedBox(height: 12),
            // Nav buttons
            Row(children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: isEnd
                      ? () { _stopSpeech(); setState(() { _openStory = null; }); }
                      : (_page > 0 ? () => _goPage(-1) : null),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFf0e6d3),
                    foregroundColor: const Color(0xFF7B3F00),
                    disabledBackgroundColor: const Color(0xFFf0e6d3).withAlpha(128),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: Color(0xFFecdcc8), width: 1.5)),
                    elevation: 0,
                  ),
                  child: Text(
                    isEnd ? (_lang == 'hi' ? '↩ सभी कहानियाँ' : '↩ All Stories') : '← Prev',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    if (isEnd) {
                      final next = _getNextStory();
                      if (next != null) { _stopSpeech(); setState(() { _openStory = next; _page = 0; }); }
                    } else {
                      _goPage(1);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7B3F00),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 4,
                  ),
                  child: Text(
                    isEnd ? (_lang == 'hi' ? 'अगली कहानी →' : 'Next Story →')
                        : _page == total - 1 ? (_lang == 'hi' ? 'नीति देखें →' : 'See Moral →')
                        : (_lang == 'hi' ? 'अगला →' : 'Next →'),
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _spdBtn(String label, double spd) {
    final sel = _speed == spd;
    return GestureDetector(
      onTap: () {
        setState(() => _speed = spd);
        if (_playing) { _stopSpeech(); _startSpeech(); }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: sel ? const Color(0xFF7B3F00) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: sel ? const Color(0xFF7B3F00) : const Color(0xFFecdcc8), width: 1.5),
        ),
        child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: sel ? Colors.white : const Color(0xFFa08060))),
      ),
    );
  }
}

// Word with character positions for highlighting
class _Word {
  final String text;
  final int start, end;
  const _Word({required this.text, required this.start, required this.end});
}

// Highlighted text widget
class _HighlightedText extends StatelessWidget {
  final String text;
  final List<_Word> words;
  final int highlightIdx;
  final bool isHindi;

  const _HighlightedText({
    required this.text,
    required this.words,
    required this.highlightIdx,
    required this.isHindi,
  });

  @override
  Widget build(BuildContext context) {
    if (words.isEmpty || highlightIdx < 0) {
      return Text(text,
          style: TextStyle(fontSize: isHindi ? 17 : 16, height: isHindi ? 2.15 : 1.9, color: const Color(0xFF3a2c1a)));
    }

    final spans = <InlineSpan>[];
    int pos = 0;
    for (int i = 0; i < words.length; i++) {
      final w = words[i];
      if (w.start > pos) {
        spans.add(TextSpan(text: text.substring(pos, w.start)));
      }
      final active = i == highlightIdx;
      spans.add(TextSpan(
        text: w.text,
        style: active
            ? TextStyle(
                color: const Color(0xFFc4855a),
                fontWeight: FontWeight.w900,
                fontSize: isHindi ? 21 : 20,
              )
            : null,
      ));
      pos = w.end;
    }
    if (pos < text.length) spans.add(TextSpan(text: text.substring(pos)));

    return RichText(
      text: TextSpan(
        style: TextStyle(fontSize: isHindi ? 17 : 16, height: isHindi ? 2.15 : 1.9, color: const Color(0xFF3a2c1a)),
        children: spans,
      ),
    );
  }
}
