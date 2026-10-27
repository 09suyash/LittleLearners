class AnimalData {
  final String name;
  final String emoji;
  final String category;
  final String sound; // onomatopoeia spoken by TTS — the quiz tests the sound, not the name
  const AnimalData({required this.name, required this.emoji, required this.category, required this.sound});
}

const List<AnimalData> animals = [
  AnimalData(name: 'Cow',      emoji: '🐮', category: 'farm', sound: 'Moo'),
  AnimalData(name: 'Horse',    emoji: '🐴', category: 'farm', sound: 'Neigh'),
  AnimalData(name: 'Sheep',    emoji: '🐑', category: 'farm', sound: 'Baa'),
  AnimalData(name: 'Pig',      emoji: '🐷', category: 'farm', sound: 'Oink'),
  AnimalData(name: 'Duck',     emoji: '🦆', category: 'farm', sound: 'Quack'),
  AnimalData(name: 'Dog',      emoji: '🐶', category: 'pet', sound: 'Woof Woof'),
  AnimalData(name: 'Cat',      emoji: '🐱', category: 'pet', sound: 'Meow'),
  AnimalData(name: 'Lion',     emoji: '🦁', category: 'wild', sound: 'Roar'),
  AnimalData(name: 'Elephant', emoji: '🐘', category: 'wild', sound: 'Toot Toot'),
  AnimalData(name: 'Monkey',   emoji: '🐵', category: 'wild', sound: 'Ooh Ooh Ah Ah'),
  AnimalData(name: 'Tiger',    emoji: '🐯', category: 'wild', sound: 'Growl'),
  AnimalData(name: 'Bird',     emoji: '🐦', category: 'wild', sound: 'Tweet Tweet'),
  AnimalData(name: 'Snake',    emoji: '🐍', category: 'wild', sound: 'Hiss'),
  AnimalData(name: 'Fish',     emoji: '🐟', category: 'ocean', sound: 'Blub Blub'),
  AnimalData(name: 'Frog',     emoji: '🐸', category: 'ocean', sound: 'Ribbit'),
];
