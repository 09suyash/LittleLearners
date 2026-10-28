import 'dart:async';
import 'dart:collection';
import 'package:flutter/widgets.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _VoiceSegment {
  final String text;
  final bool isDialogue;
  const _VoiceSegment(this.text, this.isDialogue);
}

class _TtsRequest {
  final String text;
  final String lang;
  final double rate;
  final double pitch;
  final int charOffset;    // char offset of this segment in full page text
  final bool isPageFinal;  // true → fire page completion handler when done
  final int sessionToken;  // token matching TtsService session at creation time
  final Completer<void> completer = Completer();

  _TtsRequest({
    required this.text,
    required this.lang,
    required this.rate,
    required this.pitch,
    required this.sessionToken,
    this.charOffset = 0,
    this.isPageFinal = false,
  });
}

// Singleton — all screens share one TTS engine.
class TtsService with WidgetsBindingObserver {
  static final TtsService _instance = TtsService._();
  factory TtsService() => _instance;

  TtsService._() {
    WidgetsBinding.instance.addObserver(this);
  }

  final FlutterTts _tts = FlutterTts();
  Completer<void>? _initCompleter;
  final Queue<_TtsRequest> _queue = Queue();
  bool _isSpeaking = false;
  bool get isSpeaking => _isSpeaking;
  int _sessionToken = 0;

  List<Map<String, String>> _availableVoices = [];
  final Map<String, Map<String, String>> _selectedVoices = {};

  // Current char offset in the full page text — used by progress handler.
  int _currentOffset = 0;
  int get currentOffset => _currentOffset;

