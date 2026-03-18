import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nwt_reading/src/localization/app_localizations_getter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math';
import 'package:nwt_reading/src/plans/entities/plan.dart';
import 'package:nwt_reading/src/plans/entities/plans.dart';
import 'package:nwt_reading/src/schedules/entities/schedule.dart';

final achievementsListProvider = StateNotifierProvider<AchievementsListNotifier, List<Achievement>>((ref) {
  return AchievementsListNotifier();
});

final dailyReadingStatusProvider = Provider<bool>((ref) {
  final Plans plans = ref.watch(plansProvider);
  final Plan? firstPlan = plans.plans.firstOrNull;
  if (firstPlan == null) return false;

  final plan = ref.watch(planProviderFamily(firstPlan.id));

  // Prüfe ob heute gelesen wurde anhand von lastDate
  return plan.lastDate != null &&
      DateUtils.isSameDay(plan.lastDate!, DateTime.now());
});

final availableRewardsProvider = Provider<int>((ref) {
  final achievements = ref.watch(achievementsListProvider);
  return achievements.where((a) => a.isCompleted && !a.isRewardClaimed).length;
});

final Map<String, int> achievementXP = {
  'Erste Bibellesung': 50,
  '3 Tage hintereinander gelesen': 75,
  '7 Tage hintereinander gelesen': 150,
  '10 Tage hintereinander gelesen': 250,
  'Erstes Kapitel abgeschlossen': 50,
  '5 Kapitel abgeschlossen': 150,
  'Erstes Buch abgeschlossen': 200,
  '5 Bücher abgeschlossen': 300,
  'Erster Monat abgeschlossen': 250,
  '3 Monate abgeschlossen': 400
};

int getRequiredXPForLevel(int level) {
  return (100 * pow(1.2, level - 1)).round();
}

class AchievementsListWidget extends ConsumerStatefulWidget {
  final String planId;
  final void Function(int, BuildContext) onRewardClaimed; 

  const AchievementsListWidget({
    required this.planId,
    required this.onRewardClaimed,
    super.key,
  });

  @override
  _AchievementsListWidgetState createState() => _AchievementsListWidgetState();
}

