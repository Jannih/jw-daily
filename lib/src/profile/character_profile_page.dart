import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nwt_reading/src/profile/achievements_list.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    _loadStats();
  }

  Future<void> _loadStats() async {
    final prefs = await SharedPreferences.getInstance();
    final xp = prefs.getInt('character_xp') ?? 0;
    final level = prefs.getInt('character_level') ?? 1;
    state = CharacterStats(xp: xp, level: level);
  }

  Future<void> _saveStats() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('character_xp', state.xp);
    await prefs.setInt('character_level', state.level);
  }

  void increaseXP(int amount) {
    int newXP = state.xp + amount;
    int newLevel = state.level;
    
    while (newXP >= 100) {
      newXP -= 100;
      newLevel++;
    }

    state = CharacterStats(xp: newXP, level: newLevel);
    _saveStats();
  }
}

class CharacterProfilePage extends ConsumerStatefulWidget {
  static const String routeName = '/characterProfile';

  final String planId;

  const CharacterProfilePage({
    required this.planId,
    Key? key,
  }) : super(key: key);

  @override
  ConsumerState<CharacterProfilePage> createState() => _CharacterProfilePageState(); 
}

class _CharacterProfilePageState extends ConsumerState<CharacterProfilePage> {
  String _name = 'Dein Name';
  bool _isEditingName = false;

    @override
  void initState() {
    super.initState();
    _loadName();
  }

  Future<void> _loadName() async {
    final prefs = await SharedPreferences.getInstance();
    final savedName = prefs.getString('character_name');
    if (savedName != null) {
      setState(() {
        _name = savedName;
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

    return Scaffold(
      appBar: AppBar(
        title: Text('Charakter Profil'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Stack(
              children: [
                CircleAvatar(
                  backgroundImage: AssetImage('assets/images/sheep.jpg'),
                  radius: 50,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.blue, width: 2),
                    ),
                    child: Text(
                      '${characterStats.level}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
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
                      controller: TextEditingController(text: _name),
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
                      width: (characterStats.xp / 100) * MediaQuery.of(context).size.width,
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
                      'XP: ${characterStats.xp} / 100',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            offset: Offset(1, 1),
                            blurRadius: 2,
                            color: Color.fromRGBO(0, 0, 0, 0.5),
                          ),
                        ],
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
                onRewardClaimed: (amount) {
                  ref.read(characterStatsProvider.notifier).increaseXP(amount);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}