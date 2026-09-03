import 'package:flutter/material.dart';

import '../services/level_progress_service.dart';
import 'arrow_game_screen.dart';

class LevelSelectionScreen extends StatefulWidget {
  const LevelSelectionScreen({super.key});

  @override
  State<LevelSelectionScreen> createState() => _LevelSelectionScreenState();
}

class _LevelSelectionScreenState extends State<LevelSelectionScreen> {
  static const int totalLevels = 1000;
  int _unlocked = 1;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final unlocked = await LevelProgressService.instance.unlockedLevel();
    if (!mounted) return;
    setState(() {
      _unlocked = unlocked.clamp(1, totalLevels);
      _loading = false;
    });
  }

  String _difficulty(int level) {
    if (level <= 25) return 'EASY';
    if (level <= 100) return 'MEDIUM';
    if (level <= 500) return 'HARD';
    return 'EXTREME';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Levels')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text('Choose a level', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      ),
                      Text('$_unlocked / $totalLevels unlocked'),
                    ],
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(14),
                    itemCount: totalLevels,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 0.9,
                    ),
                    itemBuilder: (context, index) {
                      final level = index + 1;
                      final unlocked = level <= _unlocked;
                      final difficulty = _difficulty(level);
                      return FutureBuilder<bool>(
                        future: LevelProgressService.instance.isCompleted(level),
                        builder: (context, snapshot) {
                          final completed = snapshot.data ?? false;
                          return InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: unlocked
                                ? () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => ArrowGameScreen(level: level)),
                                    );
                                    _loadProgress();
                                  }
                                : null,
                            child: Container(
                              decoration: BoxDecoration(
                                color: unlocked ? Colors.white : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: unlocked ? Colors.blue.shade100 : Colors.black12),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(unlocked ? (completed ? Icons.check_circle : Icons.play_circle_fill) : Icons.lock,
                                      color: unlocked ? Colors.blue : Colors.grey, size: 28),
                                  const SizedBox(height: 5),
                                  Text('$level', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                                  const SizedBox(height: 3),
                                  Text(difficulty, style: TextStyle(fontSize: 9, color: Colors.grey.shade700)),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
