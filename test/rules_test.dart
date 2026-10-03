import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadow_world/room_game.dart';

void walkTo(RoomGame game, int destination) {
  final path = game.pathTo(destination);
  expect(path, isNotNull, reason: '$destination must be reachable');
  for (final cell in path!) {
    expect(game.adjacent(game.position, cell), isTrue);
    expect(game.passable(cell), isTrue);
    expect(game.move(cell), isTrue);
  }
  expect(game.position, destination);
}

void main() {
  test('walls, closed gate, map edges and nonadjacent moves are blocked', () {
    final game = RoomGame();
    expect(game.pathTo(game.position), isEmpty);
    expect(game.pathTo(36), [36]);
    for (final cell in [-1, 48, ...RoomGame.walls, RoomGame.gate]) {
      expect(game.pathTo(cell), isNull);
      expect(game.move(cell), isFalse);
    }
    expect(game.move(0), isFalse);
    expect(game.adjacent(5, 6), isFalse);
    expect(game.position, 42);
    expect(game.steps, 0);
  });

  test('wrong signal resets progress and records one mistake', () {
    final game = RoomGame();
    walkTo(game, RoomGame.switches[1]);
    expect(game.interact(), contains('重置'));
    expect(game.progress, 0);
    expect(game.mistakes, 1);
    walkTo(game, RoomGame.switches[0]);
    expect(game.interact(), contains('正确'));
    expect(game.progress, 1);
    expect(game.open, isFalse);
  });

  for (var chapter = 0; chapter < 3; chapter++) {
    test('chapter $chapter can solve the signal, collect tokens and exit', () {
      final game = RoomGame(chapter);
      for (final signal in game.code) {
        walkTo(game, RoomGame.switches[signal]);
        game.interact();
      }
      expect(game.open, isTrue);
      expect(game.passable(RoomGame.gate), isTrue);
      for (final token in RoomGame.tokens) {
        if (!game.collected.contains(token)) {
          walkTo(game, token);
        }
      }
      expect(game.collected, RoomGame.tokens.toSet());
      expect(game.won, isFalse);
      walkTo(game, RoomGame.exit);
      expect(game.won, isTrue);
      final steps = game.steps;
      expect(game.move(4), isFalse);
      expect(game.interact(), contains('已完成'));
      expect(game.steps, steps);
      final restored = RoomGame.fromJson(
        jsonDecode(jsonEncode(game.toJson())),
      )!;
      expect(restored.toJson(), game.toJson());
    });
  }

  test(
    'unfinished saves restore, invalid map and victory states are rejected',
    () {
      final game = RoomGame()..move(36);
      final json = game.toJson();
      expect(RoomGame.fromJson(json)!.toJson(), json);
      for (final bad in [
        {...json, 'version': 2},
        {...json, 'chapter': 3},
        {...json, 'position': 7},
        {...json, 'position': RoomGame.gate},
        {...json, 'progress': 3},
        {...json, 'steps': -1},
        {
          ...json,
          'collected': [0],
        },
        {...json, 'won': true},
      ]) {
        expect(RoomGame.fromJson(bad), isNull);
      }
    },
  );
}
