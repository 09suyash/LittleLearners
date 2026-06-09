# Little Learners — End-to-End App Documentation

## Overview

Little Learners is a Flutter kids-learning app targeting ages 2–10. It bundles three mini-apps — ABC & Phonics, Math Quiz, and Moral Stories — inside a single shell with a bottom navigation bar. The app runs in portrait-only, full-screen (immersive) mode with a dark gradient aesthetic on the home and math/ABC screens, and a warm parchment aesthetic on the stories screen.

---

## Tech Stack

| Concern | Solution |
|---|---|
| Framework | Flutter (Dart 3) |
| TTS | `flutter_tts` — singleton `TtsService` shared across all screens |
| Persistence | `shared_preferences` — scores, learned letters, completed stories |
| State | `StatefulWidget` + `setState`; `ValueNotifier<int>` for cross-widget tab signalling |
| Animation | `AnimationController` / `TweenSequence` / `AnimatedScale` / `CustomPainter` |
| Navigation | `IndexedStack` — all 4 screens stay mounted (no rebuild on tab switch) |

---

## Project Structure

```
lib/
├── main.dart                  # App entry point, MainShell widget
├── models/
│   ├── letter_data.dart       # LetterData model + 26-letter constant list
│   └── story_data.dart        # StoryData / StoryVersion / StoryPage models + 8 stories
├── screens/
│   ├── home_screen.dart       # Home / dashboard screen
│   ├── abc_screen.dart        # ABC & Phonics mini-app
│   ├── math_screen.dart       # Math Quiz mini-app
│   └── stories_screen.dart    # Moral Stories mini-app
└── utils/
    ├── fx.dart                # Shared UI widgets: TapScale, ConfettiOverlay
    └── tts_service.dart       # Singleton TTS wrapper
```

---

## App Entry — `main.dart`

### Startup
- Locks orientation to portrait-up.
- Enables `SystemUiMode.immersiveSticky` (hides status bar and navigation bar).

### `MainShell`
- Top-level stateful widget that owns navigation state.
- `int _tab` drives the `IndexedStack` child index.
- `ValueNotifier<int> _tabNotifier` broadcasts tab changes to child screens that need to react (currently only `HomeScreen`).
- `goToTab(int idx)` updates both `_tab` and `_tabNotifier` so nav bar taps and in-app card taps both work.
- Bottom nav bar has 4 items: **HOME** 🏠, **ABC** 🔤, **MATH** 🔢, **STORIES** 📚.

---

## Home Screen (`home_screen.dart`)

The landing/dashboard screen. Dark purple gradient background with twinkling star particles.

### Visual Layout
1. **Animated mascot** — 48px emoji that floats up/down (sine wave, 3 s period). Tap cycles through 10 emojis (`🎓🦉🤩🐸⭐🦄🎉🌈🐨🚀`) with a bounce/scale TweenSequence animation.
2. **Gradient title** — "Little Learners" with a 4-colour shader mask (yellow → red → green → blue).
3. **Stats row** — Three pills: ABC Score (letters learned / 26), Math Score (best quiz score / total), Stories Read (count).
4. **App cards** — One card per mini-app showing icon, name, description, and feature tags. Tapping navigates to that tab.
5. **Footer** — Version string and a "Reset Progress" underlined link.

### Logic
- `_loadStats()` reads SharedPreferences and refreshes the three stat pills.
- `_onTabChange()` listens on `tabNotifier`; re-calls `_loadStats()` whenever the user returns to tab 0 (solves stale-stats issue with `IndexedStack`).
- `_confirmReset()` shows an `AlertDialog` asking for confirmation, then calls `SharedPreferences.clear()` and refreshes stats.

### Star background
50 `_StarWidget` instances — each is an independent `StatefulWidget` with its own `AnimationController` that fades the star opacity in/out on a random period (2–6 s) and random delay.

---

## ABC & Phonics Screen (`abc_screen.dart`)

Teaches all 26 letters with voice, tracing canvas, and a quiz mode.

### Views (`enum AbcView`)
| View | Description |
|---|---|
| `grid` | Main 26-letter grid |
| `trace` | Full-screen letter tracing canvas |
| `quiz` | 10-question letter-identification quiz |
| `result` | Quiz result screen |

