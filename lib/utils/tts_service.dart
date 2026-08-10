import 'dart:async';
import 'dart:collection';
import 'package:flutter/widgets.dart';
import 'package:flutter_tts/flutter_tts.dart';

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
  bool _initialized = false;
  final Queue<_TtsRequest> _queue = Queue();
  bool _isSpeaking = false;
  bool get isSpeaking => _isSpeaking;
  int _sessionToken = 0;

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
      await _tts.setPitch(1.1);
      await _tts.setSpeechRate(0.45);
      // Internal completion handler — keeps the queue moving.
      _tts.setCompletionHandler(() {
        _isSpeaking = false;
      });
      _initialized = true;
      _initCompleter!.complete();
    } catch (e) {
      _initCompleter!.completeError(e);
      _initCompleter = null;
    }
  }

  // General-purpose single-utterance speak (all non-story screens).
  Future<void> speak(
    String text, {
    BuildContext? context,
    String lang = 'en',
    double rate = 0.45,
    double pitch = 1.1,
  }) async {
    if (context != null) {
      if (!context.mounted) return;
      final route = ModalRoute.of(context);
      if (route != null && !route.isCurrent) return;
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
    double speed = 0.45,
  }) async {
    if (context != null) {
      if (!context.mounted) return;
      final route = ModalRoute.of(context);
      if (route != null && !route.isCurrent) return;
    }
    final segs = _parseVoices(text);
    int offset = 0;
    for (int i = 0; i < segs.length; i++) {
      final seg = segs[i];
      final isLast = i == segs.length - 1;
      _queue.add(_TtsRequest(
        text: seg.text,
        lang: lang,
        rate: seg.isDialogue ? (speed + 0.06).clamp(0.1, 0.9) : speed,
        pitch: seg.isDialogue ? 1.55 : 0.92,
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
        if (_queue.isNotEmpty) _processQueue();
        return;
      }

      _currentOffset = request.charOffset;
      await _tts.setLanguage(request.lang == 'hi' ? 'hi-IN' : 'en-US');
      await _tts.setSpeechRate(request.rate);
      await _tts.setPitch(request.pitch);
      await _tts.speak(request.text);

      await Future.delayed(const Duration(milliseconds: 100));
      int attempts = 0;
      while (_isSpeaking && attempts < 120 && request.sessionToken == _sessionToken) {
        await Future.delayed(const Duration(milliseconds: 50));
        attempts++;
      }

      if (request.sessionToken != _sessionToken) {
        if (_initialized) {
          await _tts.stop();
        }
        _isSpeaking = false;
        return;
      }

      request.completer.complete();

      if (request.isPageFinal) {
        _pageCompletionHandler?.call();
      }
    } catch (e) {
      if (!request.completer.isCompleted) {
        request.completer.completeError(e);
      }
    } finally {
      _isSpeaking = false;
      if (_queue.isNotEmpty) _processQueue();
    }
  }

  Future<void> stop() async {
    try {
      _sessionToken++;
      _queue.clear();
      if (_isSpeaking && _initialized) {
        _isSpeaking = false;
        await _tts.stop();
      } else {
        _isSpeaking = false;
      }
    } catch (_) {
      _isSpeaking = false;
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_initialized) {
      _tts.stop();
    }
  }
}