  // Called only when a full story page (all segments) finishes.
  VoidCallback? _pageCompletionHandler;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      stop();
    }
  }

  Future<void> _init() async {
    if (_initCompleter != null) return _initCompleter!.future;
    _initCompleter = Completer<void>();
    try {
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      await _tts.setSpeechRate(0.36);
      // Internal completion handler — keeps the queue moving.
      _tts.setCompletionHandler(() {
        _isSpeaking = false;
      });
      await _loadVoices();
      await _loadSavedVoices();
      _initCompleter!.complete();
    } catch (e) {
      _initCompleter!.completeError(e);
      _initCompleter = null;
    }
  }

  Future<void> _loadVoices() async {
    try {
      final dynamic raw = await _tts.getVoices;
      if (raw is List) {
        _availableVoices = raw.map((v) {
          if (v is Map) {
            return Map<String, String>.from(
              v.map((k, val) => MapEntry(k.toString(), val?.toString() ?? '')),
            );
          }
          return <String, String>{};
        }).where((m) => m.isNotEmpty && m.containsKey('name') && m.containsKey('locale')).toList();
      }
    } catch (e) {
      debugPrint('TtsService._loadVoices error: $e');
    }
  }

  Future<void> _loadSavedVoices() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final lang in ['en', 'hi']) {
        final savedName = prefs.getString('tts_voice_$lang');
        if (savedName != null && savedName.isNotEmpty) {
          final match = _availableVoices.firstWhere(
            (v) => v['name'] == savedName,
            orElse: () => {},
          );
          if (match.isNotEmpty) {
            _selectedVoices[lang] = match;
          }
        }
        _selectedVoices.putIfAbsent(lang, () => _selectBestVoice(lang) ?? {});
      }
    } catch (_) {}
  }

  Map<String, String>? _selectBestVoice(String lang) {
    final targetPrefix = (lang == 'hi') ? 'hi' : 'en';
    final matches = _availableVoices.where((v) {
      final loc = (v['locale'] ?? '').toLowerCase().replaceAll('_', '-');
      return loc.startsWith(targetPrefix);
    }).toList();

    if (matches.isEmpty) return null;

    matches.sort((a, b) {
      int score(Map<String, String> v) {
        int s = 0;
        final q = (v['quality'] ?? '').toLowerCase();
        if (q == 'very high') {
          s += 60;
        } else if (q == 'high') {
          s += 40;
        } else if (q == 'normal') {
          s += 15;
        }

        final name = (v['name'] ?? '').toLowerCase();
        if (name.contains('neural') || name.contains('wavenet') || name.contains('network')) {
          s += 35;
        }
        if (name.contains('sfg') || name.contains('iom') || name.contains('iol') || name.contains('hie')) {
          s += 25;
        }
        if (name.contains('female')) s += 15;

        if (name.contains('pico') || name.contains('synthetic') || q == 'low' || q == 'very low') {
          s -= 50;
        }
        return s;
      }
      return score(b).compareTo(score(a));
    });

    return matches.first;
  }

  List<Map<String, String>> getAvailableVoices({String? lang}) {
    if (lang == null) return List.unmodifiable(_availableVoices);
    final prefix = lang == 'hi' ? 'hi' : 'en';
    return _availableVoices.where((v) {
      final loc = (v['locale'] ?? '').toLowerCase().replaceAll('_', '-');
      return loc.startsWith(prefix);
    }).toList();
  }

  Map<String, String>? getActiveVoice(String lang) {
    return _selectedVoices[lang] ?? _selectBestVoice(lang);
  }

  String? getActiveVoiceName(String lang) {
    final v = getActiveVoice(lang);
    if (v == null || v.isEmpty) return null;
    return friendlyVoiceName(v);
  }

  static String friendlyVoiceName(Map<String, String> voice) {
    final name = voice['name'] ?? '';
    final quality = (voice['quality'] ?? '').toLowerCase();
    final isNetwork = voice['network_required'] == '1';

    String label = name;
    if (name.contains('-x-')) {
      final parts = name.split('-x-');
      if (parts.length > 1) {
        final id = parts[1].replaceAll(RegExp(r'-(local|network)'), '').toUpperCase();
        final type = name.contains('network') || isNetwork ? 'Neural' : 'Natural';
        label = 'Google $type ($id)';
      }
    } else if (name.length > 20) {
      label = name.substring(0, 20);
    }

    if (quality == 'very high' || quality == 'high') {
      label += ' ⭐';
    }
    return label;
  }

  Future<void> setVoice(String lang, Map<String, String> voice) async {
    _selectedVoices[lang] = voice;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('tts_voice_$lang', voice['name'] ?? '');
    } catch (_) {}

    try {
      if (voice.containsKey('name') && voice.containsKey('locale')) {
        await _tts.setVoice({
          'name': voice['name']!,
          'locale': voice['locale']!,
        });
      }
    } catch (_) {}
  }

  Future<void> _applyBestVoice(String lang) async {
    final voice = _selectedVoices[lang] ?? _selectBestVoice(lang);
    if (voice != null && voice.isNotEmpty && voice['name'] != null && voice['locale'] != null) {
      try {
        await _tts.setVoice({
          'name': voice['name']!,
          'locale': voice['locale']!,
        });
      } catch (_) {}
    }
    await _tts.setLanguage(lang == 'hi' ? 'hi-IN' : 'en-US');
  }

  // General-purpose single-utterance speak (all non-story screens).
  Future<void> speak(
    String text, {
    BuildContext? context,
    String lang = 'en',
    double rate = 0.36,
    double pitch = 1.0,
    bool interrupt = true,
  }) async {
    if (context != null) {
      if (!context.mounted) return;
      final route = ModalRoute.of(context);
      if (route != null && !route.isCurrent) return;
    }
    if (interrupt) {
      await stop();
    }
    final request = _TtsRequest(
      text: text,
      lang: lang,
      rate: rate,
      pitch: pitch,
      sessionToken: _sessionToken,
      isPageFinal: false,
    );
    _queue.add(request);
    _processQueue();
    return request.completer.future;
  }

  // Story page narration — splits text into narrator + dialogue segments
  // and speaks each with a distinct voice. Fires [_pageCompletionHandler]
  // once after the last segment completes.
  Future<void> speakPage(
    String text, {
    BuildContext? context,
    String lang = 'en',
    double speed = 0.75,
  }) async {
    if (context != null) {
      if (!context.mounted) return;
      final route = ModalRoute.of(context);
      if (route != null && !route.isCurrent) return;
    }
    await stop();
    final segs = _parseVoices(text);
    int offset = 0;

    // Calibrate speed multiplier for children's storytelling:
    // Base rate: 0.34 in flutter_tts maps to ~0.68x native Android rate (comfortable storytelling).
    // Multipliers:
    // 0.5x  -> rate = 0.17 (native ~0.34x: calm, very slow bedtime reading)
    // 0.75x -> rate = 0.255 (native ~0.51x: cozy bedtime storytelling)
    // 1.0x  -> rate = 0.34 (native ~0.68x: standard storytelling pace)
    // 1.25x -> rate = 0.425 (native ~0.85x: brisk pace)
    final double baseRate = (0.34 * speed).clamp(0.14, 0.65);

    for (int i = 0; i < segs.length; i++) {
      final seg = segs[i];
      final isLast = i == segs.length - 1;
      _queue.add(_TtsRequest(
        text: seg.text,
        lang: lang,
        rate: seg.isDialogue ? (baseRate * 1.02).clamp(0.14, 0.65) : baseRate,
        pitch: seg.isDialogue ? 1.05 : 1.0, // subtle character warmth without distortion
        charOffset: offset,
        sessionToken: _sessionToken,
        isPageFinal: isLast,
      ));
      offset += seg.text.length;
    }
    _processQueue();
  }

  // Set handler called when a full story page finishes (all segments done).
  void setPageCompletionHandler(VoidCallback handler) {
    _pageCompletionHandler = handler;
  }

  void setProgressHandler(void Function(String, int, int, String) handler) {
    _tts.setProgressHandler(handler);
  }

  // Splits text into narrator and quoted-dialogue segments.
  static List<_VoiceSegment> _parseVoices(String text) {
    final segments = <_VoiceSegment>[];
    final regex = RegExp(r'"[^"]*"');
    int lastEnd = 0;
    for (final match in regex.allMatches(text)) {
      if (match.start > lastEnd) {
        final t = text.substring(lastEnd, match.start);
        if (t.trim().isNotEmpty) segments.add(_VoiceSegment(t, false));
      }
      segments.add(_VoiceSegment(match.group(0)!, true));
      lastEnd = match.end;
    }
    if (lastEnd < text.length) {
      final t = text.substring(lastEnd);
      if (t.trim().isNotEmpty) segments.add(_VoiceSegment(t, false));
    }
    return segments.isEmpty ? [_VoiceSegment(text, false)] : segments;
  }

  void _processQueue() async {
    if (_isSpeaking || _queue.isEmpty) return;
    _isSpeaking = true;
    final request = _queue.removeFirst();

    if (request.sessionToken != _sessionToken) {
      _isSpeaking = false;
      if (_queue.isNotEmpty) _processQueue();
      return;
    }

    try {
      await _init();
      if (request.sessionToken != _sessionToken) {
        _isSpeaking = false;
        await _tts.stop();
        return;
      }

      _currentOffset = request.charOffset;
      await _applyBestVoice(request.lang);
      if (request.sessionToken != _sessionToken) {
        _isSpeaking = false;
        await _tts.stop();
        return;
      }

      await _tts.setSpeechRate(request.rate);
      if (request.sessionToken != _sessionToken) {
        _isSpeaking = false;
        await _tts.stop();
        return;
      }

      await _tts.setPitch(request.pitch);
      if (request.sessionToken != _sessionToken) {
        _isSpeaking = false;
        await _tts.stop();
        return;
      }

      await _tts.speak(request.text);

      await Future.delayed(const Duration(milliseconds: 100));
      int attempts = 0;
      while (_isSpeaking && attempts < 120 && request.sessionToken == _sessionToken) {
        await Future.delayed(const Duration(milliseconds: 50));
        attempts++;
      }

      if (request.sessionToken != _sessionToken) {
        await _tts.stop();
        _isSpeaking = false;
        return;
      }

      request.completer.complete();

      if (request.isPageFinal && request.sessionToken == _sessionToken) {
        _pageCompletionHandler?.call();
      }
    } catch (e) {
      if (!request.completer.isCompleted) {
        request.completer.completeError(e);
      }
    } finally {
      _isSpeaking = false;
      // Slight natural pause between segments for human breathing cadence
      if (_queue.isNotEmpty && request.sessionToken == _sessionToken) {
        await Future.delayed(const Duration(milliseconds: 150));
        if (request.sessionToken == _sessionToken) {
          _processQueue();
        }
      }
    }
  }

  Future<void> stop() async {
    _sessionToken++;
    _queue.clear();
    _isSpeaking = false;
    try {
      await _tts.stop();
      // Catch any in-flight utterance that Android's async synthesis was preparing
      Future.delayed(const Duration(milliseconds: 80), () {
        _tts.stop();
      });
      Future.delayed(const Duration(milliseconds: 200), () {
        _tts.stop();
      });
    } catch (_) {
      _isSpeaking = false;
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    stop();
  }
}