### Letter Grid (`AbcView.grid`)
- 4-column `GridView` of letter cards. Each card shows the letter, its emoji, and a coloured accent border.
- Letters already opened are marked with a checkmark badge.
- A progress bar at the top shows how many of the 26 letters have been learned.
- **"Start Quiz" button** launches the quiz if at least 4 letters have been learned.
- Tapping a letter card opens `_LetterSheet` (modal bottom sheet) and immediately speaks the letter via TTS.

### Letter Sheet (`_LetterSheet`)
Modal bottom sheet showing:
- Large letter + phonetic description (e.g. `/æ/ — like in "cat"`)
- Primary word with its emoji
- Three example words with emojis
- **"Trace It"** button → navigates to `AbcView.trace`
- Speak button — reads the letter aloud
- Prev / Next arrows to navigate between letters without closing

### Trace Screen (`_TraceScreen`)
- Full-screen `CustomPainter` canvas.
- User draws with finger; strokes are stored as a list of `Offset` lists.
- **Clear** button wipes the canvas.
- **Back** button returns to the grid.
- The letter is shown as a faint guide behind the canvas.

### Quiz (`AbcView.quiz`)
- 10 random questions generated by `_startQuiz()`. Each question picks a random letter, then 3 wrong distractors — answer and distractors are shuffled.
- `_QuizQuestion` stores: `answer` (letter), `emoji`, `word`, and `choices` (4 letter strings).
- Each question shows the emoji + word at the top and 4 letter-choice buttons.
- A per-question `_TimerBar` counts down 12 seconds; timeout calls `_answerQuiz(-1)`.
- `_answerQuiz(choiceIdx)` checks correctness (guards `choiceIdx < 0` for timeout), plays TTS feedback, and advances after 1.5 s.
- ✕ close button quits to grid at any time.

### Result (`AbcView.result`)
- Displays score / 10, personal best, star rating (⭐–⭐⭐⭐), and how many letters learned overall.
- "Try Again" and "Back to Letters" buttons.

### Persistence (ABC)
| Key | Type | Meaning |
|---|---|---|
| `abc_learned_letters` | `List<String>` | Letters the user has opened (e.g. `["A","B","C"]`) |
| `abc_learned` | `int` | Count of learned letters (used by Home screen) |
| `abc_quiz_best` | `int` | Best quiz score out of 10 |

---

## Math Quiz Screen (`math_screen.dart`)

Three modes — Practice, Times Tables, and Blitz — all share one screen with an internal state machine.

### Views (`enum MathView`)
| View | Description |
|---|---|
| `modeSelect` | Choose Practice / Tables / Blitz |
| `settings` | Configure the chosen mode |
| `quiz` | Practice or Tables question-by-question quiz |
| `blitz` | 60-second rapid-fire blitz |
| `result` | Score, badges, leaderboard, confetti |

### Data Types
- **`enum MathOp`** — `add`, `sub`, `mul`
- **`enum Difficulty`** — `easy` (max 10), `med` (max 20), `hard` (max 50)
- **`_MathQuestion`** — holds `display` (e.g. `"3 + 4"`), `answer` (int), `choices` (List of 4 shuffled ints). Choices are generated once at question creation — never re-randomised.
- **`_LbEntry`** — name, score, total; up to 5 entries kept in an in-memory leaderboard.

### Mode Select
Three cards: Practice, Times Tables, and Blitz (featured with gold border). Tapping navigates to Settings for that mode.

### Settings
Common to all modes: player name text field.

**Practice mode settings:**
- Operation: Add / Sub / Mul
- Difficulty: Easy / Medium / Hard
- Question count: 5 / 10 / 15
- Missing Number Mode: Off / On

**Times Tables settings:**
- Choose which table (2× – 12×) via a 4-column grid of chips.

**Blitz settings:**
- Difficulty: Easy / Medium / Hard
- Operations toggle: ➕ Add / ➖ Sub / ✖️ Mul (multi-select, minimum 1 always active)

### Question Generation (`_genQ`)
- Generates `a`, `b` within the difficulty range for the chosen operation.
- If **Missing Number Mode** is on, the display is `? sym b = ans` and the answer to find is `a`; choices are generated around `a` instead of `ans`.
- `_genChoices(ans)` creates 3 distractors by adding/subtracting random offsets from the answer, ensures no negatives or duplicates, then shuffles.

