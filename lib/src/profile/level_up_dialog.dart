import 'package:flutter/material.dart';
import 'dart:math' as math;

class LevelUpDialog extends StatefulWidget {
  final int newLevel;

  const LevelUpDialog({
    required this.newLevel,
    Key? key,
  }) : super(key: key);

  @override
  State<LevelUpDialog> createState() => _LevelUpDialogState();
}

class _LevelUpDialogState extends State<LevelUpDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;

  String _getUnlockMessage(int level) {
    if (level == 5 || level == 10) {
      return 'Neuen Avatar erhalten!';
    }
    return '';
  }

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
          color: Colors.white,
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
                              child: Icon(
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
                        child: Icon(
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
                'Level Up!',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
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
                    'Du hast Level ${widget.newLevel} erreicht!',
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.black87,
                    ),
                  ),
                  if (_getUnlockMessage(widget.newLevel).isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      _getUnlockMessage(widget.newLevel),
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.green,
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
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  'Weiter',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
