import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/story_data.dart';

/// Stores user-added stories in SharedPreferences as JSON.
/// Works on all platforms: Web, iOS, Android, macOS, Windows, Linux.
/// Built-in stories (0..N-1) are always loaded from story_data.dart.
class StoryRepository extends ChangeNotifier {
  static final StoryRepository _instance = StoryRepository._();
  factory StoryRepository() => _instance;
  StoryRepository._();

  static const _prefKey = 'custom_stories_v1';

  // ── Serialisation ────────────────────────────────────────────────────────

  static List<Map<String, dynamic>> _encodePages(List<StoryPage> pages) =>
      pages.map((p) => {'scene': p.scene, 'text': p.text}).toList();

  static List<StoryPage> _decodePages(dynamic raw) {
    if (raw == null) return [];
    return (raw as List)
        .map((e) => StoryPage(
              scene: (e['scene'] as String?) ?? '',
              text: (e['text'] as String?) ?? '',
            ))
        .toList();
  }

  static Map<String, dynamic> _toMap(StoryData s) => {
        'id': s.id,
        'icon': s.icon,
        'color': s.color.toARGB32(),
        'en_title': s.en.title,
        'en_tag': s.en.tag,
        'en_moral': s.en.moral,
        'en_pages': _encodePages(s.en.pages),
        'hi_title': s.hi.title,
        'hi_tag': s.hi.tag,
        'hi_moral': s.hi.moral,
        'hi_pages': _encodePages(s.hi.pages),
      };

  static StoryData _fromMap(Map<String, dynamic> m) {
    final enPages = _decodePages(m['en_pages']);
    final hiPages = _decodePages(m['hi_pages']);
    final hiTitle = (m['hi_title'] as String?) ?? '';
    return StoryData(
      id: m['id'] as int,
      icon: m['icon'] as String,
      color: Color(m['color'] as int),
      en: StoryVersion(
        title: m['en_title'] as String,
        tag: (m['en_tag'] as String?) ?? '',
        pages: enPages,
        moral: (m['en_moral'] as String?) ?? '',
      ),
      hi: StoryVersion(
        title: hiTitle.isNotEmpty ? hiTitle : (m['en_title'] as String),
        tag: (m['hi_tag'] as String?) ?? (m['en_tag'] as String?) ?? '',
        pages: hiPages.isNotEmpty ? hiPages : enPages,
        moral: (m['hi_moral'] as String?) ?? (m['en_moral'] as String?) ?? '',
      ),
    );
  }

  // ── Persistence ──────────────────────────────────────────────────────────

  Future<List<StoryData>> _loadCustom() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefKey);
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List)
          .map((e) => _fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveCustom(List<StoryData> custom) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, jsonEncode(custom.map(_toMap).toList()));
  }

  // ── Public API ───────────────────────────────────────────────────────────

  /// Returns built-in stories followed by user-added stories.
  Future<List<StoryData>> getAll() async {
    final custom = await _loadCustom();
    return [...stories, ...custom];
  }

  /// Adds a new custom story. Uses timestamp as unique ID.
  Future<void> add(StoryData s) async {
    final custom = await _loadCustom();
    final id = DateTime.now().millisecondsSinceEpoch;
    custom.add(StoryData(id: id, icon: s.icon, color: s.color, en: s.en, hi: s.hi));
    await _saveCustom(custom);
    notifyListeners();
  }

  /// Updates an existing custom story. Built-in stories cannot be updated.
  Future<void> update(StoryData s) async {
    if (isBuiltin(s.id)) return;
    final custom = await _loadCustom();
    final idx = custom.indexWhere((c) => c.id == s.id);
    if (idx >= 0) {
      custom[idx] = s;
      await _saveCustom(custom);
      notifyListeners();
    }
  }

  /// Deletes a custom story. Built-in stories cannot be deleted.
  Future<void> delete(int id) async {
    if (isBuiltin(id)) return;
    final custom = await _loadCustom();
    custom.removeWhere((s) => s.id == id);
    await _saveCustom(custom);
    notifyListeners();
  }

  /// Returns true for the 8 built-in stories (id 0..7).
  bool isBuiltin(int id) => id >= 0 && id < stories.length;
}
