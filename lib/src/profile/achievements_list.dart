import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  final String? planId = firstPlan?.id;

  if (planId == null) return false;

  final planNotifier = ref.read(planProviderFamily(planId).notifier);
  final deviationDays = planNotifier.getDeviationDays();

  // Wenn wir hinterher sind, ist keine Lesung gemacht
  if (deviationDays > 0) return false;

  // Prüfe den aktuellen Tag
  final plan = ref.watch(planProviderFamily(planId));

  final currentDayIndex = plan.bookmark.dayIndex;
  final currentSectionIndex = plan.bookmark.sectionIndex;

  // Prüfe ob alle Sections des heutigen Tages gelesen wurden
  bool allSectionsRead = true;
  for (int sectionIndex = 0; sectionIndex <= currentSectionIndex; sectionIndex++) {
    if (!planNotifier.isRead(dayIndex: currentDayIndex, sectionIndex: sectionIndex)) {
      allSectionsRead = false;
      break;
    }
  }

  // Nur true wenn wir nicht hinterher sind UND alle Sections gelesen wurden
  return deviationDays <= 0 && allSectionsRead;
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
      ref.read(achievementsListProvider.notifier).loadAchievements();
      _updateAchievements();
    });
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

            return Card(
                color: achievement.title == 'Tägliche Bibellesung'
                    ? (achievement.canClaimDailyReward(hasReadToday) ? Colors.white : Colors.grey[300])
                    : (achievement.isCompleted 
                        ? (achievement.isRewardClaimed ? Colors.grey[300] : Colors.white) 
                        : Colors.grey[300]),
                child: ListTile(
                  leading: Icon(
                    achievement.isRewardClaimed 
                        ? Icons.check_circle 
                        : achievement.icon,
                    color: achievement.title == 'Tägliche Bibellesung'
                        ? (achievement.canClaimDailyReward(hasReadToday) ? Colors.blue : Colors.grey)
                        : (achievement.isCompleted 
                            ? (achievement.isRewardClaimed ? Colors.grey : Colors.blue)
                            : Colors.grey),
                ),
                title: Text(
                  achievement.title,
                  style: TextStyle(
                    color: achievement.title == 'Tägliche Bibellesung'
                        ? (achievement.canClaimDailyReward(hasReadToday) ? Colors.black : Colors.grey)
                        : (achievement.isRewardClaimed ? Colors.grey : Colors.black),
                  ),
                ),
                trailing: (achievement.isCompleted && !achievement.isRewardClaimed) ||
                          achievement.canClaimDailyReward(hasReadToday)
                    ? Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.green.shade400,
                              Colors.green.shade700,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ElevatedButton(
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
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                          child: const Text(
                            'Belohnung abholen',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      )
                    : null,
              ),
            );
          },
        );
      },
      loading: () => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
            SizedBox(height: 16),
            Text(
              'Lade Erfolge...',
              style: TextStyle(
                color: Colors.blue,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      error: (error, stack) => Center(
        child: Card(
          margin: EdgeInsets.all(16),
          color: Colors.red.shade50,
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 48,
                ),
                SizedBox(height: 16),
                Text(
                  'Ein Fehler ist aufgetreten',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.red.shade700,
                  ),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    ref.invalidate(scheduleProviderFamily(plan.scheduleKey));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  child: Text(
                    'Erneut versuchen',
                    style: TextStyle(color: Colors.white),
                  ),
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

    // Tage hintereinander gelesen
    int consecutiveDays = 0;
    for (int i = bookmark.dayIndex; i >= 0; i--) {
      if (i <= bookmark.dayIndex) {
        consecutiveDays++;
      } else {
        break;
      }
    }

    if (consecutiveDays >= 3) {
      updateAchievement(updatedAchievements, '3 Tage hintereinander gelesen', true);
    }
    if (consecutiveDays >= 7) {
      updateAchievement(updatedAchievements, '7 Tage hintereinander gelesen', true);
    }
    if (consecutiveDays >= 10) {
      updateAchievement(updatedAchievements, '10 Tage hintereinander gelesen', true);
    }

    // Kapitel abgeschlossen
    int completedChapters = bookmark.dayIndex * schedule.days[0].sections.length + bookmark.sectionIndex + 1;
    if (completedChapters >= 1) {
      updateAchievement(updatedAchievements, 'Erstes Kapitel abgeschlossen', true);
    }
    if (completedChapters >= 5) {
      updateAchievement(updatedAchievements, '5 Kapitel abgeschlossen', true);
    }

    // Bücher abgeschlossen
    int completedBooks = 0;
    // Logik für abgeschlossene Bücher
    if (completedBooks >= 1) {
      updateAchievement(updatedAchievements, 'Erstes Buch abgeschlossen', true);
    }
    if (completedBooks >= 5) {
      updateAchievement(updatedAchievements, '5 Bücher abgeschlossen', true);
    }

    // Monate abgeschlossen
    int completedMonths = 0;
    // Logik für abgeschlossene Monate
    if (completedMonths >= 1) {
      updateAchievement(updatedAchievements, 'Erster Monat abgeschlossen', true);
    }
    if (completedMonths >= 3) {
      updateAchievement(updatedAchievements, '3 Monate abgeschlossen', true);
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
      final prefs = await SharedPreferences.getInstance();
      final achievementsData = state.map((achievement) => {
        'title': achievement.title,
        'isCompleted': achievement.isCompleted,
        'isRewardClaimed': achievement.isRewardClaimed,
        'lastRewardClaimed': achievement.lastRewardClaimed?.toIso8601String(),
      }).toList();
      
      await prefs.setString('achievements', jsonEncode(achievementsData));
    } catch (e) {
      print('Fehler beim Speichern der Achievements: $e');
    }
  }

  Future<void> loadAchievements() async {
    try {
      final prefs = await SharedPreferences.getInstance();
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
      print('Fehler beim Laden der Achievements: $e');
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