import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nwt_reading/src/plans/stories/plan_edit_story.dart';

class PlanShowBibleVersesTile extends ConsumerWidget {
  const PlanShowBibleVersesTile(this.planId, {super.key});

  final String? planId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref.watch(planEditProviderFamily(planId));
    ref.watch(planEditProviderFamily(planId));
    final planEdit = ref.read(planEditProviderFamily(planId).notifier);

    return ListTile(
      title: const Text('Bibelverse erklärt'),
      subtitle:
          const Text('Zeige in den Abschnitten die Bibelvers Erklärung an.'),
      trailing: Switch(
        key: const Key('show-bible-verses'),
        value: plan.showBibleVerses,
        onChanged: (bool value) {
          planEdit.updateShowBibleVerses(value);
        },
      ),
    );
  }
}
