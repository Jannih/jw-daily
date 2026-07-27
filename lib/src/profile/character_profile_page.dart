import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jw_daily/src/localization/app_localizations_getter.dart';
import 'package:jw_daily/src/plans/entities/plan.dart';
import 'package:jw_daily/src/profile/achievements.dart';
import 'package:jw_daily/src/profile/achievements_list.dart';
import 'package:jw_daily/src/profile/level_up_dialog.dart';
import 'package:jw_daily/src/utils/date_utils.dart' as app_date_utils;
import 'package:shared_preferences/shared_preferences.dart';

import 'sheep_pasture_game.dart';

const _namePreferenceKey = 'character_name';
const _xpPreferenceKey = 'character_xp';
const _levelPreferenceKey = 'character_level';
const _penaltyCheckPreferenceKey = 'last_penalty_check';

@immutable
class CharacterStats {
  const CharacterStats({required this.xp, required this.level});

  final int xp;
  final int level;
}

final characterStatsProvider =
    StateNotifierProvider<CharacterStatsNotifier, CharacterStats>(
        (ref) => CharacterStatsNotifier(),
        name: 'characterStatsProvider');

class CharacterStatsNotifier extends StateNotifier<CharacterStats> {
  CharacterStatsNotifier() : super(const CharacterStats(xp: 0, level: 1)) {
    _loadStats();
  }

  Future<void> _loadStats() async {
    final preferences = await SharedPreferences.getInstance();
    state = CharacterStats(
      xp: preferences.getInt(_xpPreferenceKey) ?? 0,
      level: preferences.getInt(_levelPreferenceKey) ?? 1,
    );
  }

  Future<void> _saveStats() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setInt(_xpPreferenceKey, state.xp);
    await preferences.setInt(_levelPreferenceKey, state.level);
  }

  /// Adds experience and returns the new level if the character levelled up.
  int? increaseXP(int amount) {
    final oldLevel = state.level;
    var newXP = state.xp + amount;
    var newLevel = state.level;

    while (newXP >= getRequiredXPForLevel(newLevel)) {
      newXP -= getRequiredXPForLevel(newLevel);
      newLevel++;
    }

    state = CharacterStats(xp: newXP, level: newLevel);
    _saveStats();

    return newLevel > oldLevel ? newLevel : null;
  }

  void decreaseXP(int daysInactive) {
    if (daysInactive <= 0) return;

    var newXP = state.xp - (daysInactive * 10);
    var newLevel = state.level;

    while (newXP < 0) {
      if (newLevel <= 1) {
        newXP = 0;
        break;
      }
      newLevel--;
      newXP += getRequiredXPForLevel(newLevel);
    }

    state = CharacterStats(xp: newXP, level: newLevel);
    _saveStats();
  }

  int getCurrentLevelXP() => getRequiredXPForLevel(state.level);
}

class CharacterProfilePage extends ConsumerStatefulWidget {
  const CharacterProfilePage({required this.planId, super.key});

  static const String routeName = '/characterProfile';

  final String planId;

  @override
  ConsumerState<CharacterProfilePage> createState() =>
      _CharacterProfilePageState();
}

class _CharacterProfilePageState extends ConsumerState<CharacterProfilePage> {
  final _nameController = TextEditingController();
  bool _isEditingName = false;
  int? _gameLevel;
  SheepPastureGame? _game;

  @override
  void initState() {
    super.initState();
    _loadName();
    _applyDailyPenalty();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _applyDailyPenalty() async {
    final preferences = await SharedPreferences.getInstance();
    if (!mounted) return;

    final lastCheck = preferences.getString(_penaltyCheckPreferenceKey);
    final now = DateTime.now();
    if (lastCheck != null &&
        app_date_utils.DateUtils.isSameDay(DateTime.tryParse(lastCheck), now)) {
      return;
    }

    final planNotifier = ref.read(planProviderFamily(widget.planId).notifier);
    // Without a loaded schedule the deviation is always reported as 0, which
    // would silently skip today's penalty — try again on the next visit
    // instead of marking the day as checked.
    if (planNotifier.schedule == null) return;

    final deviationDays = planNotifier.getDeviationDays();
    if (deviationDays > 0) {
      ref.read(characterStatsProvider.notifier).decreaseXP(deviationDays);
    }

    await preferences.setString(
        _penaltyCheckPreferenceKey, now.toIso8601String());
  }

  Future<void> _loadName() async {
    final preferences = await SharedPreferences.getInstance();
    if (!mounted) return;

    final savedName = preferences.getString(_namePreferenceKey);
    if (savedName != null) {
      setState(() => _nameController.text = savedName);
    }
  }

  Future<void> _saveName(String name) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_namePreferenceKey, name);
  }

  void _onRewardClaimed(int amount, BuildContext context) {
    final newLevel =
        ref.read(characterStatsProvider.notifier).increaseXP(amount);
    if (newLevel != null && context.mounted) {
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => LevelUpDialog(newLevel: newLevel),
      );
    }
  }

  /// The Flame game has to survive rebuilds — recreating it would reload every
  /// sprite and restart the animation whenever the page rebuilds.
  SheepPastureGame _gameForLevel(int level) {
    if (_game == null || _gameLevel != level) {
      _gameLevel = level;
      _game = SheepPastureGame(level: level);
    }

    return _game!;
  }

  @override
  Widget build(BuildContext context) {
    final characterStats = ref.watch(characterStatsProvider);
    final currentLevelXP = getRequiredXPForLevel(characterStats.level);
    final name = _nameController.text.isEmpty
        ? context.loc.profilePageDefaultName
        : _nameController.text;

    return Scaffold(
      appBar: AppBar(title: Text(context.loc.profilePageTitle)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              height: 200,
              child: GameWidget(game: _gameForLevel(characterStats.level)),
            ),
            const SizedBox(height: 40),
            GestureDetector(
              onTap: () => setState(() => _isEditingName = true),
              child: _isEditingName
                  ? TextField(
                      autofocus: true,
                      textAlign: TextAlign.center,
                      controller: _nameController,
                      onSubmitted: (value) async {
                        setState(() => _isEditingName = false);
                        await _saveName(value);
                      },
                      onTapOutside: (_) =>
                          setState(() => _isEditingName = false),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                    )
                  : Text(
                      name,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
            ),
            const SizedBox(height: 20),
            _XpBar(xp: characterStats.xp, requiredXP: currentLevelXP),
            const SizedBox(height: 20),
            Expanded(
              child: AchievementsListWidget(
                planId: widget.planId,
                onRewardClaimed: _onRewardClaimed,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _XpBar extends StatelessWidget {
  const _XpBar({required this.xp, required this.requiredXP});

  final int xp;
  final int requiredXP;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Stack(
      children: [
        Container(
          height: 20,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: colorScheme.primary),
            color: colorScheme.surfaceContainerHighest,
          ),
        ),
        Positioned.fill(
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor:
                  requiredXP <= 0 ? 0.0 : (xp / requiredXP).clamp(0.0, 1.0),
              child: AnimatedContainer(
                duration: const Duration(seconds: 1),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: colorScheme.primary,
                ),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: Center(
            child: Text(
              context.loc.profilePageProgressLabel(xp, requiredXP),
              style: TextStyle(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
