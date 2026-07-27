import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jw_daily/src/localization/app_localizations_getter.dart';
import 'package:jw_daily/src/plans/entities/plan.dart';
import 'package:jw_daily/src/profile/achievements.dart';
import 'package:jw_daily/src/schedules/entities/schedule.dart';

String achievementTitle(BuildContext context, AchievementId id) => switch (id) {
      AchievementId.firstReading => context.loc.achievementFirstReading,
      AchievementId.dailyReading => context.loc.achievementDailyReading,
      AchievementId.streak3 => context.loc.achievementStreak3,
      AchievementId.streak7 => context.loc.achievementStreak7,
      AchievementId.streak10 => context.loc.achievementStreak10,
      AchievementId.firstChapter => context.loc.achievementFirstChapter,
      AchievementId.chapters5 => context.loc.achievementChapters5,
      AchievementId.firstBook => context.loc.achievementFirstBook,
      AchievementId.books5 => context.loc.achievementBooks5,
      AchievementId.firstMonth => context.loc.achievementFirstMonth,
      AchievementId.months3 => context.loc.achievementMonths3,
    };

class AchievementsListWidget extends ConsumerStatefulWidget {
  const AchievementsListWidget({
    required this.planId,
    required this.onRewardClaimed,
    super.key,
  });

  final String planId;
  final void Function(int amount, BuildContext context) onRewardClaimed;

  @override
  ConsumerState<AchievementsListWidget> createState() =>
      _AchievementsListWidgetState();
}

class _AchievementsListWidgetState
    extends ConsumerState<AchievementsListWidget> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Wait for the stored achievements before recomputing, otherwise the
      // asynchronously loaded state would overwrite the result.
      await ref.read(achievementsProvider.notifier).load();
      if (!mounted) return;
      final plan = ref.read(planProviderFamily(widget.planId));
      final schedule =
          ref.read(scheduleProviderFamily(plan.scheduleKey)).valueOrNull;
      ref.read(achievementsProvider.notifier).recompute(plan, schedule);
    });
  }

  @override
  Widget build(BuildContext context) {
    final plan = ref.watch(planProviderFamily(widget.planId));
    final asyncSchedule = ref.watch(scheduleProviderFamily(plan.scheduleKey));
    final hasReadToday = ref.watch(hasReadTodayProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return switch (asyncSchedule) {
      AsyncValue(hasValue: true) => _buildList(context, hasReadToday),
      AsyncValue(hasError: true) => Center(
          child: Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, color: colorScheme.error, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    context.loc.errorGenericMessage,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => ref
                        .invalidate(scheduleProviderFamily(plan.scheduleKey)),
                    child: Text(context.loc.errorRetryButton),
                  ),
                ],
              ),
            ),
          ),
        ),
      _ => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(context.loc.achievementsListLoading),
            ],
          ),
        ),
    };
  }

  Widget _buildList(BuildContext context, bool hasReadToday) {
    final achievements = ref.watch(achievementsProvider).achievements;
    final colorScheme = Theme.of(context).colorScheme;

    return ListView.builder(
      itemCount: achievements.length,
      itemBuilder: (context, index) {
        final achievement = achievements[index];
        final isDaily = achievement.id == AchievementId.dailyReading;
        final canClaim = isDaily
            ? achievement.canClaimDailyReward(hasReadToday)
            : achievement.canClaimReward;
        final isEarned = isDaily ? canClaim : achievement.isCompleted;

        return Card(
          color: canClaim
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHighest,
          child: ListTile(
            leading: Icon(
              !isDaily && achievement.isRewardClaimed
                  ? Icons.check_circle
                  : achievement.icon,
              color:
                  isEarned ? colorScheme.primary : colorScheme.onSurfaceVariant,
            ),
            title: Text(
              achievementTitle(context, achievement.id),
              style: TextStyle(
                color: isEarned
                    ? colorScheme.onSurface
                    : colorScheme.onSurfaceVariant,
              ),
            ),
            trailing: canClaim
                ? FilledButton(
                    onPressed: () {
                      if (isDaily) {
                        ref
                            .read(achievementsProvider.notifier)
                            .claimDailyReward();
                      } else {
                        ref
                            .read(achievementsProvider.notifier)
                            .claimReward(achievement.id);
                      }
                      widget.onRewardClaimed(
                          achievementXP[achievement.id] ?? 0, context);
                    },
                    child: Text(context.loc.achievementsListClaimRewardButton),
                  )
                : null,
          ),
        );
      },
    );
  }
}