### Practice / Tables Quiz (`_buildQuiz`)
- Header row: ✕ exit button, current score (⭐ N), question counter, streak fire badge.
- `_TimerBar` (12 s countdown, green → red); timeout triggers `_checkAnswer(-1)`.
- Question card: large equation text (`"3 + 4 = ?"` or `"? + 4 = 7"` in missing mode).
- 💡 Hint button (one use per question) — eliminates one wrong choice by making it 22% opacity and non-tappable.
- 2×2 grid of answer buttons wrapped in `TapScale` (press-scale) and `AnimatedScale` (pops the correct choice on reveal).
- Feedback text below grid shows correct/wrong/streak.
- After 1.5 s auto-advances; delayed callback guards `_view == MathView.quiz` so pressing ✕ mid-delay doesn't trigger `_finishQuiz()`.

### Blitz (`_buildBlitz`)
- Pre-generates 200 questions. Displays one at a time.
- `_BlitzTimer` counts down from 60 s; on finish calls `_finishBlitz()`.
- Stats row: remaining time, score (⭐), answered count, ✕ exit button.
- No hint, no per-question timer — pure speed.
- 380 ms flash between questions (shows green/red briefly before advancing).

### Result (`_buildResult`)
- Works for both quiz and blitz (`_lastMode` flag distinguishes).
- Shows emoji + title + player name + stars + big score number (% for quiz, correct count for blitz).
- Blitz personal best shown if `_blitzBest > 0`.
- Badges: Perfect Score 💯, Streak Master 🔥, Sharpshooter 🎯, Lightning Fast ⚡, Blitz Champion 🏆.
- In-session leaderboard (practice/tables only, top 5 by score).
- ConfettiOverlay fires if score ≥ 60% (quiz) or ≥ 10 (blitz).
- Buttons: "🏠 Modes" → modeSelect; "🔄 Try Again" → settings.

### Persistence (Math)
| Key | Type | Meaning |
|---|---|---|
| `math_best` | `int` | Best quiz score (raw correct count) |
| `math_best_total` | `int` | Total questions in the best quiz |
| `blitz_best` | `int` | Best blitz score (correct in 60 s) |

---

## Moral Stories Screen (`stories_screen.dart`)

8 classic moral stories in English and Hindi with full voice narration, word-by-word text highlighting, and page-by-page reading.

### Views
| State | Description |
|---|---|
| `_openStory == null` | Story grid (browse and search) |
| `_openStory != null` | Story reader |

### Story Grid
- Warm parchment background (`#fdf6ec`).
- Language toggle (English / हिंदी) — switches all text and TTS language instantly.
- Info banner explaining TTS usage.
- Live search field filtering by title and tag.
- Story cards show: icon, title, tag, page count, "✓ Done" badge if completed.

### Story Reader
- Back button → returns to grid, stops TTS.
- Story icon, title, "Page N of Total" or "Story Complete 🎉" status.
- Linear progress bar (current page / total pages).

**Active page:**
- Page card: scene emoji strip + `_HighlightedText` widget.
- Audio controls bar: ▶/■ play-stop button, narrating status text, speed buttons (0.7× / 1× / 1.3×).
- Auto-advance toggle: switch that moves to the next page 900 ms after narration ends.

**Completion screen (isEnd):**
- Moral card with gradient background showing the story's moral and a "Read Moral Aloud" button.
- Completion card with 🎉, "Well done!" and three stars.

**Nav buttons (always visible):**
- During reading: **← Prev** / **Next →** (last page shows "See Moral →").
- On completion: **← All Stories** (grid) / **Next Story →** (jumps to the next unfinished story; if all done, cycles to the next in sequence).

### Word Highlighting (`_HighlightedText`)
- TTS `setProgressHandler` provides the char offset of the current word.
- `_buildWords(text)` indexes every non-whitespace token with its start/end char positions.
- The active word gets a light amber background + brown bold style; all other words use normal style.

### Story Data (`story_data.dart`)
Each `StoryData` has an `id`, `icon`, accent `color`, and two `StoryVersion` objects (`en`, `hi`). Each version has a `title`, `tag`, a list of `StoryPage` (scene emoji strip + paragraph text), and a `moral` string.

