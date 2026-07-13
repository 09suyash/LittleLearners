class AnimalData {
  final String name;
  final String emoji;
  final String category;
  const AnimalData({required this.name, required this.emoji, required this.category});
}

const List<AnimalData> animals = [
  AnimalData(name: 'Cow',      emoji: '🐮', category: 'farm'),
  AnimalData(name: 'Horse',    emoji: '🐴', category: 'farm'),
  AnimalData(name: 'Sheep',    emoji: '🐑', category: 'farm'),
  AnimalData(name: 'Pig',      emoji: '🐷', category: 'farm'),
  AnimalData(name: 'Duck',     emoji: '🦆', category: 'farm'),
  AnimalData(name: 'Dog',      emoji: '🐶', category: 'pet'),
  AnimalData(name: 'Cat',      emoji: '🐱', category: 'pet'),
  AnimalData(name: 'Lion',     emoji: '🦁', category: 'wild'),
  AnimalData(name: 'Elephant', emoji: '🐘', category: 'wild'),
  AnimalData(name: 'Monkey',   emoji: '🐵', category: 'wild'),
  AnimalData(name: 'Tiger',    emoji: '🐯', category: 'wild'),
  AnimalData(name: 'Bird',     emoji: '🐦', category: 'wild'),
  AnimalData(name: 'Snake',    emoji: '🐍', category: 'wild'),
  AnimalData(name: 'Fish',     emoji: '🐟', category: 'ocean'),
  AnimalData(name: 'Frog',     emoji: '🐸', category: 'ocean'),
];
