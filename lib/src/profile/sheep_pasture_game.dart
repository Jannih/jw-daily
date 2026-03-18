import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';

class SheepPastureGame extends FlameGame {
  final int level;

  SheepPastureGame({required this.level});

  @override
  Color backgroundColor() => const Color(0xFF4CAF50);

  @override
  Future<void> onLoad() async {
    images.prefix = 'assets/images/';
    await super.onLoad();

    // Lade alle Bilder parallel
    final loadResults = await Future.wait([
      images.load('lands/Tilesets/Grass.png'),
      images.load('sheep/SheepIdle.png'),
      images.load('lands/Objects/Basic_Grass_Biom_things.png'),
      images.load('lands/Objects/Basic_Plants.png'),
      images.load('lands/Objects/Paths.png'),
    ]);
    final grassTileset = loadResults[0];
    final sheepIdleSheet = loadResults[1];
    final thingsSheetImg = loadResults[2];
    final plantsSheetImg = loadResults[3];
    final pathsSheetImg = loadResults[4];

    // 1. Pre-rendered Graslandschaft als einzelnes Bild
    final grassSheet = SpriteSheet(image: grassTileset, srcSize: Vector2.all(16));
    final grassTile = grassSheet.getSprite(6, 0);
    final tileSize = 32.0;

    final tilesX = (size.x / tileSize).ceil();
    final totalWidth = tilesX * tileSize;
    final xOffset = (totalWidth - size.x) / 2;
    final tilesY = (size.y / tileSize).ceil();

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    for (var y = 0; y < tilesY; y++) {
      for (var x = 0; x < tilesX; x++) {
        grassTile.render(
          canvas,
          position: Vector2((x * tileSize) - xOffset, y * tileSize),
          size: Vector2.all(tileSize),
        );
      }
    }
    final picture = recorder.endRecording();
    final grassImage = await picture.toImage(size.x.ceil(), size.y.ceil());

    add(
      SpriteComponent(
        sprite: Sprite(grassImage),
        size: size,
        position: Vector2.zero(),
      )..priority = 0,
    );

    // 2. Animiertes Schaf (immer zentriert, priority 2)
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

    // 3. Sprite Sheets vorbereiten
    final thingsSheet = SpriteSheet(image: thingsSheetImg, srcSize: Vector2.all(16));
    final plantsSheet = SpriteSheet(image: plantsSheetImg, srcSize: Vector2.all(16));
    final pathsSheet = SpriteSheet(image: pathsSheetImg, srcSize: Vector2.all(16));

    // ============================================================
    // LEVEL PROGRESSION: "Leere Weide → Gepflegter Garten → Blühendes Ökosystem"
    // Jedes Level bringt etwas Neues! Keine Dead Zones.
    // ============================================================

    // Level 2-3: Erster kleiner Baumsetzling (links unten)
    if (level == 2 || level == 3) {
      _addSprite(thingsSheet.getSprite(2, 4), size.x * 0.25, size.y - 64, 32, 1);
    }

    // Level 4+: Erster voller Baum (links unten, 2x2)
    if (level >= 4) {
      _addTree(thingsSheet, 0, 1, size.x * 0.25, size.y - 64, tileSize);
    }

    // Level 5: Vordergrund-Grasbüschel (Tiefe erzeugen)
    if (level >= 5) {
      _addSprite(plantsSheet.getSprite(0, 0), size.x * 0.15, size.y - 24, 24, 3);
      _addSprite(plantsSheet.getSprite(0, 1), size.x * 0.85, size.y - 20, 24, 3);
    }

    // Level 6+: Beerenbusch (rechts unten)
    if (level >= 6) {
      _addSprite(thingsSheet.getSprite(3, 0), size.x * 0.95, size.y - 10, 32, 1,
          anchor: Anchor.bottomRight);
    }

    // Level 7: Kleiner Pfad (zeigt: "Das Schaf hat einen Weg getrampelt")
    if (level >= 7) {
      _addSprite(pathsSheet.getSprite(0, 0), size.x * 0.45, size.y * 0.7, 32, 1);
      _addSprite(pathsSheet.getSprite(1, 0), size.x * 0.45 + 32, size.y * 0.7, 32, 1);
    }

    // Level 8-9: Zweiter Baumsetzling (rechts mitte)
    if (level == 8 || level == 9) {
      _addSprite(thingsSheet.getSprite(2, 4), size.x * 0.75, size.y / 2, 32, 1);
    }

    // Level 9: Kleine Pflanze rechts unten (Pilze/Busch)
    if (level >= 9) {
      _addSprite(plantsSheet.getSprite(0, 2), size.x * 0.88, size.y * 0.8, 24, 1);
    }

    // Level 10+: Zweiter voller Baum (rechts mitte, 2x2)
    if (level >= 10) {
      _addTree(thingsSheet, 0, 1, size.x * 0.75, size.y / 2, tileSize);
    }

    // Level 11-13: Dritter Baumsetzling (links oben)
    if (level == 11 || level == 12 || level == 13) {
      _addSprite(thingsSheet.getSprite(2, 4), size.x * 0.1, size.y / 4, 32, 1);
    }

    // Level 13: Kleiner Stein / Deko-Element (Zentrum-rechts)
    if (level >= 13) {
      _addSprite(plantsSheet.getSprite(0, 3), size.x * 0.6, size.y * 0.75, 24, 1);
    }

    // Level 14+: Dritter voller Baum (links oben, 2x2 - anderer Baum-Typ)
    if (level >= 14) {
      _addTree(thingsSheet, 0, 3, size.x * 0.1, size.y / 4, tileSize);
    }

    // Level 15: Blühender Busch (links mitte - Vorbote der Blume)
    if (level >= 15) {
      _addSprite(plantsSheet.getSprite(0, 4), size.x * 0.2, size.y * 0.45, 28, 1);
    }

    // Level 16: Zweiter Blumen-Akzent (rechts oben)
    if (level >= 16) {
      _addSprite(plantsSheet.getSprite(0, 5), size.x * 0.8, size.y * 0.35, 28, 1);
    }

    // Level 17: Mehr Vordergrund-Pflanzen (Weide füllt sich)
    if (level >= 17) {
      _addSprite(plantsSheet.getSprite(0, 0), size.x * 0.55, size.y - 20, 24, 3);
      _addSprite(plantsSheet.getSprite(0, 1), size.x * 0.35, size.y - 28, 20, 3);
    }

    // Level 18+: Blume (Highlight, neben Schaf)
    if (level >= 18) {
      _addSprite(thingsSheet.getSprite(2, 7), size.x / 2 + 40, size.y / 2 + 40, 32, 1,
          anchor: Anchor.bottomRight);
    }

    // Level 20+: Pfad-Erweiterung (die Weide hat einen Rundweg)
    if (level >= 20) {
      _addSprite(pathsSheet.getSprite(0, 1), size.x * 0.45, size.y * 0.7 + 32, 32, 1);
      _addSprite(pathsSheet.getSprite(1, 1), size.x * 0.45 + 32, size.y * 0.7 + 32, 32, 1);
    }
  }

  /// Hilfsmethode: Einzelnes Sprite hinzufügen
  void _addSprite(Sprite sprite, double x, double y, double spriteSize, int priority,
      {Anchor anchor = Anchor.topLeft}) {
    add(
      SpriteComponent(
        sprite: sprite,
        size: Vector2.all(spriteSize),
        position: Vector2(x, y),
        anchor: anchor,
      )..priority = priority,
    );
  }

  /// Hilfsmethode: 2x2 Baum hinzufügen (4 Tiles)
  void _addTree(SpriteSheet sheet, int startRow, int startCol, double x, double y, double tileSize) {
    for (var row = 0; row < 2; row++) {
      for (var col = 0; col < 2; col++) {
        add(
          SpriteComponent(
            sprite: sheet.getSprite(startRow + row, startCol + col),
            size: Vector2.all(tileSize),
            position: Vector2(x + col * tileSize, y + row * tileSize),
          )..priority = 1,
        );
      }
    }
  }
}
