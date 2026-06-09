# Little Learners — Game & Feature Ideas

## Quick Wins (1–2 days each)

### 1. Reward Stickers / Badge Cabinet
- Unlock a sticker for every 5 letters learned, every quiz passed, every story finished
- A "Trophy Room" tab where kids collect all earned badges
- Dramatically increases return visits — single best retention mechanic for kids apps
- **Status: DONE** — 18 badges across ABC/Math/Stories/Memory, BADGES 🏅 tab in bottom nav

### 2. Daily Challenge
- One fixed daily puzzle: a math problem, a hidden letter, or a story trivia question
- Streak counter ("Day 3 🔥") keeps kids coming back every day
- Resets at midnight, saved to SharedPreferences
- **Status: DONE** — 3 challenge types (math/letter/trivia), deterministic daily seed, streak counter, 3 badges, card on Home screen

### 3. Coloring Book
- 10–15 simple outlines (animals, fruits, vehicles) filled with a palette of 12 colors
- Zero learning curve, maximum engagement for ages 2–5
- Uses CustomPainter flood-fill or region tap
- **Status: TODO**

---

## Medium Effort (3–5 days each)

### 4. Memory Card Flip Game ⭐ RECOMMENDED
- 8 pairs of letter + emoji cards face-down on a grid
- Flip two at a time; match all pairs to win
- Reuses existing LetterData — zero new content needed
- Targets ages 2–5 who find quizzes too hard
- **Status: DONE** — Easy/Medium/Hard (4/6/8 pairs), move counter, timer, win screen, 2 badges

### 5. Word Builder
- Show a picture, drag letter tiles into blank slots to spell the word (3–4 letters)
- Bridges ABC learning and reading — natural next step after letters
- Uses existing wordEmojis map from letter_data.dart
- **Status: TODO**

### 6. Counting / Number Recognition (Toddler Mode)
- Show 1–10 dots, tap the matching number
- Separate from Math Quiz, targets ages 2–4
- No addition needed — pure number recognition
- **Status: TODO**

### 7. Puzzle Pieces
- Split a story scene illustration into 9 tiles
- Slide/drag to reassemble the picture
- Introduces a new interaction mechanic, ties back to stories
- **Status: TODO**

---

## Bigger Reach Expansions

### 8. Parent Dashboard
- PIN-locked settings section
- Shows: time spent per app, weakest letters, average quiz score, stories read
- Parents choose apps for their kids — giving them visibility is a key conversion driver
- **Status: TODO**

### 9. More Languages
- Add Spanish or French to stories and ABC phonics
- TTS architecture already supports language switching — minimal code change
- India + diaspora + Spanish-speaking markets are huge reach
- **Status: TODO**

### 10. Nursery Rhyme Karaoke
- Scrolling lyrics synced to TTS (word-highlight logic already exists in stories screen)
- 5 classic rhymes: Twinkle Twinkle, BINGO, Wheels on the Bus, Old MacDonald, ABC Song
- Covers the 2–4 age gap where quizzes don't work yet
- **Status: TODO**

---

## Implementation Priority

| Priority | Feature | Reason |
|---|---|---|
| 1 | Badge Cabinet | Turns every existing feature into a reward loop |
| 2 | Memory Card Flip | New mechanic, targets youngest users, reuses existing data |
| 3 | Daily Challenge | Best retention driver, simple to implement |
| 4 | Word Builder | Natural progression from ABC learning |
| 5 | Coloring Book | Pure fun for ages 2–5 |
| 6 | Counting Mode | Fills the toddler gap in Math |
| 7 | Nursery Rhymes | Covers 2–4 age range with zero quiz pressure |
| 8 | Puzzle Pieces | Ties stories to interactive play |
| 9 | Parent Dashboard | Drives adult adoption |
| 10 | More Languages | Expands geographic reach |
