import 'dart:math';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';

enum SoundType { tap, correct, wrong, win, slide, pop, tick, buzz, chime, chomp, vroom, critter }

class _Note {
  final double freq, dur, amp;
  const _Note(this.freq, this.dur, this.amp);
}

class SoundService {
  static final SoundService _i = SoundService._();
  factory SoundService() => _i;
  SoundService._();

  final _player = AudioPlayer();
  final Map<SoundType, Uint8List> _cache = {};

  static const _defs = <SoundType, List<_Note>>{
    SoundType.tap:     [_Note(880.0,   0.06, 0.40)],
    SoundType.correct: [_Note(523.25,  0.09, 0.50), _Note(659.25, 0.09, 0.55), _Note(783.99, 0.14, 0.65)],
    SoundType.wrong:   [_Note(220.0,   0.10, 0.55), _Note(164.81, 0.18, 0.55)],
    SoundType.win:     [_Note(523.25,  0.10, 0.60), _Note(659.25, 0.10, 0.60), _Note(783.99, 0.10, 0.60), _Note(1046.5, 0.28, 0.75)],
    SoundType.slide:   [_Note(330.0,   0.05, 0.35)],
    SoundType.pop:     [_Note(1100.0,  0.05, 0.45)],
    SoundType.tick:    [_Note(660.0,   0.04, 0.30)],
    SoundType.buzz:    [_Note(110.0,   0.22, 0.55)],
    SoundType.chime:   [_Note(784.0,   0.08, 0.50), _Note(988.0, 0.12, 0.55)],
    SoundType.chomp:   [_Note(180.0,   0.09, 0.50)],
    SoundType.vroom:   [_Note(140.0,   0.08, 0.40), _Note(180.0, 0.08, 0.45), _Note(230.0, 0.10, 0.50)],
    SoundType.critter: [_Note(392.0,   0.06, 0.40), _Note(523.25, 0.09, 0.45)],
  };

  static const _sampleRate = 22050;

  Uint8List _makeWav(List<_Note> notes) {
    int totalSamples = 0;
    for (final n in notes) { totalSamples += (n.dur * _sampleRate).round(); }

    final dataLen = totalSamples * 2;
    final buf = ByteData(44 + dataLen);

    // RIFF/WAVE header
    _str(buf,  0, 'RIFF');
    buf.setUint32(4, 36 + dataLen, Endian.little);
    _str(buf,  8, 'WAVE');
    _str(buf, 12, 'fmt ');
    buf.setUint32(16, 16, Endian.little);
    buf.setUint16(20,  1, Endian.little); // PCM
    buf.setUint16(22,  1, Endian.little); // mono
    buf.setUint32(24, _sampleRate,     Endian.little);
    buf.setUint32(28, _sampleRate * 2, Endian.little);
    buf.setUint16(32,  2, Endian.little);
    buf.setUint16(34, 16, Endian.little);
    _str(buf, 36, 'data');
    buf.setUint32(40, dataLen, Endian.little);

    int pos = 44;
    for (final n in notes) {
      final count = (n.dur * _sampleRate).round();
      for (int i = 0; i < count; i++) {
        final t   = i / _sampleRate;
        final env = (1.0 - i / count).clamp(0.0, 1.0);
        final v   = (sin(2 * pi * n.freq * t) * env * n.amp * 32767)
            .round()
            .clamp(-32768, 32767);
        buf.setInt16(pos, v, Endian.little);
        pos += 2;
      }
    }

    return buf.buffer.asUint8List();
  }

  static void _str(ByteData buf, int offset, String s) {
    for (int i = 0; i < s.length; i++) { buf.setUint8(offset + i, s.codeUnitAt(i)); }
  }

  Uint8List _get(SoundType type) =>
      _cache.putIfAbsent(type, () => _makeWav(_defs[type]!));

  Future<void> play(SoundType type) async {
    try {
      await _player.stop();
      await _player.play(BytesSource(_get(type)));
    } catch (_) {}
  }
}
