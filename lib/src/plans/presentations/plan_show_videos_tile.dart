import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jw_daily/src/localization/app_localizations_getter.dart';
import 'package:jw_daily/src/plans/stories/plan_edit_story.dart';

class PlanShowVideosTile extends ConsumerWidget {
  const PlanShowVideosTile(this.planId, {super.key});

  final String? planId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref.watch(planEditProviderFamily(planId));
    ref.watch(planEditProviderFamily(planId));
    final planEdit = ref.read(planEditProviderFamily(planId).notifier);

    return ListTile(
      title: Text(context.loc.planEditPageShowVideosTitle),
      subtitle: Text(context.loc.planEditPageShowVideosSubtitle),
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
