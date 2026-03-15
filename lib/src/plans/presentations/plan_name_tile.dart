import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nwt_reading/src/base/presentation/plan.dart';
import 'package:nwt_reading/src/localization/app_localizations_getter.dart';
import 'package:nwt_reading/src/plans/stories/plan_edit_story.dart';

class PlanNameTile extends ConsumerWidget {
  const PlanNameTile(this.planId, {super.key});

  final String? planId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref.watch(planEditProviderFamily(planId));
    final planName = getPlanName(context, plan);
    final planEdit = ref.read(planEditProviderFamily(planId).notifier);

    return ListTile(
        title: TextFormField(
      key: const Key('plan-name'),
      autofillHints: const ['plan-name'],
      autofocus: true,
      initialValue: planName,
      decoration:
          InputDecoration(hintText: context.loc.planNameHint),
      onChanged: (name) =>
          (name != planName) ? planEdit.changeName(name) : null,
    ));
  }
}
