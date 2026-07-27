import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jw_daily/src/localization/app_localizations_getter.dart';
import 'package:jw_daily/src/plans/entities/plans.dart';
import 'package:jw_daily/src/profile/achievements.dart';
import 'package:jw_daily/src/plans/presentations/plan_edit_dialog.dart';
import 'package:jw_daily/src/plans/presentations/plans_grid.dart';
import 'package:jw_daily/src/settings/stories/settings_story.dart';
import 'package:jw_daily/src/whats_new/presentations/whats_new_dialog.dart';
import 'package:jw_daily/src/profile/profile_utils.dart';

import '../../settings/presentations/settings_page.dart';
import '../../profile/character_profile_page.dart';

class PlansPage extends ConsumerStatefulWidget {
  const PlansPage({super.key});
  static const routeName = '/';

  @override
  PlansPageState createState() => PlansPageState();
}

class PlansPageState extends ConsumerState<PlansPage> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((duration) {
      callWhatsNewDialog(context);
      ref.read(achievementsProvider.notifier).load();
    });
  }

  void callWhatsNewDialog(BuildContext context) async {
    final seenWhatsNewVersion =
        (await ref.read(settingsProvider.future)).seenWhatsNewVersion;

    if (context.mounted) {
      showWhatsNewDialog(context, ref, seenWhatsNewVersion);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(context.loc.plansPageTitle),
          actions: [
            Stack(
              clipBehavior:
                  Clip.none, // Erlaubt dem Badge über den Stack hinauszuragen
              children: [
                Consumer(
                  builder: (context, ref, _) {
                    final characterStats = ref.watch(characterStatsProvider);
                    return IconButton(
                      icon: CircleAvatar(
                        backgroundImage: AssetImage(
                            getSheepImageForLevel(characterStats.level)),
                        radius: 16,
                      ),
                      onPressed: () {
                        final plans = ref.read(plansProvider);
                        final selectedPlanId = plans.plans.isNotEmpty
                            ? plans.plans.first.id
                            : null;

                        if (selectedPlanId != null) {
                          Navigator.restorablePushNamed(
                            context,
                            CharacterProfilePage.routeName,
                            arguments: {'planId': selectedPlanId},
                          );
                        }
                      },
                    );
                  },
                ),
                Consumer(
                  builder: (context, ref, _) {
                    final availableRewards =
                        ref.watch(availableRewardsProvider);
                    final colorScheme = Theme.of(context).colorScheme;
                    if (availableRewards > 0) {
                      return Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: colorScheme.error,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: colorScheme.surface,
                              width: 2,
                            ),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            '$availableRewards',
                            style: TextStyle(
                              color: colorScheme.onError,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                final plans = ref.read(plansProvider);
                final selectedPlanId =
                    plans.plans.isNotEmpty ? plans.plans.first.id : null;

                Navigator.restorablePushNamed(
                  context,
                  SettingsPage.routeName,
                  arguments: {'planId': selectedPlanId},
                );
              },
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: const PlansGrid(key: Key('plans-grid')),
            ),
            // Bild unterhalb des Grids hinzufügen
            Consumer(
              builder: (context, ref, _) {
                final characterStats = ref.watch(characterStatsProvider);
                return Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Image.asset(
                    getSheepImageForLevel(characterStats.level),
                  ),
                );
              },
            ),
          ],
        ),
        // Only one plan is supported, and creating a second one would silently
        // replace the first including its progress. Offer it only while there
        // is none — an existing plan is changed through its edit dialog.
        floatingActionButton: ref.watch(plansProvider).plans.isNotEmpty
            ? null
            : FloatingActionButton(
                tooltip: context.loc.plansPageAddPlanTooltip,
                onPressed: () => showDialog<String>(
                  context: context,
                  builder: (BuildContext context) => PlanEditDialog(),
                ),
                child: const Icon(Icons.add),
              ),
      );
}
