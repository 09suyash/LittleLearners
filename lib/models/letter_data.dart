import 'package:flutter/material.dart';

class LetterData {
  final String letter;
  final String emoji;
  final String primaryWord;
  final List<String> words;
  final String phonetic;
  final Color color;

  const LetterData({
    required this.letter,
    required this.emoji,
    required this.primaryWord,
    required this.words,
    required this.phonetic,
    required this.color,
  });
}

const List<LetterData> letters = [
  LetterData(letter: 'A', emoji: '🍎', primaryWord: 'Apple',    words: ['Apple', 'Ant', 'Arrow'],       phonetic: '/æ/ — like in "apple"',  color: Color(0xFFFF6B6B)),
  LetterData(letter: 'B', emoji: '🎈', primaryWord: 'Balloon',  words: ['Ball', 'Bird', 'Balloon'],     phonetic: '/b/ — like in "ball"',   color: Color(0xFFFF8E53)),
  LetterData(letter: 'C', emoji: '🐱', primaryWord: 'Cat',      words: ['Cat', 'Cake', 'Car'],          phonetic: '/k/ — like in "cat"',    color: Color(0xFFFFC300)),
  LetterData(letter: 'D', emoji: '🐶', primaryWord: 'Dog',      words: ['Dog', 'Duck', 'Drum'],         phonetic: '/d/ — like in "dog"',    color: Color(0xFF51CF66)),
  LetterData(letter: 'E', emoji: '🥚', primaryWord: 'Egg',      words: ['Egg', 'Eye', 'Elephant'],      phonetic: '/ɛ/ — like in "egg"',    color: Color(0xFF339AF0)),
  LetterData(letter: 'F', emoji: '🐟', primaryWord: 'Fish',     words: ['Fish', 'Frog', 'Flag'],        phonetic: '/f/ — like in "fish"',   color: Color(0xFF845EF7)),
  LetterData(letter: 'G', emoji: '🍇', primaryWord: 'Grapes',   words: ['Goat', 'Gift', 'Grapes'],      phonetic: '/g/ — like in "goat"',   color: Color(0xFFF06595)),
  LetterData(letter: 'H', emoji: '🎩', primaryWord: 'Hat',      words: ['Hat', 'Horse', 'House'],       phonetic: '/h/ — like in "hat"',    color: Color(0xFFFF6B6B)),
  LetterData(letter: 'I', emoji: '🦎', primaryWord: 'Iguana',   words: ['Igloo', 'Ink', 'Iguana'],      phonetic: '/ɪ/ — like in "ink"',    color: Color(0xFFFF8E53)),
  LetterData(letter: 'J', emoji: '🧃', primaryWord: 'Juice',    words: ['Jar', 'Jump', 'Juice'],        phonetic: '/dʒ/ — like in "jar"',  color: Color(0xFFFFC300)),
  LetterData(letter: 'K', emoji: '🪁', primaryWord: 'Kite',     words: ['Kite', 'Key', 'Koala'],        phonetic: '/k/ — like in "kite"',   color: Color(0xFF51CF66)),
  LetterData(letter: 'L', emoji: '🦁', primaryWord: 'Lion',     words: ['Lion', 'Leaf', 'Lemon'],       phonetic: '/l/ — like in "lion"',   color: Color(0xFF339AF0)),
  LetterData(letter: 'M', emoji: '🥭', primaryWord: 'Mango',    words: ['Moon', 'Mango', 'Monkey'],     phonetic: '/m/ — like in "moon"',   color: Color(0xFF845EF7)),
  LetterData(letter: 'N', emoji: '🪺', primaryWord: 'Nest',     words: ['Nest', 'Nose', 'Night'],       phonetic: '/n/ — like in "nest"',   color: Color(0xFFF06595)),
  LetterData(letter: 'O', emoji: '🍊', primaryWord: 'Orange',   words: ['Orange', 'Owl', 'Ox'],         phonetic: '/ɒ/ — like in "orange"', color: Color(0xFFFF6B6B)),
  LetterData(letter: 'P', emoji: '🦜', primaryWord: 'Parrot',   words: ['Parrot', 'Pear', 'Pizza'],     phonetic: '/p/ — like in "parrot"', color: Color(0xFFFF8E53)),
  LetterData(letter: 'Q', emoji: '👑', primaryWord: 'Queen',    words: ['Queen', 'Quilt', 'Quail'],     phonetic: '/kw/ — like in "queen"', color: Color(0xFFFFC300)),
  LetterData(letter: 'R', emoji: '🌈', primaryWord: 'Rainbow',  words: ['Rain', 'Rabbit', 'Rainbow'],   phonetic: '/r/ — like in "rain"',   color: Color(0xFF51CF66)),
  LetterData(letter: 'S', emoji: '☀️', primaryWord: 'Sun',      words: ['Sun', 'Star', 'Snake'],        phonetic: '/s/ — like in "sun"',    color: Color(0xFF339AF0)),
  LetterData(letter: 'T', emoji: '🐯', primaryWord: 'Tiger',    words: ['Tiger', 'Tree', 'Train'],      phonetic: '/t/ — like in "tiger"',  color: Color(0xFF845EF7)),
  LetterData(letter: 'U', emoji: '☂️', primaryWord: 'Umbrella', words: ['Umbrella', 'Unicorn', 'Urn'],  phonetic: '/ʌ/ — like in "umbrella"', color: Color(0xFFF06595)),
  LetterData(letter: 'V', emoji: '🚐', primaryWord: 'Van',      words: ['Van', 'Vine', 'Violin'],       phonetic: '/v/ — like in "van"',    color: Color(0xFFFF6B6B)),
  LetterData(letter: 'W', emoji: '🍉', primaryWord: 'Watermelon',words: ['Wolf', 'Whale', 'Watermelon'],phonetic: '/w/ — like in "wolf"',   color: Color(0xFFFF8E53)),
  LetterData(letter: 'X', emoji: '🩻', primaryWord: 'X-ray',    words: ['X-ray', 'Fox', 'Box'],         phonetic: '/ks/ — like in "fox"',   color: Color(0xFFFFC300)),
  LetterData(letter: 'Y', emoji: '🐂', primaryWord: 'Yak',      words: ['Yak', 'Yarn', 'Yo-yo'],        phonetic: '/j/ — like in "yak"',    color: Color(0xFF51CF66)),
  LetterData(letter: 'Z', emoji: '🦓', primaryWord: 'Zebra',    words: ['Zebra', 'Zero', 'Zip'],        phonetic: '/z/ — like in "zebra"',  color: Color(0xFF339AF0)),
];

