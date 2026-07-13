# Zoodles — New Mini-Game Concepts (Racing / Archery / Animal Feeding)

> **Status: all 3 shipped.** Animal Feeding, Archery, and Racing are built and
> wired into the home screen (17 activities total now). Kept below as the
> design record of what was actually built — a few details changed from the
> original brainstorm during implementation (noted inline).

Brainstormed ideas for the batch of games after the first 14 activities
(ABC, Math, Stories, Memory Match, Word Builder, Counting, Coloring, Puzzle,
Simon Says, Bubble Pop, Shape Sorter, Animal Sound Quiz, Whack-a-Mole, Maze
Runner).

> Note: `GAME_IDEAS.md` (the older tracking doc) is now stale — Coloring Book,
> Word Builder, Counting, and Puzzle Pieces are all marked TODO there but are
> actually shipped. Worth a cleanup pass separately; this file only covers the
> new concepts below.

---

## 1. Racing Game 🏎️ — DONE (`lib/screens/racing_screen.dart`)

Built as designed, with one simplification: instead of a continuous overlapping
spawn pool, each "wave" has exactly 3 tiles (one per lane, exactly one
correct) — guarantees a correct answer is always available and made the catch
logic much simpler to get right (`progress ∈ [0.80, 1.0)` + matching lane =
caught). Safety-net `CountdownBar` runs alongside the real end condition
(prompt count or word completion). Word Race re-issues a missed letter
instead of advancing, capped at 20 waves, so it can never soft-lock.


**Core idea:** vehicle auto-drives forward on a 3-lane road; the child switches
lanes (tap arrows or swipe) to collect the correct letter/word/number tile
before it passes, learning "on the move" instead of standing still. No crash /
fail state — wrong pickups simply don't score, keeping it stress-free for
younger kids. Speed increases over a run as the difficulty knob.

**Vehicle picker:** 🚗 car / 🏍️ bike / 🚲 cycle chosen at the start — cosmetic,
reuses the same "pick your character" pattern as the mascot picker on Home.

Three selectable modes (like Math Quiz's practice/tables/blitz):

- **Lane Sprint (Letters/Numbers):** prompt at top — "Collect: G" or "Next
  number: 7" — one lane has the right tile, others have distractors.
- **Word Race:** target word shown ("CAT"); letters scattered across lanes
  must be grabbed *in order* as they approach. Finish line = word spelled.
- **Math Dash:** a problem shows ("3 + 2 = ?"); each lane has a different
  number: steer into the correct-answer lane before it's too late.

**Reuse:** `CountdownBar` or a distance-progress bar for the run timer,
`AppState.addStars` / `awardWithToast` for rewards, `SoundType.correct/wrong`
for pickups. New mechanic for this codebase: continuous auto-scroll + lane
switch (closest existing precedent is none — first of its kind).

---

## 2. Archery Game 🏹 — DONE (`lib/screens/archery_screen.dart`)

Built as **Mixed Practice** rather than 3 separate selectable modes (user's
call, to keep scope tight) — each of the 10 questions randomly is a letter,
number, or math problem. Targets are bullseye discs in a grid; tapping shows
a hit/miss ring directly on that target rather than animating a separate
arrow sprite from the bow (simpler, same visual payoff).


**Core idea:** shooting-gallery style (no physics/trajectory sim needed, matches
this app's "no engine" convention) — several targets (balloons/boards) are on
screen, each labeled with a letter, number, or math answer. A prompt says
"Hit the letter M" / "Hit 7" / "Hit the answer to 4 + 3", and the child taps
the correct target; an arrow animates to it. Wrong taps just miss — no penalty.

**Modes:** Letters / Numbers / Math Ops — mirrors the Racing game's mode split
for consistency across the two.

**Difficulty scaling:** number of simultaneous targets, how fast targets drift
or swap position, and time per round (via `CountdownBar`).

**Reuse:** structurally close to Animal Sound Quiz's "tap the correct choice
from a grid" pattern, just with a bow/arrow visual flourish instead of a
static grid — low implementation risk since the core interaction already
exists in the codebase.

---

## 3. Animal Feeding Game 🦖 — DONE (`lib/screens/animal_feeding_screen.dart`)

Built with a **static reveal-and-tap** mechanic instead of floating/falling
items — lower risk than reskinning Bubble Pop's continuous scroll, and this
was meant to be the cheapest game to ship. Slots stay in place per prompt; a
per-prompt `CountdownBar` auto-advances on timeout. Wrong taps don't lock or
advance — only the correct tap or a timeout moves to the next prompt.


**Core idea:** the child picks a favorite animal at the start (🦖 dinosaur, 🐊
croc, 🦁 lion, 🐳 whale, etc.) as the "eater" character — a dedicated picker,
separate from (but visually similar to) the mascot picker on Home. Letters,
numbers, or words float/fall across the screen as "food"; a prompt shows the
target ("Feed me the letter S" / "Feed me 5"), and tapping the correct floating
item makes the animal chomp it (mouth-open emoji swap + a fun chomp sound).
Wrong items tapped just get ignored/spat out — no penalty, keeps it playful.

**Reuse:** this is mechanically Bubble Pop's spawn-float-tap loop, reskinned
with a chosen animal and a *target-matching* rule (must match the prompt)
rather than "any good bubble scores" — cheapest of the three to build since
the spawn/despawn timer-pool pattern is already proven and battle-tested.

---

## Badges (final, in `lib/utils/badge_service.dart`)

| Game | First-play | Hard/mastery |
|---|---|---|
| Racing | `race_first` 🏁 | `race_ace` 🏆 — Hard round finished with zero misses |
| Archery | `archery_first` 🏹 | `archery_perfect` 🎯 — 10/10 |
| Animal Feeding | `feed_first` 🦖 | `feed_ace` 🍖 — 10/10 on Hard |

Reward convention matches the rest of the app: `AppState.addStars(10)` on
completion, `+25` first-time badge, `+50` hardest-tier/perfect badge.

---

## Smaller backlog items (mentioned earlier, not forgotten)

- **Nursery Rhyme screen** — already built (`lib/screens/nursery_rhyme_screen.dart`,
  badges already defined) but not wired into Home; blocked on real audio
  files since `assets/audio/` is currently empty.
- **Rewards Shop** — spend accumulated stars on mascot skins/themes; gives
  stars a spending sink beyond the level bar.
- **Number Tracing** — mirror the existing letter-tracing flow in ABC &
  Phonics, inside Counting Fun.

---

## Build order used

Animal Feeding → Archery → Racing, cheapest/lowest-risk first, most novel
mechanic (Racing's lane-switch scrolling) last — exactly as planned.
