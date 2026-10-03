import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadow_world/main.dart';
import 'package:shadow_world/room_game.dart';
import 'package:shadow_world/frequency/game_support.dart';

Finder cells() => find.descendant(
  of: find.byType(KeyboardBoard),
  matching: find.byType(OutlinedButton),
);

void main() {
  setUp(() {
    saveMap('world.save', {});
    saveMap('results', {});
  });
  testWidgets(
    'Ready waits at the entrance; explicit start enables saved movement',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1440, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
      await tester.pumpWidget(const MyApp());
      await tester.pump();
      expect(find.text('频率密室'), findsOneWidget);
      expect(find.text('进入房间'), findsOneWidget);
      expect(cells(), findsNWidgets(48));
      expect(
        tester
            .widgetList<OutlinedButton>(cells())
            .every((b) => b.onPressed == null),
        isTrue,
      );
      await tester.pump(const Duration(seconds: 2));
      expect(readMap('world.save'), isEmpty);
      expect(find.text('0 秒'), findsOneWidget);
      await tester.tap(find.text('进入房间'));
      await tester.pump();
      expect(find.text('进入房间'), findsNothing);
      expect(find.text('交互 E'), findsOneWidget);
      await tester.tap(find.byTooltip('向上'));
      await tester.pump();
      final game = RoomGame.fromJson(
        objectMap(readMap('world.save')!['game']),
      )!;
      expect(game.position, 36);
      expect(game.steps, 1);
      await tester.tap(find.byTooltip('暂停'));
      await tester.pump();
      final pausedSave = readMap('world.save');
      await tester.pump(const Duration(seconds: 2));
      expect(readMap('world.save'), pausedSave);
      expect(find.text('已暂停'), findsOneWidget);
    },
  );
}