class _AchievementsListWidgetState extends ConsumerState<AchievementsListWidget> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(achievementsListProvider.notifier).loadAchievements();
      _updateAchievements();
    });
  }

  String? _getProgressText(Achievement achievement, Plan plan, Schedule schedule) {
    if (achievement.isCompleted) return null;

    final readingDays = plan.bookmark.dayIndex;

    // Streak-Fortschritt
    if (achievement.title == '3 Tage hintereinander gelesen') {
      return '$readingDays / 3';
    }
    if (achievement.title == '7 Tage hintereinander gelesen') {
      return '$readingDays / 7';
    }
    if (achievement.title == '10 Tage hintereinander gelesen') {
      return '$readingDays / 10';
    }

    // Kapitel-Fortschritt
    int completedChapters = 0;
    for (var i = 0; i < plan.bookmark.dayIndex && i < schedule.days.length; i++) {
      completedChapters += schedule.days[i].sections.length;
    }
    if (plan.bookmark.dayIndex < schedule.days.length) {
      completedChapters += plan.bookmark.sectionIndex + 1;
    }

    if (achievement.title == '5 Kapitel abgeschlossen') {
      return '$completedChapters / 5';
    }

    return null;
  }

  void _updateAchievements() {
    final plan = ref.read(planProviderFamily(widget.planId));
    final schedule = ref.read(scheduleProviderFamily(plan.scheduleKey)).valueOrNull;
    if (schedule != null) {
      ref.read(achievementsListProvider.notifier)
          .updateAchievementsBasedOnReading(plan, schedule);
    }
  }

  @override
  Widget build(BuildContext context) {
    final plan = ref.watch(planProviderFamily(widget.planId));
    final scheduleAsyncValue = ref.watch(scheduleProviderFamily(plan.scheduleKey));
    final hasReadToday = ref.watch(dailyReadingStatusProvider);

    return scheduleAsyncValue.when(
      data: (schedule) {
        final achievements = ref.watch(achievementsListProvider);

        return ListView.builder(
          itemCount: achievements.length,
          itemBuilder: (context, index) {
            final achievement = achievements[index];

            final colorScheme = Theme.of(context).colorScheme;
            final isActive = achievement.title == 'Tägliche Bibellesung'
                ? achievement.canClaimDailyReward(hasReadToday)
                : (achievement.isCompleted && !achievement.isRewardClaimed);
            final isDone = achievement.title == 'Tägliche Bibellesung'
                ? !achievement.canClaimDailyReward(hasReadToday)
                : (!achievement.isCompleted || achievement.isRewardClaimed);

            // Fortschrittstext für Streak-Achievements
            final progressText = _getProgressText(achievement, plan, schedule);

            return Card(
                color: isDone
                    ? colorScheme.surfaceContainerHighest
                    : colorScheme.surface,
                child: ListTile(
                  leading: Icon(
                    achievement.isRewardClaimed
                        ? Icons.check_circle
                        : achievement.icon,
                    color: isActive
                        ? colorScheme.primary
                        : colorScheme.outline,
                ),
                title: Text(
                  achievement.title,
                  style: TextStyle(
                    color: isDone
                        ? colorScheme.outline
                        : colorScheme.onSurface,
                  ),
                ),
                subtitle: progressText != null && !achievement.isRewardClaimed
                    ? Text(
                        progressText,
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.outline,
                        ),
                      )
                    : null,
                trailing: (achievement.isCompleted && !achievement.isRewardClaimed) ||
                          achievement.canClaimDailyReward(hasReadToday)
                    ? Container(
                        FilledButton(
                          onPressed: () {
                            if (achievement.title == 'Tägliche Bibellesung') {
                              ref.read(achievementsListProvider.notifier)
                                  .claimDailyReward(achievement.title);
                              widget.onRewardClaimed(10, context);
                            } else {
                              ref.read(achievementsListProvider.notifier)
                                  .claimReward(achievement.title);
                              widget.onRewardClaimed(
                                achievementXP[achievement.title] ?? 0,
                                context
                              );
                            }
                          },
                          child: Text(
                            '+${achievement.title == 'Tägliche Bibellesung' ? 10 : achievementXP[achievement.title] ?? 0} XP',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                    : null,
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Card(
          margin: const EdgeInsets.all(16),
          color: Theme.of(context).colorScheme.errorContainer,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  color: Theme.of(context).colorScheme.error,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  MaterialLocalizations.of(context).alertDialogLabel,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () {
                    ref.invalidate(scheduleProviderFamily(plan.scheduleKey));
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AchievementsListNotifier extends StateNotifier<List<Achievement>> {
  SharedPreferences? _prefs;

  AchievementsListNotifier()
      : super([
          Achievement('Erste Bibellesung', Icons.book, false),
          Achievement('Tägliche Bibellesung', Icons.auto_stories, false, isRewardClaimed: false),
          Achievement('3 Tage hintereinander gelesen', Icons.calendar_today, false),
          Achievement('7 Tage hintereinander gelesen', Icons.calendar_view_week, false),
          Achievement('10 Tage hintereinander gelesen', Icons.calendar_view_month, false),
          Achievement('Erstes Kapitel abgeschlossen', Icons.check_circle, false),
          Achievement('5 Kapitel abgeschlossen', Icons.check_circle_outline, false),
          Achievement('Erstes Buch abgeschlossen', Icons.library_books, false),
          Achievement('5 Bücher abgeschlossen', Icons.library_books_outlined, false),
          Achievement('Erster Monat abgeschlossen', Icons.date_range, false),
          Achievement('3 Monate abgeschlossen', Icons.event, false),
        ]) {
    loadAchievements();
  }

  void updateDailyReadingStatus(int deviationDays) {
    state = [
      for (final achievement in state)
        if (achievement.title == 'Tägliche Bibellesung')
          Achievement(
            achievement.title,
            achievement.icon,
            deviationDays <= 0, 
            isRewardClaimed: achievement.isRewardClaimed,
            lastRewardClaimed: achievement.lastRewardClaimed,
          )
        else
          achievement,
    ];
  }

  void updateAchievementsBasedOnReading(Plan plan, Schedule schedule) {
    final bookmark = plan.bookmark;
    List<Achievement> updatedAchievements = [...state];

    // Erste Bibellesung
    if (bookmark.dayIndex >= 0 && bookmark.sectionIndex >= 0) {
      updateAchievement(updatedAchievements, 'Erste Bibellesung', true);
    }

    // TODO: dayIndex tracks schedule position, not actual consecutive calendar days.
    final readingDaysCompleted = bookmark.dayIndex;

    if (readingDaysCompleted >= 3) {
      updateAchievement(updatedAchievements, '3 Tage hintereinander gelesen', true);
    }
    if (readingDaysCompleted >= 7) {
      updateAchievement(updatedAchievements, '7 Tage hintereinander gelesen', true);
    }
    if (readingDaysCompleted >= 10) {
      updateAchievement(updatedAchievements, '10 Tage hintereinander gelesen', true);
    }

    // Kapitel abgeschlossen - zähle tatsächliche Sections über alle Tage
    int completedChapters = 0;
    for (var i = 0; i < bookmark.dayIndex && i < schedule.days.length; i++) {
      completedChapters += schedule.days[i].sections.length;
    }
    if (bookmark.dayIndex < schedule.days.length) {
      completedChapters += bookmark.sectionIndex + 1;
    }
    if (completedChapters >= 1) {
      updateAchievement(updatedAchievements, 'Erstes Kapitel abgeschlossen', true);
    }
    if (completedChapters >= 5) {
      updateAchievement(updatedAchievements, '5 Kapitel abgeschlossen', true);
    }

    state = updatedAchievements;
    _saveAchievements();
  }

  void updateAchievement(List<Achievement> achievements, String title, bool completed) {
    final index = achievements.indexWhere((a) => a.title == title);
    if (index != -1) {
      achievements[index] = Achievement(
        title,
        achievements[index].icon,
        completed,
        isRewardClaimed: achievements[index].isRewardClaimed,
      );
    }
  }

  void applyAndSave(List<Achievement> achievements) {
    state = achievements;
    _saveAchievements();
  }

  void claimReward(String achievementTitle) {
    state = [
      for (final achievement in state)
        if (achievement.title == achievementTitle)
          Achievement(
            achievement.title,
            achievement.icon,
            achievement.isCompleted,
            isRewardClaimed: true,
          )
        else
          achievement,
    ];
    
    _saveAchievements();
  }

  void claimDailyReward(String achievementTitle) {
    state = [
      for (final achievement in state)
        if (achievement.title == achievementTitle)
          Achievement(
            achievement.title,
            achievement.icon,
            achievement.isCompleted,
            isRewardClaimed: false,
            lastRewardClaimed: DateTime.now(),
          )
        else
          achievement,
    ];
    _saveAchievements();
  }

  Future<void> _saveAchievements() async {
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      final achievementsData = state.map((achievement) => {
        'title': achievement.title,
        'isCompleted': achievement.isCompleted,
        'isRewardClaimed': achievement.isRewardClaimed,
        'lastRewardClaimed': achievement.lastRewardClaimed?.toIso8601String(),
      }).toList();
      
      await prefs.setString('achievements', jsonEncode(achievementsData));
    } catch (e) {
      debugPrint('Fehler beim Speichern der Achievements: $e');
    }
  }

  Future<void> loadAchievements() async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
      final prefs = _prefs!;
      final achievementsString = prefs.getString('achievements');
      
      if (achievementsString != null) {
        final achievementsData = jsonDecode(achievementsString) as List;
        final loadedAchievements = achievementsData.map((data) {
          final title = data['title'] as String;
          final lastRewardClaimedStr = data['lastRewardClaimed'] as String?;
          final existingAchievement = state.firstWhere(
            (a) => a.title == title,
            orElse: () => Achievement(title, Icons.star, false),
          );
          
          return Achievement(
            title,
            existingAchievement.icon,
            data['isCompleted'] as bool,
            isRewardClaimed: data['isRewardClaimed'] as bool,
            lastRewardClaimed: lastRewardClaimedStr != null 
                ? DateTime.parse(lastRewardClaimedStr)
                : null,
          );
        }).toList();

        state = loadedAchievements;
      }
    } catch (e) {
      debugPrint('Fehler beim Laden der Achievements: $e');
    }
  }
}

class Achievement {
  final String title;
  final IconData icon;
  final bool isCompleted;
  final bool isRewardClaimed;
  final DateTime? lastRewardClaimed;

  Achievement(this.title, this.icon, this.isCompleted, {this.isRewardClaimed = false, this.lastRewardClaimed});

  bool canClaimDailyReward(bool hasReadToday) {
    if (title != 'Tägliche Bibellesung') return false;
    
    // Nur wenn heute wirklich gelesen wurde
    if (!hasReadToday) return false;
    
    // Prüfe ob heute schon eine Belohnung geholt wurde
    if (lastRewardClaimed != null) {
      final now = DateTime.now();
      if (DateUtils.isSameDay(now, lastRewardClaimed!)) {
        return false;
      }
    }
    
    return true; 
  }
}