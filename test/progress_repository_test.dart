import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zoodles/core/core.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final p = await SharedPreferences.getInstance();
    await p.clear();
  });

  group('ProgressRepository Tests', () {
    test('Child name persistence', () async {
      final repo = ProgressRepository();
      expect(await repo.getChildName(), isEmpty);

      await repo.setChildName('Aarav');
      expect(await repo.getChildName(), equals('Aarav'));
      expect(AppState.childName, equals('Aarav'));
    });

    test('Parent PIN persistence and removal', () async {
      final repo = ProgressRepository();
      expect(await repo.getParentPin(), isNull);

      await repo.setParentPin('1234');
      expect(await repo.getParentPin(), equals('1234'));

      await repo.removeParentPin();
      expect(await repo.getParentPin(), isNull);
    });

    test('ABC progress saving and reading', () async {
      final repo = ProgressRepository();
      expect(await repo.getAbcLearnedLetters(), isEmpty);
      expect(await repo.getAbcLearnedCount(), equals(0));

      await repo.saveAbcProgress(
        learnedLetters: ['A', 'B', 'C'],
        quizBest: 8,
      );

      expect(await repo.getAbcLearnedLetters(), equals(['A', 'B', 'C']));
      expect(await repo.getAbcLearnedCount(), equals(3));
      expect(await repo.getAbcQuizBest(), equals(8));
    });

    test('Math quiz and blitz score logic', () async {
      final repo = ProgressRepository();
      expect(await repo.getMathBest(), equals(-1));

      // First score
      final saved1 = await repo.saveMathScore(score: 7, total: 10);
      expect(saved1, isTrue);
      expect(await repo.getMathBest(), equals(7));

      // Lower score should not overwrite best
      final saved2 = await repo.saveMathScore(score: 5, total: 10);
      expect(saved2, isFalse);
      expect(await repo.getMathBest(), equals(7));

      // Blitz score updates
      final blitzBest = await repo.saveBlitzScore(15);
      expect(blitzBest, equals(15));
      expect(await repo.getBlitzBest(), equals(15));
    });

    test('Stories completion tracking', () async {
      final repo = ProgressRepository();
      expect(await repo.getCompletedStoryIds(), isEmpty);

      await repo.markStoryCompleted(0);
      await repo.markStoryCompleted(1);
      expect(await repo.getCompletedStoryIds(), containsAll(['0', '1']));
    });

    test('Explorer badge milestone check', () async {
      final repo = ProgressRepository();
      expect(await repo.hasExploredAllApps(), isFalse);

      await repo.saveAbcProgress(learnedLetters: ['A']);
      expect(await repo.hasExploredAllApps(), isFalse);

      await repo.saveMathScore(score: 1, total: 10);
      expect(await repo.hasExploredAllApps(), isFalse);

      await repo.markStoryCompleted(0);
      expect(await repo.hasExploredAllApps(), isTrue);
    });

    test('Progress overview reflects saved stats', () async {
      final repo = ProgressRepository();
      await repo.setChildName('Kavya');
      await repo.saveAbcProgress(learnedLetters: ['A', 'B', 'C', 'D']);
      await repo.saveMathScore(score: 9, total: 10);
      await repo.saveBlitzScore(18);
      await repo.markStoryCompleted(2);

      final overview = await repo.getOverview();
      expect(overview.childName, equals('Kavya'));
      expect(overview.abcLearned, equals(4));
      expect(overview.mathBest, equals(9));
      expect(overview.mathBestTotal, equals(10));
      expect(overview.blitzBest, equals(18));
      expect(overview.storiesRead, equals(1));
    });
  });
}
