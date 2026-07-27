import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:jw_daily/src/localization/app_localizations_getter.dart';

class LevelUpDialog extends StatefulWidget {
  final int newLevel;

  const LevelUpDialog({
    required this.newLevel,
    super.key,
  });

  @override
  State<LevelUpDialog> createState() => _LevelUpDialogState();
}

class _LevelUpDialogState extends State<LevelUpDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;

  /// A new avatar becomes available at these levels — see
  /// getSheepImageForLevel.
  bool get _unlocksAvatar => widget.newLevel == 5 || widget.newLevel == 10;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..forward();

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));

    _rotateAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color.fromRGBO(255, 235, 59, 0.3),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animierte Sterne
            SizedBox(
              height: 200,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Hintere rotierende Sterne
                  ...List.generate(8, (index) {
                    return AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        return Transform.rotate(
                          angle: _rotateAnimation.value + (index * math.pi / 4),
                          child: Transform.translate(
                            offset: Offset(
                              math.cos(index * math.pi / 4) * 60,
                              math.sin(index * math.pi / 4) * 60,
                            ),
                            child: Transform.scale(
                              scale: _scaleAnimation.value,
                              child: const Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 24,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }),
                  // Zentraler großer Stern
                  AnimatedBuilder(
                    animation: _scaleAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _scaleAnimation.value,
                        child: const Icon(
                          Icons.star,
                          color: Colors.amber,
                          size: 80,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            ScaleTransition(
              scale: _scaleAnimation,
              child: Text(
                context.loc.levelUpDialogTitle,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                  shadows: [
                    Shadow(
                      color: Color.fromRGBO(33, 150, 243, 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            FadeTransition(
              opacity: _controller,
              child: Column(
                children: [
                  Text(
                    context.loc.levelUpDialogMessage(widget.newLevel),
                    style: TextStyle(
                      fontSize: 18,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  if (_unlocksAvatar) ...[
                    const SizedBox(height: 8),
                    Text(
                      context.loc.levelUpDialogAvatarUnlocked,
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            ScaleTransition(
              scale: _scaleAnimation,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(
                  context.loc.levelUpDialogContinueButton,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