const wordEmojis = {
  'Apple': '🍎', 'Ant': '🐜', 'Arrow': '🏹',
  'Ball': '⚽', 'Bird': '🐦', 'Balloon': '🎈',
  'Cat': '🐱', 'Cake': '🎂', 'Car': '🚗',
  'Dog': '🐶', 'Duck': '🦆', 'Drum': '🥁',
  'Egg': '🥚', 'Eye': '👁️', 'Elephant': '🐘',
  'Fish': '🐟', 'Frog': '🐸', 'Flag': '🚩',
  'Goat': '🐐', 'Gift': '🎁', 'Grapes': '🍇',
  'Hat': '🎩', 'Horse': '🐴', 'House': '🏠',
  'Igloo': '🏔️', 'Ink': '🖊️', 'Iguana': '🦎',
  'Jar': '🫙', 'Jump': '🤸', 'Juice': '🧃',
  'Kite': '🪁', 'Key': '🔑', 'Koala': '🐨',
  'Lion': '🦁', 'Leaf': '🍃', 'Lemon': '🍋',
  'Moon': '🌙', 'Mango': '🥭', 'Monkey': '🐒',
  'Nest': '🪺', 'Nose': '👃', 'Night': '🌙',
  'Orange': '🍊', 'Owl': '🦉', 'Ox': '🐂',
  'Parrot': '🦜', 'Pear': '🍐', 'Pizza': '🍕',
  'Queen': '👑', 'Quilt': '🛏️', 'Quail': '🐦',
  'Rain': '🌧️', 'Rabbit': '🐰', 'Rainbow': '🌈',
  'Sun': '☀️', 'Star': '⭐', 'Snake': '🐍',
  'Tiger': '🐯', 'Tree': '🌳', 'Train': '🚂',
  'Umbrella': '☂️', 'Unicorn': '🦄', 'Urn': '🏺',
  'Van': '🚐', 'Vine': '🌿', 'Violin': '🎻',
  'Wolf': '🐺', 'Whale': '🐋', 'Watermelon': '🍉',
  'X-ray': '🩻', 'Fox': '🦊', 'Box': '📦',
  'Yak': '🐂', 'Yarn': '🧶', 'Yo-yo': '🪀',
  'Zebra': '🦓', 'Zero': '0️⃣', 'Zip': '🤐',
};
