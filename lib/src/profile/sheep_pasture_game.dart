import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';

class SheepPastureGame extends FlameGame {
  final int level;

  SheepPastureGame({required this.level});

  @override
  Future<void> onLoad() async {
    images.prefix = 'assets/images/';
    await super.onLoad();

    // 1. Pixel-perfekte, lückenlose Graslandschaft
    final grassTileset = await images.load('lands/Tilesets/Grass.png');
    final grassSheet = SpriteSheet(image: grassTileset, srcSize: Vector2.all(16));
    final grassTile = grassSheet.getSprite(6, 0);
    final tileSize = 32.0;

    // Berechne Kacheln, um Breite zu überschreiten (ceil)
    final tilesX = (size.x / tileSize).ceil();
    // Berechne die resultierende Gesamtbreite
    final totalWidth = tilesX * tileSize;
    // Zentriere die überdimensionierte Fläche, indem du sie links verschiebst
    final xOffset = (totalWidth - size.x) / 2;

    final tilesY = (size.y / tileSize).ceil();

    for (var y = 0; y < tilesY; y++) {
      for (var x = 0; x < tilesX; x++) {
        add(
          SpriteComponent(
            sprite: grassTile,
            size: Vector2.all(tileSize),
            position: Vector2((x * tileSize) - xOffset, y * tileSize),
          )..priority = 0,
        );
      }
    }

    // 2. Animiertes Schaf (deine funktionierende Implementierung)
    final sheepIdleSheet = await images.load('sheep/SheepIdle.png');
    final sheepAnimation = SpriteAnimation.fromFrameData(
      sheepIdleSheet,
      SpriteAnimationData.sequenced(
        amount: 19,
        stepTime: 0.15,
        textureSize: Vector2(64, 64),
      ),
    );

    final sheep = SpriteAnimationComponent(
      animation: sheepAnimation,
      size: Vector2.all(64),
      anchor: Anchor.center,
      position: Vector2(size.x / 2, size.y / 2),
    )..priority = 2;
    add(sheep);

    // 3. Dekorative Elemente aus "Basic_Grass_Biom_things.png"
    final thingsSheetImg = await images.load('lands/Objects/Basic_Grass_Biom_things.png');
    final thingsSheet = SpriteSheet(image: thingsSheetImg, srcSize: Vector2.all(16));

    // Ab Level 2 erscheinen verschiedene Dekorationen zum Testen
    if (level == 2 || level == 3) {
      // Der große Baum (2x2 Kacheln) bestehend aus 4 einzelnen Tiles
      final treeX = size.x * 0.25;
      final treeY = size.y - 64; // Platz für 2 Reihen

      // Der Baumstumpf
      final treeStart = SpriteComponent(
        sprite: thingsSheet.getSprite(2, 4),
        size: Vector2.all(32),
        position: Vector2(treeX, treeY),
      )..priority = 1;
      add(treeStart);
    }

    if (level >= 4) {
      final tileSize = 32.0;
      final treeX = size.x * 0.25;
      final treeY = size.y - 64; // Platz für 2 Reihen

            // Obere linke Ecke (0,1)
      add(SpriteComponent(
        sprite: thingsSheet.getSprite(0, 1),
        size: Vector2.all(tileSize),
        position: Vector2(treeX, treeY),
      )..priority = 1);

      // Obere rechte Ecke (1,1)
      add(SpriteComponent(
        sprite: thingsSheet.getSprite(0, 2),
        size: Vector2.all(tileSize),
        position: Vector2(treeX + tileSize, treeY),
      )..priority = 1);

      // Untere linke Ecke (0,2)
      add(SpriteComponent(
        sprite: thingsSheet.getSprite(1, 1),
        size: Vector2.all(tileSize),
        position: Vector2(treeX, treeY + tileSize),
      )..priority = 1);

      // Untere rechte Ecke (1,2)
      add(SpriteComponent(
        sprite: thingsSheet.getSprite(1, 2),
        size: Vector2.all(tileSize),
        position: Vector2(treeX + tileSize, treeY + tileSize),
      )..priority = 1);
    }

    if (level >= 6) {
      // Der Früchtebusch (3,0)
      final berryBush = SpriteComponent(
        sprite: thingsSheet.getSprite(3, 0),
        size: Vector2.all(32),
        anchor: Anchor.bottomRight,
        position: Vector2(size.x * 0.95, size.y - 10),
      )..priority = 1;
      add(berryBush);
    }

    if (level == 8 || level == 9) {
      final tree2X = size.x * 0.75;
      final tree2Y = size.y / 2;
      // Der Baumstumpf
      final treeStart2 = SpriteComponent(
        sprite: thingsSheet.getSprite(2, 4),
        size: Vector2.all(32),
        position: Vector2(tree2X, tree2Y),
      )..priority = 1;
      add(treeStart2);
    }

    if (level >= 10) {
      // Zweiter Baum oben rechts (2x2 Kacheln)
      final tree2X = size.x * 0.75;
      final tree2Y = size.y / 2;

      // Obere linke Ecke (0,1)
      add(SpriteComponent(
        sprite: thingsSheet.getSprite(0, 1),
        size: Vector2.all(tileSize),
        position: Vector2(tree2X, tree2Y),
      )..priority = 1);

      // Obere rechte Ecke (0,2)
      add(SpriteComponent(
        sprite: thingsSheet.getSprite(0, 2),
        size: Vector2.all(tileSize),
        position: Vector2(tree2X + tileSize, tree2Y),
      )..priority = 1);

      // Untere linke Ecke (1,1)
      add(SpriteComponent(
        sprite: thingsSheet.getSprite(1, 1),
        size: Vector2.all(tileSize),
        position: Vector2(tree2X, tree2Y + tileSize),
      )..priority = 1);

      // Untere rechte Ecke (1,2)
      add(SpriteComponent(
        sprite: thingsSheet.getSprite(1, 2),
        size: Vector2.all(tileSize),
        position: Vector2(tree2X + tileSize, tree2Y + tileSize),
      )..priority = 1);
    }

    if (level == 11 || level == 12 || level == 13) {
      final tree3X = size.x * 0.1;
      final tree3Y = size.y / 4;
      // Der Baumstumpf
      final treeStart3 = SpriteComponent(
        sprite: thingsSheet.getSprite(2, 4),
        size: Vector2.all(32),
        position: Vector2(tree3X, tree3Y),
      )..priority = 1;
      add(treeStart3);
    }

    if (level >= 14) {
      // Dritter Baum oben links (2x2 Kacheln)
      final tree3X = size.x * 0.1;
      final tree3Y = size.y / 4;

      // Obere linke Ecke (0,1)
      add(SpriteComponent(
        sprite: thingsSheet.getSprite(0, 3),
        size: Vector2.all(tileSize),
        position: Vector2(tree3X, tree3Y),
      )..priority = 1);

      // Obere rechte Ecke (0,2)
      add(SpriteComponent(
        sprite: thingsSheet.getSprite(0, 4),
        size: Vector2.all(tileSize),
        position: Vector2(tree3X + tileSize, tree3Y),
      )..priority = 1);

      // Untere linke Ecke (1,1)
      add(SpriteComponent(
        sprite: thingsSheet.getSprite(1, 3),
        size: Vector2.all(tileSize),
        position: Vector2(tree3X, tree3Y + tileSize),
      )..priority = 1);

      // Untere rechte Ecke (1,2)
      add(SpriteComponent(
        sprite: thingsSheet.getSprite(1, 4),
        size: Vector2.all(tileSize),
        position: Vector2(tree3X + tileSize, tree3Y + tileSize),
      )..priority = 1);
    }

    if (level >= 18) {
      // Der Früchtebusch (3,0)
      final flower = SpriteComponent(
        sprite: thingsSheet.getSprite(2, 7),
        size: Vector2.all(32),
        anchor: Anchor.bottomRight,
        position: Vector2(size.x / 2 + 40, size.y / 2 + 40),
      )..priority = 1;
      add(flower);
    }
  }
} 