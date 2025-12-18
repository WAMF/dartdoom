import 'dart:typed_data';

import 'package:doom_core/src/render/r_draw.dart';
import 'package:doom_core/src/render/r_state.dart';
import 'package:test/test.dart';

void main() {
  group('DrawerType', () {
    test('has all drawer types', () {
      expect(DrawerType.values, contains(DrawerType.column));
      expect(DrawerType.values, contains(DrawerType.fuzz));
      expect(DrawerType.values, contains(DrawerType.translated));
      expect(DrawerType.values, contains(DrawerType.span));
    });
  });

  group('ColumnDrawer', () {
    late ColumnDrawer drawer;
    late Uint8List dest;
    late Int32List yLookup;
    late Int32List columnOfs;

    setUp(() {
      drawer = ColumnDrawer();
      dest = Uint8List(ScreenDimensions.width * ScreenDimensions.height);
      yLookup = Int32List(ScreenDimensions.height);
      columnOfs = Int32List(ScreenDimensions.width);

      for (var i = 0; i < ScreenDimensions.height; i++) {
        yLookup[i] = i * ScreenDimensions.width;
      }
      for (var i = 0; i < ScreenDimensions.width; i++) {
        columnOfs[i] = i;
      }

      drawer
        ..yLookup = yLookup
        ..columnOfs = columnOfs;
    });

    test('has default values', () {
      final d = ColumnDrawer();
      expect(d.x, 0);
      expect(d.yl, 0);
      expect(d.yh, 0);
      expect(d.iscale, 0);
      expect(d.textureMid, 0);
    });

    test('draw does nothing when count is negative', () {
      drawer
        ..x = 0
        ..yl = 10
        ..yh = 5
        ..source = Uint8List(128)
        ..colormap = Uint8List(256);

      final destCopy = Uint8List.fromList(dest);
      drawer.draw(dest);

      expect(dest, destCopy);
    });

    test('draw writes pixels when count is non-negative', () {
      drawer
        ..x = 10
        ..yl = 50
        ..yh = 55
        ..iscale = 65536
        ..textureMid = 0
        ..source = Uint8List.fromList(List.generate(128, (i) => i))
        ..colormap = Uint8List.fromList(List.generate(256, (i) => i));

      drawer.draw(dest);

      for (var y = 50; y <= 55; y++) {
        final index = yLookup[y] + columnOfs[10];
        expect(dest[index], isNot(0));
      }
    });

    test('drawLow doubles pixels horizontally', () {
      drawer
        ..x = 5
        ..yl = 50
        ..yh = 52
        ..iscale = 65536
        ..textureMid = 0
        ..source = Uint8List.fromList(List.generate(128, (i) => 100))
        ..colormap = Uint8List.fromList(List.generate(256, (i) => i));

      drawer.drawLow(dest);

      for (var y = 50; y <= 52; y++) {
        final index = yLookup[y] + columnOfs[10];
        expect(dest[index], dest[index + 1]);
      }
    });
  });

  group('FuzzColumnDrawer', () {
    late FuzzColumnDrawer drawer;
    late Uint8List dest;
    late Int32List yLookup;
    late Int32List columnOfs;

    setUp(() {
      drawer = FuzzColumnDrawer();
      dest = Uint8List(ScreenDimensions.width * ScreenDimensions.height);
      yLookup = Int32List(ScreenDimensions.height);
      columnOfs = Int32List(ScreenDimensions.width);

      for (var i = 0; i < ScreenDimensions.height; i++) {
        yLookup[i] = i * ScreenDimensions.width;
      }
      for (var i = 0; i < ScreenDimensions.width; i++) {
        columnOfs[i] = i;
      }

      drawer
        ..yLookup = yLookup
        ..columnOfs = columnOfs;
    });

    test('has default values', () {
      final d = FuzzColumnDrawer();
      expect(d.x, 0);
      expect(d.yl, 0);
      expect(d.yh, 0);
      expect(d.fuzzPos, 0);
    });

    test('draw does nothing when count is negative', () {
      drawer
        ..x = 0
        ..yl = 10
        ..yh = 5
        ..colormap = Uint8List(256 * 34);

      final destCopy = Uint8List.fromList(dest);
      drawer.draw(dest);

      expect(dest, destCopy);
    });

    test('fuzzPos advances after draw', () {
      drawer
        ..x = 10
        ..yl = 50
        ..yh = 55
        ..colormap = Uint8List(256 * 34);

      dest.fillRange(0, dest.length, 100);

      final initialFuzzPos = drawer.fuzzPos;
      drawer.draw(dest);

      expect(drawer.fuzzPos, isNot(initialFuzzPos));
    });

    test('clamps yl to 1 when at top edge', () {
      drawer
        ..x = 10
        ..yl = 0
        ..yh = 5
        ..colormap = Uint8List(256 * 34);

      dest.fillRange(0, dest.length, 100);
      drawer.draw(dest);
    });

    test('clamps yh when at bottom edge', () {
      drawer
        ..x = 10
        ..yl = ScreenDimensions.viewHeight - 5
        ..yh = ScreenDimensions.viewHeight - 1
        ..colormap = Uint8List(256 * 34);

      dest.fillRange(0, dest.length, 100);
      drawer.draw(dest);
    });
  });

  group('TranslatedColumnDrawer', () {
    test('has default values', () {
      final drawer = TranslatedColumnDrawer();

      expect(drawer.x, 0);
      expect(drawer.yl, 0);
      expect(drawer.yh, 0);
      expect(drawer.translation, isNull);
    });

    test('draw does nothing when count is negative', () {
      final drawer = TranslatedColumnDrawer();
      final dest = Uint8List(ScreenDimensions.width * ScreenDimensions.height);
      final yLookup = Int32List(ScreenDimensions.height);
      final columnOfs = Int32List(ScreenDimensions.width);

      for (var i = 0; i < ScreenDimensions.height; i++) {
        yLookup[i] = i * ScreenDimensions.width;
      }
      for (var i = 0; i < ScreenDimensions.width; i++) {
        columnOfs[i] = i;
      }

      drawer
        ..yLookup = yLookup
        ..columnOfs = columnOfs
        ..x = 0
        ..yl = 10
        ..yh = 5
        ..source = Uint8List(128)
        ..colormap = Uint8List(256)
        ..translation = Uint8List(256);

      final destCopy = Uint8List.fromList(dest);
      drawer.draw(dest);

      expect(dest, destCopy);
    });
  });

  group('SpanDrawer', () {
    late SpanDrawer drawer;
    late Uint8List dest;
    late Int32List yLookup;
    late Int32List columnOfs;

    setUp(() {
      drawer = SpanDrawer();
      dest = Uint8List(ScreenDimensions.width * ScreenDimensions.height);
      yLookup = Int32List(ScreenDimensions.height);
      columnOfs = Int32List(ScreenDimensions.width);

      for (var i = 0; i < ScreenDimensions.height; i++) {
        yLookup[i] = i * ScreenDimensions.width;
      }
      for (var i = 0; i < ScreenDimensions.width; i++) {
        columnOfs[i] = i;
      }

      drawer
        ..yLookup = yLookup
        ..columnOfs = columnOfs;
    });

    test('has default values', () {
      final d = SpanDrawer();
      expect(d.y, 0);
      expect(d.x1, 0);
      expect(d.x2, 0);
      expect(d.xFrac, 0);
      expect(d.yFrac, 0);
      expect(d.xStep, 0);
      expect(d.yStep, 0);
    });

    test('draw does nothing when count is negative', () {
      drawer
        ..y = 50
        ..x1 = 100
        ..x2 = 50
        ..source = Uint8List(64 * 64)
        ..colormap = Uint8List(256);

      final destCopy = Uint8List.fromList(dest);
      drawer.draw(dest);

      expect(dest, destCopy);
    });

    test('draw writes horizontal span', () {
      drawer
        ..y = 50
        ..x1 = 10
        ..x2 = 20
        ..xFrac = 0
        ..yFrac = 0
        ..xStep = 65536
        ..yStep = 0
        ..source = Uint8List.fromList(List.generate(64 * 64, (i) => 50))
        ..colormap = Uint8List.fromList(List.generate(256, (i) => i));

      drawer.draw(dest);

      final baseIndex = yLookup[50];
      for (var x = 10; x <= 20; x++) {
        expect(dest[baseIndex + x], 50);
      }
    });

    test('drawLow doubles pixels horizontally', () {
      drawer
        ..y = 50
        ..x1 = 10
        ..x2 = 15
        ..xFrac = 0
        ..yFrac = 0
        ..xStep = 65536
        ..yStep = 0
        ..source = Uint8List.fromList(List.generate(64 * 64, (i) => 75))
        ..colormap = Uint8List.fromList(List.generate(256, (i) => i));

      drawer.drawLow(dest);

      final baseIndex = yLookup[50];
      for (var x = 10; x <= 15; x++) {
        final index = baseIndex + x * 2;
        expect(dest[index], dest[index + 1]);
      }
    });
  });

  group('DrawContext', () {
    late DrawContext context;
    late Int32List yLookup;
    late Int32List columnOfs;

    setUp(() {
      context = DrawContext();
      yLookup = Int32List(ScreenDimensions.height);
      columnOfs = Int32List(ScreenDimensions.width);

      for (var i = 0; i < ScreenDimensions.height; i++) {
        yLookup[i] = i * ScreenDimensions.width;
      }
      for (var i = 0; i < ScreenDimensions.width; i++) {
        columnOfs[i] = i;
      }
    });

    test('has all drawer instances', () {
      expect(context.column, isA<ColumnDrawer>());
      expect(context.fuzz, isA<FuzzColumnDrawer>());
      expect(context.translated, isA<TranslatedColumnDrawer>());
      expect(context.span, isA<SpanDrawer>());
    });

    test('has default drawer functions', () {
      expect(context.columnFunc, DrawerType.column);
      expect(context.baseColumnFunc, DrawerType.column);
      expect(context.spanFunc, DrawerType.span);
    });

    test('setLookups configures all drawers', () {
      context.setLookups(yLookup, columnOfs, ScreenDimensions.centerY, ScreenDimensions.viewHeight);

      expect(context.column.yLookup, yLookup);
      expect(context.column.columnOfs, columnOfs);
      expect(context.column.centerY, ScreenDimensions.centerY);
      expect(context.fuzz.yLookup, yLookup);
      expect(context.fuzz.columnOfs, columnOfs);
      expect(context.fuzz.viewHeight, ScreenDimensions.viewHeight);
      expect(context.translated.yLookup, yLookup);
      expect(context.translated.columnOfs, columnOfs);
      expect(context.translated.centerY, ScreenDimensions.centerY);
      expect(context.span.yLookup, yLookup);
      expect(context.span.columnOfs, columnOfs);
    });

    test('drawColumn uses columnFunc to select drawer', () {
      context.setLookups(yLookup, columnOfs, ScreenDimensions.centerY, ScreenDimensions.viewHeight);
      final dest = Uint8List(ScreenDimensions.width * ScreenDimensions.height);

      context.column
        ..x = 10
        ..yl = 50
        ..yh = 55
        ..iscale = 65536
        ..textureMid = 0
        ..source = Uint8List.fromList(List.generate(128, (i) => i))
        ..colormap = Uint8List.fromList(List.generate(256, (i) => i));

      context.columnFunc = DrawerType.column;
      context.drawColumn(dest);
    });

    test('drawColumn does nothing for span type', () {
      context.setLookups(yLookup, columnOfs, ScreenDimensions.centerY, ScreenDimensions.viewHeight);
      final dest = Uint8List(ScreenDimensions.width * ScreenDimensions.height);
      final destCopy = Uint8List.fromList(dest);

      context.columnFunc = DrawerType.span;
      context.drawColumn(dest);

      expect(dest, destCopy);
    });

    test('drawSpan draws span', () {
      context.setLookups(yLookup, columnOfs, ScreenDimensions.centerY, ScreenDimensions.viewHeight);
      final dest = Uint8List(ScreenDimensions.width * ScreenDimensions.height);

      context.span
        ..y = 50
        ..x1 = 10
        ..x2 = 20
        ..xFrac = 0
        ..yFrac = 0
        ..xStep = 65536
        ..yStep = 0
        ..source = Uint8List.fromList(List.generate(64 * 64, (i) => 50))
        ..colormap = Uint8List.fromList(List.generate(256, (i) => i));

      context.drawSpan(dest);

      final baseIndex = yLookup[50];
      expect(dest[baseIndex + 15], 50);
    });
  });
}
