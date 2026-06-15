import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

// Singleton — all screens share one TTS engine so they can't play simultaneously.
class TtsService {
  static final TtsService _instance = TtsService._();
  factory TtsService() => _instance;
  TtsService._();

  final FlutterTts _tts = FlutterTts();
  Completer<void>? _initCompleter;
  final Queue<_TtsRequest> _queue = Queue();
  bool _isSpeaking = false;

  Future<void> _init() async {
    // Use Completer to ensure only one initialization happens
    if (_initCompleter != null) {
      return _initCompleter!.future;
    }
    
    _initCompleter = Completer<void>();
    try {
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.1);
      await _tts.setSpeechRate(0.85);
      _initCompleter!.complete();
    } catch (e) {
      _initCompleter!.completeError(e);
      _initCompleter = null;
    }
  }

  Future<void> speak(String text, {String lang = 'en', double rate = 0.85, double pitch = 1.1}) async {
    final request = _TtsRequest(text: text, lang: lang, rate: rate, pitch: pitch);
    _queue.add(request);
    _processQueue();
    return request.completer.future;
  }

  void _processQueue() async {
    if (_isSpeaking || _queue.isEmpty) return;
    
    _isSpeaking = true;
    final request = _queue.removeFirst();
    
    try {
      await _init();
      await _tts.stop();
      await Future.delayed(const Duration(milliseconds: 50)); // Brief pause to ensure stop completes
      await _tts.setLanguage(request.lang == 'hi' ? 'hi-IN' : 'en-US');
      await _tts.setSpeechRate(request.rate);
      await _tts.setPitch(request.pitch);
      await _tts.speak(request.text);
      
      // Wait for speech to complete
      await Future.delayed(const Duration(milliseconds: 100));
      int attempts = 0;
      while (_isSpeaking && attempts < 100) {
        await Future.delayed(const Duration(milliseconds: 50));
        attempts++;
      }
      
      request.completer.complete();
    } catch (e) {
      request.completer.completeError(e);
    } finally {
      _isSpeaking = false;
      if (_queue.isNotEmpty) {
        _processQueue();
      }
    }
  }

  Future<void> stop() async {
    try {
      // Clear state and queue first so new speak() calls added after this
      // are not wiped by a delayed _queue.clear().
      _isSpeaking = false;
      _queue.clear();
      await _tts.stop();
    } catch (_) {}
  }

  void setCompletionHandler(VoidCallback handler) {
    _tts.setCompletionHandler(() {
      _isSpeaking = false;
      handler();
      if (_queue.isNotEmpty) {
        _processQueue();
      }
    });
  }

  void setProgressHandler(void Function(String, int, int, String) handler) {
    _tts.setProgressHandler(handler);
  }

  // Singleton — dispose just stops current speech, does not destroy the engine.
  void dispose() => _tts.stop();
}

class _TtsRequest {
  final String text;
  final String lang;
  final double rate;
  final double pitch;
  final Completer<void> completer = Completer();

  _TtsRequest({
    required this.text,
    required this.lang,
    required this.rate,
    required this.pitch,
  });
}
