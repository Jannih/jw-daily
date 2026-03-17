import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nwt_reading/src/base/repositories/shared_preferences_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nwt_reading/src/localization/app_localizations_getter.dart';
import 'package:nwt_reading/src/profile/achievements_list.dart';
import 'package:nwt_reading/src/profile/level_up_dialog.dart';
import 'package:nwt_reading/src/profile/profile_utils.dart';
import 'package:nwt_reading/src/plans/entities/plan.dart';
import 'package:flame/game.dart';
import 'sheep_pasture_game.dart';

// Datenklasse für Character Stats
class CharacterStats {
  final int xp;
  final int level;

  CharacterStats({
    required this.xp,
    required this.level,
  });
}

// Provider für Character Stats
final characterStatsProvider = StateNotifierProvider<CharacterStatsNotifier, CharacterStats>((ref) {
  final prefs = ref.watch(sharedPreferencesRepositoryProvider);
  return CharacterStatsNotifier(prefs);
});

class CharacterStatsNotifier extends StateNotifier<CharacterStats> {
  CharacterStatsNotifier(this._prefs) : super(CharacterStats(xp: 0, level: 1)) {
    _init();
  }

  final SharedPreferences _prefs;

  void _init() {
    final xp = _prefs.getInt('character_xp') ?? 0;
    final level = _prefs.getInt('character_level') ?? 1;
    state = CharacterStats(xp: xp, level: level);
  }

  Future<void> _saveStats() async {
    await _prefs.setInt('character_xp', state.xp);
    await _prefs.setInt('character_level', state.level);
  }

  Future<void> increaseXP(int amount, BuildContext context) async {
    final oldLevel = state.level;
    var newXP = state.xp + amount;
    var newLevel = state.level;

    while (newXP >= getRequiredXPForLevel(newLevel)) {
      newXP -= getRequiredXPForLevel(newLevel);
      newLevel++;
    }

    state = CharacterStats(xp: newXP, level: newLevel);
    await _saveStats();

    if (newLevel > oldLevel && context.mounted) {
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => LevelUpDialog(newLevel: newLevel),
      );
    }
  }

  Future<void> decreaseXP(int daysInactive) async {
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
    await _saveStats();
  }

  int getCurrentLevelXP() {
    return getRequiredXPForLevel(state.level);
  }
}

class CharacterProfilePage extends ConsumerStatefulWidget {
  static const String routeName = '/characterProfile';

  final String planId;

  const CharacterProfilePage({
    required this.planId,
    super.key,
  });

  @override
  ConsumerState<CharacterProfilePage> createState() => _CharacterProfilePageState(); 
}

class _CharacterProfilePageState extends ConsumerState<CharacterProfilePage> {
  late String _name;
  bool _isEditingName = false;
  late final TextEditingController _nameController;
  SheepPastureGame? _game;
  int _gameLevel = 1;

  @override
  void initState() {
    super.initState();
    final prefs = ref.read(sharedPreferencesRepositoryProvider);
    _name = prefs.getString('character_name') ?? '';
    _nameController = TextEditingController(text: _name);
    _applyDailyPenalty();
  }

  @override
  void dispose() {
    _game?.onRemove();
    _nameController.dispose();
    super.dispose();
  }

  void _applyDailyPenalty() {
    final prefs = ref.read(sharedPreferencesRepositoryProvider);
    final lastCheckString = prefs.getString('last_penalty_check');
    final now = DateTime.now();

    if (lastCheckString != null) {
      final lastCheck = DateTime.parse(lastCheckString);
      if (DateUtils.isSameDay(lastCheck, now)) {
        return;
      }
    }

    final planNotifier = ref.read(planProviderFamily(widget.planId).notifier);
    final deviationDays = planNotifier.getDeviationDays();

    if (deviationDays < 0) {
      ref.read(characterStatsProvider.notifier).decreaseXP(deviationDays.abs());
    }

    prefs.setString('last_penalty_check', now.toIso8601String());
  }

  Future<void> _saveName(String name) async {
    final prefs = ref.read(sharedPreferencesRepositoryProvider);
    await prefs.setString('character_name', name);
  }

  @override
  Widget build(BuildContext context) {
    final characterStats = ref.watch(characterStatsProvider);
    final currentLevelXP = ref.read(characterStatsProvider.notifier).getCurrentLevelXP();
    final theme = Theme.of(context);
    final xpFraction = currentLevelXP > 0
        ? (characterStats.xp / currentLevelXP).clamp(0.0, 1.0)
        : 0.0;

    // Nur neues Game erstellen wenn sich das Level ändert
    if (_game == null || _gameLevel != characterStats.level) {
      _game?.onRemove();
      _gameLevel = characterStats.level;
      _game = SheepPastureGame(level: characterStats.level);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(context.loc.characterProfileTitle),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              height: 200,
              child: GameWidget(game: _game!),
            ),
            const SizedBox(height: 24),
            // Level Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Level ${characterStats.level}',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Name mit Edit-Hint
            GestureDetector(
              onTap: () {
                setState(() {
                  _isEditingName = true;
                });
              },
              child: _isEditingName
                  ? TextField(
                      autofocus: true,
                      textAlign: TextAlign.center,
                      controller: _nameController,
                      onSubmitted: (value) async {
                        setState(() {
                          _name = value;
                          _isEditingName = false;
                        });
                        await _saveName(value);
                      },
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _name.isEmpty ? context.loc.characterProfileDefaultName : _name,
                          style: theme.textTheme.headlineSmall,
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.edit,
                          size: 18,
                          color: theme.colorScheme.outline,
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 20),
            // XP Progress Bar - mit LayoutBuilder für sichere Breite
            LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: [
                    Container(
                      height: 20,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: theme.colorScheme.primary),
                        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(seconds: 1),
                      height: 20,
                      width: xpFraction * constraints.maxWidth,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    SizedBox(
                      height: 20,
                      child: Center(
                        child: Text(
                          '${characterStats.xp} / $currentLevelXP XP',
                          style: TextStyle(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            Expanded(
              child: AchievementsListWidget(
                planId: widget.planId,
                onRewardClaimed: (amount, context) {
                  ref.read(characterStatsProvider.notifier)
                      .increaseXP(amount, context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}