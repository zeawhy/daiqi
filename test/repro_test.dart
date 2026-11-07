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
    t.view.padding = FakeViewPadding(top: top);
    t.view.viewPadding = FakeViewPadding(top: top);
    addTearDown(() { t.view.resetPhysicalSize(); t.view.resetPadding(); t.view.resetViewPadding(); });
    await t.pumpWidget(UncontrolledProviderScope(container: c, child: MaterialApp(theme: AppTheme.lightTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: AppLocalizations.supportedLocales,
      home: PackScreen(checklistId: id))));
    await frames(t);
  }

  testWidgets('P0#1 longPress then release', (t) async {
    await boot(t);
    expect(find.text('0 / 4'), findsOneWidget);
    await t.longPress(find.text('钥匙'));
    await frames(t, 800);
    print('menu shown: ${find.text('今天不带').evaluate().isNotEmpty}');
    print('counter 0/4: ${find.text('0 / 4').evaluate().isNotEmpty}  1/4: ${find.text('1 / 4').evaluate().isNotEmpty}');
  });

  testWidgets('P0#2 drag coords with status bar 40', (t) async {
    await boot(t, top: 40);
    final slotRect = t.getRect(find.ancestor(of: find.text('钥匙'), matching: find.byType(SizedBox)).first);
    final start = t.getCenter(find.text('钥匙'));
    print('slot rect $slotRect center-of-text $start');
    final g = await t.startGesture(start);
    await g.moveBy(const Offset(0, 15)); await t.pump();
    await g.moveBy(const Offset(0, 60)); await t.pump();
    final pointer = start + const Offset(0, 75);
    final dragged = find.byWidgetPredicate((w) => w is ItemCardWidget && w.isDragged);
    final r = t.getRect(dragged);
    print('pointer $pointer floating rect $r center ${r.center} delta ${r.center - pointer}');
    // release outside dropzone -> fly back; sample end position
    await g.up(); await t.pump();
    await t.pump(const Duration(milliseconds: 20));
    var r1 = t.getRect(dragged);
    print('flyback t=20ms rect $r1');
    await t.pump(const Duration(milliseconds: 400));
    print('after flyback overlay present: ${dragged.evaluate().isNotEmpty}');
    await frames(t);
  });

  testWidgets('P0#2 click path size', (t) async {
    await boot(t, top: 40);
    final slot = t.getRect(find.ancestor(of: find.text('钥匙'), matching: find.byType(SizedBox)).first);
    print('real slot size ${slot.size} topLeft ${slot.topLeft}');
    await t.tap(find.text('钥匙'));
    await t.pump(); await t.pump(const Duration(milliseconds: 1));
    final dragged = find.byWidgetPredicate((w) => w is ItemCardWidget && w.isDragged);
    final r = t.getRect(dragged);
    print('click-pack t=1ms overlay rect $r (size ${r.size}); expected topLeft ${slot.topLeft}');
    await frames(t, 800);
  });
}