**The 8 stories:**
| # | Title | Moral theme |
|---|---|---|
| 0 | The Lion and the Mouse / शेर और चूहा | Kindness always comes back |
| 1 | The Tortoise and the Hare / कछुआ और खरगोश | Slow and steady wins the race |
| 2 | The Fox and the Grapes / लोमड़ी और अंगूर | Don't make excuses for failure |
| 3 | The Crow and the Pitcher / कौआ और घड़ा | Use your brain to solve problems |
| 4 | The Ant and the Grasshopper / चींटी और टिड्डा | Work today, enjoy tomorrow |
| 5 | The Greedy Dog / लालची कुत्ता | Be thankful for what you have |
| 6 | The Boy Who Cried Wolf / भेड़िया आया रे | Always tell the truth |
| 7 | The Golden Goose / सोने के अंडे वाली मुर्गी | Greed destroys what you have |

### Persistence (Stories)
| Key | Type | Meaning |
|---|---|---|
| `stories_done` | `List<String>` | IDs of completed stories (e.g. `["0","2"]`) |

---

## Shared Utilities

### `TtsService` (`utils/tts_service.dart`)
A singleton wrapping `flutter_tts`. All three screens share the same instance so only one voice plays at a time.

- `speak(text, {lang, rate, pitch})` — stops current speech then speaks new text.
- `stop()` — stops speech immediately.
- `setCompletionHandler(cb)` — called when an utterance finishes (used by stories for auto-advance).
- `setProgressHandler(cb)` — called per-word with char positions (used for word highlighting).
- `dispose()` — only stops current speech; does not destroy the engine (singleton lifecycle).

Default voice settings: volume 1.0, pitch 1.1, rate 0.85.

### `fx.dart` (`utils/fx.dart`)

**`TapScale`**
A gesture wrapper that scales its child to 0.88 on tap-down and back to 1.0 on release, with a 120 ms animation. Wraps quiz answer buttons throughout the app.

**`ConfettiOverlay`**
A full-screen overlay of falling coloured rectangles rendered via `CustomPainter`. Triggered by a `bool trigger` parameter. Each particle has a random colour, start position, fall speed, rotation speed, and horizontal drift. Particles reset to the top when they fall off-screen. Used on the Math quiz and Blitz result screens when score is good.

---

## Letter Data (`models/letter_data.dart`)

`LetterData` — `letter`, `emoji`, `primaryWord`, `words` (3 example words), `phonetic` (IPA description), `color`.

`letters` — const list of all 26 `LetterData` entries (A–Z).

`wordEmojis` — const map from word string to emoji (78 entries) used to render emoji next to example words in the letter sheet.

---

## SharedPreferences — All Keys

| Key | Type | Written by | Read by |
|---|---|---|---|
| `abc_learned_letters` | `List<String>` | ABC screen | ABC screen |
| `abc_learned` | `int` | ABC screen | Home screen |
| `abc_quiz_best` | `int` | ABC screen | ABC screen |
| `math_best` | `int` | Math screen | Home screen |
| `math_best_total` | `int` | Math screen | Home screen |
| `blitz_best` | `int` | Math screen | Math screen |
| `stories_done` | `List<String>` | Stories screen | Home + Stories screens |

All keys are cleared together by the Home screen's "Reset Progress" feature.

---

## Navigation Flow

```
MainShell (IndexedStack)
├── Tab 0 — HomeScreen
│     └── App cards → goToTab(1/2/3)
├── Tab 1 — AbcScreen
│     AbcView.grid → tap letter → LetterSheet (modal)
│                  → "Trace It" → AbcView.trace
│                  → "Start Quiz" → AbcView.quiz → AbcView.result
├── Tab 2 — MathScreen
│     MathView.modeSelect → MathView.settings → MathView.quiz → MathView.result
│                                             → MathView.blitz → MathView.result
└── Tab 3 — StoriesScreen
      grid → tap story → reader (page-by-page) → completion → Next Story or All Stories
```

---

## Key Design Decisions

- **`IndexedStack`** keeps all screens alive simultaneously so switching tabs is instant and stateful (no rebuilds). The trade-off is that `initState` runs only once per session; the Home screen works around this with a `ValueNotifier` listener.
- **Singleton TTS** prevents two screens from speaking at once — a common bug when each screen creates its own `FlutterTts` instance.
- **Choices stored on `_MathQuestion`** — generating choices in `build()` each frame would produce different random orderings than what was generated in `_checkAnswer()`, causing the wrong answer to always appear correct. Storing them once at question creation fixes this.
- **Guard `choiceIdx < 0`** in answer handlers — per-question timers fire `_checkAnswer(-1)` on timeout; without the guard, `choices[-1]` would throw a `RangeError`.
