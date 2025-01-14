import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nwt_reading/src/localization/app_localizations_getter.dart';
import 'package:nwt_reading/src/plans/entities/plans.dart';
import 'package:nwt_reading/src/profile/achievements_list.dart';
import 'package:nwt_reading/src/plans/presentations/plan_edit_dialog.dart';
import 'package:nwt_reading/src/plans/presentations/plans_grid.dart';
import 'package:nwt_reading/src/settings/stories/settings_story.dart';
import 'package:nwt_reading/src/whats_new/presentations/whats_new_dialog.dart';

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
      ref.read(achievementsListProvider.notifier).loadAchievements();
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
              clipBehavior: Clip.none, // Erlaubt dem Badge über den Stack hinauszuragen
              children: [
                IconButton(
                  icon: const CircleAvatar(
                    backgroundImage: AssetImage('assets/images/sheep.jpg'),
                    radius: 16,
                  ),
                  onPressed: () {
                    final plans = ref.read(plansProvider);
                    final selectedPlanId = plans.plans.isNotEmpty ? plans.plans.first.id : null;
                    
                    if (selectedPlanId != null) {
                      Navigator.restorablePushNamed(
                        context, 
                        CharacterProfilePage.routeName,
                        arguments: {'planId': selectedPlanId},
                      );
                    }
                  },
                ),
                Consumer(
                  builder: (context, ref, _) {
                    final availableRewards = ref.watch(availableRewardsProvider);
                    if (availableRewards > 0) {
                      return Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 2,
                            ),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            '$availableRewards',
                            style: const TextStyle(
                              color: Colors.white,
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
                final selectedPlanId = plans.plans.isNotEmpty ? plans.plans.first.id : null;
                
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
              child: PlansGrid(
                key: const Key('plans-grid'),
              ),
            ),
            // Bild unterhalb des Grids hinzufügen
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Image.asset('assets/images/sheep.jpg'),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          tooltip: context.loc.plansPageAddPlanTooltip,
          onPressed: () => showDialog<String>(
            context: context,
            builder: (BuildContext context) => PlanEditDialog(),
          ),
          child: const Icon(Icons.add),
        ),
      );
}
