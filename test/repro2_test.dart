// ignore_for_file: avoid_print
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/native.dart';
import 'package:daiqi/app/providers.dart';
import 'package:daiqi/app/theme.dart';
import 'package:daiqi/data/database.dart';
import 'package:daiqi/data/repositories/checklist_repository.dart';
import 'package:daiqi/shared/services/audio_service.dart';
import 'package:daiqi/shared/services/haptic_service.dart';
import 'package:daiqi/features/pack/item_card_widget.dart';
import 'package:daiqi/features/pack/pack_screen.dart';
import 'package:daiqi/l10n/app_localizations.dart';

void main() {
  late AppDatabase db; late ProviderContainer c; late String id;
  Future<void> frames(WidgetTester t, [int ms = 600]) async { for (var e=0;e<ms;e+=50){ await t.pump(const Duration(milliseconds:50)); } }
  Future<void> boot(WidgetTester t, {double top = 0}) async {
    AudioService.enabled=false; HapticService.enabled=false;
    db = AppDatabase(NativeDatabase.memory());
    final repo = ChecklistRepository(db);
    await repo.ensurePresetChecklist();
    id = (await repo.watchAllSummaries().first).first.id;
    c = ProviderContainer(overrides:[databaseProvider.overrideWithValue(db)]);
    addTearDown(() async { c.dispose(); await t.pump(); await db.close(); });
    t.view.physicalSize = const Size(400, 850); t.view.devicePixelRatio = 1.0;
    t.view.padding = FakeViewPadding(top: top); t.view.viewPadding = FakeViewPadding(top: top);
    addTearDown(() { t.view.resetPhysicalSize(); t.view.resetPadding(); t.view.resetViewPadding(); });
    await t.pumpWidget(UncontrolledProviderScope(container: c, child: MaterialApp(theme: AppTheme.lightTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: AppLocalizations.supportedLocales,
      home: PackScreen(checklistId: id))));
    await frames(t);
  }

  testWidgets('drag 12pt then hold 700ms', (t) async {
    await boot(t);
    final g = await t.startGesture(t.getCenter(find.text('钥匙')));
    await g.moveBy(const Offset(0, 12)); await t.pump();
    await t.pump(const Duration(milliseconds: 700));
    print('menu shown: ${find.text('今天不带').evaluate().isNotEmpty}');
    final dragged = find.byWidgetPredicate((w) => w is ItemCardWidget && w.isDragged);
    print('floating card present after hold: ${dragged.evaluate().isNotEmpty}');
    await g.up(); await frames(t, 800);
    print('counter 0/4: ${find.text('0 / 4').evaluate().isNotEmpty}');
  });

  testWidgets('flyback end position', (t) async {
    await boot(t, top: 40);
    final slot = t.getRect(find.ancestor(of: find.text('钥匙'), matching: find.byType(SizedBox)).first);
    final g = await t.startGesture(t.getCenter(find.text('钥匙')));
    await g.moveBy(const Offset(0, 15)); await t.pump();
    await g.moveBy(const Offset(-100, 60)); await t.pump();
    await g.up(); await t.pump();
    await t.pump(const Duration(milliseconds: 270));
    final dragged = find.byWidgetPredicate((w) => w is ItemCardWidget && w.isDragged);
    print('slot $slot  overlay near end ${dragged.evaluate().isNotEmpty ? t.getRect(dragged) : "gone"}');
    await frames(t);
  });

  testWidgets('unpack flight end', (t) async {
    await boot(t, top: 40);
    await t.tap(find.text('钥匙')); await frames(t, 900);
    print('after pack: ${find.text('1 / 4').evaluate().isNotEmpty}');
    final slot = t.getRect(find.ancestor(of: find.text('钥匙'), matching: find.byType(SizedBox)).first);
    await t.tap(find.text('钥匙')); await t.pump(); await t.pump(const Duration(milliseconds: 300));
    final dragged = find.byWidgetPredicate((w) => w is ItemCardWidget && w.isDragged);
    print('slot(after unpack) $slot overlay near end ${dragged.evaluate().isNotEmpty ? t.getRect(dragged) : "gone"}');
    await frames(t, 800);
  });
}
