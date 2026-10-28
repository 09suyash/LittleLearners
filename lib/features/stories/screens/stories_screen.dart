import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/story_data.dart';
import '../repositories/story_repository.dart';
import 'package:zoodles/core/core.dart';

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
  double _speed = 0.75;
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
    _loadPreferences();
    _loadStories();
    _loadDone();
    _tts.setPageCompletionHandler(_onSpeechDone);
    _tts.setProgressHandler((text, start, end, word) {
      // Adjust start by the current segment's offset in the full page text
      final fullStart = start + _tts.currentOffset;
      final idx = _words.indexWhere((w) => w.start <= fullStart && fullStart < w.end);
      if (idx >= 0 && mounted) setState(() => _highlightIdx = idx);
    });
  }

  void _onRepoChanged() => _loadStories();

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedSpeed = prefs.getDouble('story_speed');
      if (savedSpeed != null && mounted) {
        setState(() => _speed = savedSpeed);
      }
    } catch (_) {}
  }

  Future<void> _loadStories() async {
    try {
      final list = await _repo.getAll();
      if (mounted) setState(() { _stories = list; _storiesLoading = false; });
    } catch (_) {
      if (mounted) setState(() { _storiesLoading = false; });
    }
  }

  Future<void> _loadDone() async {
    final ids = await ProgressRepository().getCompletedStoryIds();
    if (!mounted) return;
    setState(() {
      for (final id in ids) {
        _done.add(int.tryParse(id) ?? -1);
      }
    });
  }

  Future<void> _saveDone() async {
    for (final id in _done) {
      if (id >= 0) await ProgressRepository().markStoryCompleted(id);
    }
  }

  @override
  void dispose() {
    _repo.removeListener(_onRepoChanged);
    _tts.stop();
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
    _tts.speakPage(text, lang: _lang, speed: _speed);
  }

  void _stopSpeech() {
    _tts.stop();
    if (mounted) {
      setState(() { _playing = false; _highlightIdx = -1; });
    }
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
    final hasAll = await ProgressRepository().hasExploredAllApps();
    if (hasAll && _done.isNotEmpty && mounted) {
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
    return PopScope(
      canPop: _openStory == null,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _openStory != null) {
          _stopSpeech();
          setState(() { _openStory = null; });
        }
      },
      child: _openStory == null ? _buildGrid() : _buildReader(),
    );
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
          colors: [Color(0xFF0f0c29), Color(0xFF1a1035), Color(0xFF0f0c29)],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
      child: Stack(children: [
        // Decorative blobs
        Positioned(top: -30, right: -30,
            child: Opacity(opacity: 0.12, child: Image.asset('assets/images/stories_card.png', width: 160, height: 160, fit: BoxFit.contain))),
        Positioned(bottom: 80, left: -10,
            child: Opacity(opacity: 0.05, child: const Text('🌟', style: TextStyle(fontSize: 100)))),
        Positioned(bottom: -10, right: -10,
            child: Opacity(opacity: 0.06, child: const Text('✨', style: TextStyle(fontSize: 90)))),
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
                        onTap: () { _tts.stop(); widget.onGoHome?.call(); },
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(color: Colors.white.withAlpha(18), borderRadius: BorderRadius.circular(10)),
                            child: const Center(child: Icon(Icons.arrow_back, color: Colors.white70, size: 24)),
                          ),
                          const SizedBox(width: 7),
                          const Text('Home', style: TextStyle(color: Colors.white60, fontSize: 13, fontWeight: FontWeight.w700)),
                        ]),
                      ),
                    ),
                  if (widget.onGoHome != null) const SizedBox(height: 12),
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    Image.asset('assets/images/stories_card.png', width: 36, height: 36, fit: BoxFit.contain),
                    const SizedBox(width: 8),
                    const Text('Moral Stories', style: TextStyle(fontFamily: 'serif', fontSize: 26, fontWeight: FontWeight.w700, color: Colors.white)),
                  ]),
                  const SizedBox(height: 4),
                  Text('${_stories.length} stories • Character voices • Hindi & English',
                      style: const TextStyle(color: Colors.white60, fontSize: 13)),
                  const SizedBox(height: 16),
                  // Language toggle
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(18),
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(color: Colors.white.withAlpha(25), width: 1.5),
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
                      color: Colors.white.withAlpha(14),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withAlpha(25)),
                    ),
                    child: const Row(children: [
                      Text('🔊 ', style: TextStyle(fontSize: 13)),
                      Expanded(child: Text('Tap any story → press ▶ to hear it read aloud. Word-by-word highlighting follows along.',
                          style: TextStyle(fontSize: 12, color: Colors.white60))),
                    ]),
                  ),
                  const SizedBox(height: 16),
                  // Search
                  TextField(
                    onChanged: (v) => setState(() => _searchQuery = v),
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                    decoration: InputDecoration(
                      hintText: '🔍 Search stories...',
                      hintStyle: const TextStyle(color: Colors.white60),
                      filled: true,
                      fillColor: Colors.white.withAlpha(18),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withAlpha(40))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withAlpha(40))),
                      focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide(color: Color(0xFFc4855a), width: 1.5)),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            // Story cards
            Expanded(
              child: filtered.isEmpty
                  ? Center(child: Text('No stories found matching "$_searchQuery"', style: const TextStyle(color: Colors.white60)))
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
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: active ? Colors.white : Colors.white60)),
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
          color: Colors.white.withAlpha(16),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withAlpha(30), width: 1.5),
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
                    color: Colors.white.withAlpha(18),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withAlpha(25), width: 1.5),
                  ),
                  child: Center(child: FittedBox(fit: BoxFit.scaleDown, child: Text(s.icon, style: const TextStyle(fontSize: 28)))),
                ),
                const SizedBox(width: 13),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(v.title,
                      style: const TextStyle(fontFamily: 'serif', fontSize: 14, color: Colors.white, fontWeight: FontWeight.w700),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 1),
                  Text(v.tag, style: const TextStyle(fontSize: 12, color: Colors.white60)),
                  const SizedBox(height: 5),
                  Wrap(spacing: 5, children: [
                    _badge('${v.pages.length} pages'),
                    _badge('🎭 Voices'),
                    if (isDone) _badge('✓ Done', done: true),
                  ]),
                ])),
                const Text('›', style: TextStyle(fontSize: 20, color: Colors.white54)),
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
        color: done ? const Color(0xFF2E7D32).withAlpha(50) : Colors.white.withAlpha(18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: done ? const Color(0xFF4CAF50).withAlpha(150) : Colors.white.withAlpha(25)),
      ),
      child: Text(text,
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: done ? const Color(0xFF4CAF50) : Colors.white60)),
    );
  }

  // ── Story Reader ──
  Widget _buildReader() {
    final s = _openStory!;
    final v = s.forLang(_lang);
    final total = v.pages.length;
    final isEnd = _page >= total;

    return Container(
      decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF0f0c29), Color(0xFF1a1035), Color(0xFF0f0c29)])),
      child: Stack(children: [
        Positioned(top: -30, right: -30,
            child: Opacity(opacity: 0.12, child: Image.asset('assets/images/stories_card.png', width: 160, height: 160, fit: BoxFit.contain))),
        Positioned(bottom: 80, left: -10,
            child: Opacity(opacity: 0.05, child: const Text('🌟', style: TextStyle(fontSize: 100)))),
        Positioned(bottom: -10, right: -10,
            child: Opacity(opacity: 0.06, child: const Text('✨', style: TextStyle(fontSize: 90)))),
        SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Back button
            GestureDetector(
              onTap: () { _stopSpeech(); setState(() { _openStory = null; }); },
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.arrow_back, color: Colors.white60, size: 24),
                  SizedBox(width: 6),
                  Text('Back to Stories', style: TextStyle(color: Colors.white60, fontSize: 13, fontWeight: FontWeight.w700)),
                ]),
              ),
            ),
            // Header
            Center(child: Column(children: [
              Text(_playing ? s.icon : s.icon,
                  style: TextStyle(fontSize: 48, shadows: _playing ? [const Shadow(color: Color(0xFF7B3F00), blurRadius: 8)] : null)),
              const SizedBox(height: 6),
              Text(v.title,
                  style: const TextStyle(fontFamily: 'serif', fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
              const SizedBox(height: 2),
              Text(
                isEnd ? (_lang == 'hi' ? 'कहानी पूरी हुई 🎉' : 'Story Complete! 🎉')
                    : '${_lang == 'hi' ? 'पृष्ठ' : 'Page'} ${_page + 1} ${_lang == 'hi' ? 'में से' : 'of'} $total',
                style: const TextStyle(color: Colors.white60, fontSize: 13),
              ),
            ])),
            const SizedBox(height: 14),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                value: isEnd ? 1.0 : (_page + 1) / total,
                minHeight: 8,
                backgroundColor: Colors.white.withAlpha(18),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFc4855a)),
              ),
            ),
            const SizedBox(height: 14),
            // Page card or moral/completion
            if (!isEnd) ...[
              Container(
                width: double.infinity,
                height: 270,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(14),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: Colors.white.withAlpha(25), width: 1.5),
                  boxShadow: [BoxShadow(color: Colors.black.withAlpha(40), blurRadius: 24)],
                ),
                alignment: Alignment.center,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(v.pages[_page].scene, style: const TextStyle(fontSize: 34)),
                      const SizedBox(height: 10),
                      _HighlightedText(
                        text: v.pages[_page].text,
                        words: _words,
                        highlightIdx: _highlightIdx,
                        isHindi: _lang == 'hi',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Audio controls
              Container(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(14),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white.withAlpha(25), width: 1.5),
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
                    Expanded(
                      child: GestureDetector(
                        onTap: _showVoicePicker,
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(_playing ? (_lang == 'hi' ? '🎙️ सुन रहे हैं…' : '🎙️ Narrating…') : (_lang == 'hi' ? '▶ सुनने के लिए दबाएँ' : '▶ Tap to listen'),
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  _tts.getActiveVoiceName(_lang) ?? (_lang == 'hi' ? 'हिंदी आवाज़' : 'Natural Voice'),
                                  style: const TextStyle(fontSize: 11, color: Colors.white70),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.tune_rounded, size: 12, color: Colors.white60),
                            ],
                          ),
                        ]),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 10),
                  // Voice picker button & calibrated speed buttons
                  Row(children: [
                    GestureDetector(
                      onTap: _showVoicePicker,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(16),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white.withAlpha(35), width: 1.0),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.record_voice_over_rounded, size: 12, color: Color(0xFFc4855a)),
                            const SizedBox(width: 4),
                            Text(
                              _lang == 'hi' ? 'आवाज़' : 'Voice',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(_lang == 'hi' ? 'गति:' : 'Speed:',
                        style: const TextStyle(fontSize: 11, color: Colors.white60)),
                    const SizedBox(width: 6),
                    _spdBtn('0.5×', 0.5),
                    const SizedBox(width: 4),
                    _spdBtn('0.75×', 0.75),
                    const SizedBox(width: 4),
                    _spdBtn('1×', 1.0),
                    const SizedBox(width: 4),
                    _spdBtn('1.25×', 1.25),
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
                    color: Colors.white.withAlpha(14),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: Colors.white.withAlpha(25), width: 1.5),
                  ),
                  child: Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Auto-advance pages', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                      Text('Go to next page when narration ends', style: const TextStyle(fontSize: 11, color: Colors.white60)),
                    ])),
                    Switch(
                      value: _autoAdvance,
                      onChanged: (v) => setState(() => _autoAdvance = v),
                      activeThumbColor: Colors.white,
                      activeTrackColor: const Color(0xFF6C63FF),
                      inactiveThumbColor: Colors.white60,
                      inactiveTrackColor: Colors.white.withAlpha(40),
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
                  color: Colors.white.withAlpha(14),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: Colors.white.withAlpha(25), width: 1.5),
                ),
                child: Column(children: [
                  const Text('🎉', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 7),
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(fontFamily: 'serif', fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white),
                      children: [
                        TextSpan(text: _lang == 'hi' ? 'बहुत बढ़िया! ' : 'Well done! '),
                        const TextSpan(text: '🎉', style: TextStyle(fontFamily: null)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(_lang == 'hi' ? 'आपने यह कहानी पूरी की!' : 'You finished this story!',
                      style: const TextStyle(color: Colors.white60, fontSize: 13)),
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
                    backgroundColor: Colors.white.withAlpha(18),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.white.withAlpha(10),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: Colors.white.withAlpha(30), width: 1.5)),
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
      ]),    // Stack
    );
  }

  Widget _spdBtn(String label, double spd) {
    final sel = (_speed - spd).abs() < 0.01;
    return GestureDetector(
      onTap: () async {
        setState(() => _speed = spd);
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setDouble('story_speed', spd);
        } catch (_) {}
        if (_playing) { _stopSpeech(); _startSpeech(); }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: sel ? const Color(0xFF7B3F00) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: sel ? const Color(0xFF7B3F00) : Colors.white.withAlpha(25), width: 1.5),
        ),
        child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: sel ? Colors.white : Colors.white60)),
      ),
    );
  }

  void _showVoicePicker() {
    final voices = _tts.getAvailableVoices(lang: _lang);
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E140F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final currentActive = _tts.getActiveVoice(_lang);
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _lang == 'hi' ? 'कहानी सुनाने की आवाज़' : 'Storytelling Voice',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white70),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    Text(
                      _lang == 'hi'
                          ? 'स्वाभाविक और स्पष्ट कहानी वाचन के लिए आवाज़ चुनें'
                          : 'Select a natural voice for warm storytelling',
                      style: const TextStyle(fontSize: 12, color: Colors.white60),
                    ),
                    const SizedBox(height: 14),
                    if (voices.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Center(
                          child: Text(
                            _lang == 'hi' ? 'सिस्टम डिफ़ॉल्ट आवाज़ सक्रिय है' : 'System default voice is active',
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ),
                      )
                    else
                      Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: voices.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (context, idx) {
                            final v = voices[idx];
                            final isSel = currentActive != null && currentActive['name'] == v['name'];
                            final label = TtsService.friendlyVoiceName(v);
                            return Container(
                              decoration: BoxDecoration(
                                color: isSel ? const Color(0xFF7B3F00).withAlpha(120) : Colors.white.withAlpha(12),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSel ? const Color(0xFFc4855a) : Colors.white.withAlpha(25),
                                  width: isSel ? 1.5 : 1.0,
                                ),
                              ),
                              child: ListTile(
                                dense: true,
                                title: Text(
                                  label,
                                  style: TextStyle(
                                    fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                                subtitle: Text(
                                  v['name'] ?? '',
                                  style: const TextStyle(fontSize: 10, color: Colors.white54),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.volume_up, color: Colors.white70, size: 20),
                                      tooltip: 'Preview',
                                      onPressed: () async {
                                        await _tts.setVoice(_lang, v);
                                        await _tts.speak(
                                          _lang == 'hi' ? 'नमस्ते! कहानी शुरू करें?' : 'Hello! Ready for a story?',
                                          lang: _lang,
                                        );
                                      },
                                    ),
                                    if (isSel)
                                      const Icon(Icons.check_circle, color: Color(0xFFc4855a), size: 20),
                                  ],
                                ),
                                onTap: () async {
                                  await _tts.setVoice(_lang, v);
                                  setModalState(() {});
                                  if (mounted) setState(() {});
                                  if (_playing) {
                                    _stopSpeech();
                                    _startSpeech();
                                  }
                                },
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
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
    final baseStyle = TextStyle(
      fontSize: isHindi ? 18 : 17,
      height: isHindi ? 2.0 : 1.85,
      color: Colors.white.withAlpha(240),
      letterSpacing: 0.2,
    );

    if (words.isEmpty || highlightIdx < 0) {
      return Text(
        text,
        textAlign: TextAlign.center,
        style: baseStyle,
      );
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
                color: const Color(0xFFFFD54F),
                fontWeight: FontWeight.w800,
                // Keep font size matching baseStyle so text doesn't shift or cause box jitter
                fontSize: isHindi ? 18 : 17,
                backgroundColor: const Color(0xFFc4855a).withAlpha(70),
              )
            : null,
      ));
      pos = w.end;
    }
    if (pos < text.length) spans.add(TextSpan(text: text.substring(pos)));

    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: baseStyle,
        children: spans,
      ),
    );
  }
}
