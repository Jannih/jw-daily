import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nwt_reading/src/profile/achievements_list.dart';
import 'package:nwt_reading/src/profile/level_up_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  return CharacterStatsNotifier();
});

class CharacterStatsNotifier extends StateNotifier<CharacterStats> {
  CharacterStatsNotifier() : super(CharacterStats(xp: 0, level: 1)) {
    _init();
  }

  SharedPreferences? _prefs;

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    final xp = _prefs!.getInt('character_xp') ?? 0;
    final level = _prefs!.getInt('character_level') ?? 1;
    state = CharacterStats(xp: xp, level: level);
  }

  Future<void> _saveStats() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.setInt('character_xp', state.xp);
    await prefs.setInt('character_level', state.level);
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
  String _name = 'Dein Name';
  bool _isEditingName = false;
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: _name);
    _loadName();
    _applyDailyPenalty();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _applyDailyPenalty() async {
    final prefs = await SharedPreferences.getInstance();
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
    
    await prefs.setString('last_penalty_check', now.toIso8601String());
  }

  Future<void> _loadName() async {
    final prefs = await SharedPreferences.getInstance();
    final savedName = prefs.getString('character_name');
    if (savedName != null && mounted) {
      setState(() {
        _name = savedName;
        _nameController.text = savedName;
      });
    }
  }

  Future<void> _saveName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('character_name', name);
  }

  @override
  Widget build(BuildContext context) {
    final characterStats = ref.watch(characterStatsProvider);
    final currentLevelXP = ref.read(characterStatsProvider.notifier).getCurrentLevelXP();

    return Scaffold(
      appBar: AppBar(
        title: Text('Charakter Profil'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              height: 200,
              child: GameWidget(
                game: SheepPastureGame(level: characterStats.level),
              ),
            ),
            SizedBox(height: 40),
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
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                    )
                  : Text(
                      _name,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
            ),
            SizedBox(height: 20),
            Stack(
              children: [
                Container(
                  height: 20,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.blue),
                    color: Colors.blue.shade50,
                  ),
                ),
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: AnimatedContainer(
                      duration: Duration(seconds: 1),
                      width: (characterStats.xp / currentLevelXP) * 
                          MediaQuery.of(context).size.width * 0.9,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Center(
                    child: Text(
                      'Glaubensfortschritt: ${characterStats.xp} / $currentLevelXP',
                      style: TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
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