import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nwt_reading/src/plans/stories/plan_edit_story.dart';

class PlanShowVideosTile extends ConsumerWidget {
  const PlanShowVideosTile(this.planId, {super.key});

  final String? planId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref.watch(planEditProviderFamily(planId));
    ref.watch(planEditProviderFamily(planId));
    final planEdit = ref.read(planEditProviderFamily(planId).notifier);

    return ListTile(
      title: const Text('Einführungsvideos'),
      subtitle:
          const Text('Zeige in den Abschnitten die Einführungsvideos an.'),
      trailing: Switch(
        key: const Key('show-videos'),
        value: plan.showVideos,
        onChanged: (bool value) {
          planEdit.updateShowVideos(value);
        },
      ),
    );
  }
}
