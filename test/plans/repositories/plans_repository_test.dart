import 'package:collection/collection.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:jw_daily/src/base/repositories/shared_preferences_repository.dart';
import 'package:jw_daily/src/plans/entities/plans.dart';
import 'package:jw_daily/src/plans/repositories/plans_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../notifier_tester.dart';
import '../../test_data.dart';

Future<NotifierTester<Plans>> getTester(
    [Map<String, Object> preferences = const {}]) async {
  SharedPreferences.setMockInitialValues(preferences);
  final sharedPreferences = await SharedPreferences.getInstance();

  final tester = NotifierTester<Plans>(plansProvider, overrides: [
    sharedPreferencesRepositoryProvider
        .overrideWith((ref) => sharedPreferences),
  ]);
  addTearDown(tester.container.dispose);

  return tester;
}

void main() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  final emptyPlans = Plans(const []);
  final deepCollectionEquals = const DeepCollectionEquality().equals;
  setUpAll(() {
    registerFallbackValue(emptyPlans);
  });

  test('Defaults to the empty entity', () async {
    final tester = await getTester();
    tester.container.read(plansRepositoryProvider);
    final result = tester.container.read(plansProvider);

    expect(deepCollectionEquals(result.plans, emptyPlans.plans), true);
    verifyInOrder([
      () => tester.listener(null, result),
    ]);
    verifyNoMoreInteractions(tester.listener);
  });

  test('Imports legacy settings', () async {
    for (var testLegacyExport in [testLegacyExports[1]]) {
      final tester = await getTester(testLegacyExport.preferences);
      final initialPlans = tester.container.read(plansProvider);
      tester.container.read(plansRepositoryProvider).load();
      final result = tester.container.read(plansProvider);

      expect(deepCollectionEquals(result.plans, testLegacyExport.plans.plans),
          true);
      verifyInOrder([
        () => tester.listener(null, initialPlans),
        () => tester.listener(initialPlans, result),
      ]);
      verifyNoMoreInteractions(tester.listener);
    }
  });

  test('Resolves to Shared Preferences', () async {
    final tester = await getTester(testPlansPreferences);
    tester.container.read(plansRepositoryProvider).load();
    final result = tester.container.read(plansProvider);

    expect(deepCollectionEquals(result.plans, testPlans.plans), true);
  });

  test('Adding a plan replaces the previous one', () async {
    final tester = await getTester();
    tester.container.read(plansRepositoryProvider);
    List<Plans> results = [await tester.container.read(plansProvider)];
    for (var plan in testPlans.plans) {
      tester.container.read(plansProvider.notifier).addPlan(plan);
      results.add(await tester.container.read(plansProvider));
    }

    // Only a single plan is supported, so the last one added is the only one
    // that survives.
    expect(
        deepCollectionEquals(results[4].plans, [testPlans.plans.last]), true);
    verifyInOrder([
      () => tester.listener(null, results[0]),
      () => tester.listener(results[0], results[1]),
      () => tester.listener(results[1], results[2]),
      () => tester.listener(results[2], results[3]),
      () => tester.listener(results[3], results[4]),
    ]);
    verifyNoMoreInteractions(tester.listener);
  });

  test('Setting plans keeps all of them', () async {
    final tester = await getTester();
    tester.container.read(plansRepositoryProvider);
    tester.container.read(plansProvider.notifier).setPlans(testPlans);

    expect(
        deepCollectionEquals(
            tester.container.read(plansProvider).plans, testPlans.plans),
        true);
  });

  test('Shared Preferences are set to updated value', () async {
    final tester = await getTester();
    tester.container.read(plansRepositoryProvider);
    for (var plan in testPlans.plans) {
      tester.container.read(plansProvider.notifier).addPlan(plan);
    }
    final actualPlansSerialized = tester.container
        .read(sharedPreferencesRepositoryProvider)
        .getStringList(plansPreferenceKey);

    expect(actualPlansSerialized, [testPlansSerialized.last]);
  });
}
