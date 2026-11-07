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
  testWidgets('scroll swipe starting on card', (t) async {
    AudioService.enabled=false; HapticService.enabled=false;
    final db = AppDatabase(NativeDatabase.memory());
    final repo = ChecklistRepository(db);
    final id = await repo.createChecklist(name:'长', emoji:'📋', items: List.generate(18,(i)=>(name:'物品${i+1}', emoji:'📦')));
    final c = ProviderContainer(overrides:[databaseProvider.overrideWithValue(db)]);
    addTearDown(() async { c.dispose(); await t.pump(); await db.close(); });
    t.view.physicalSize = const Size(400, 850); t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.resetPhysicalSize);
    await t.pumpWidget(UncontrolledProviderScope(container: c, child: MaterialApp(theme: AppTheme.lightTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: AppLocalizations.supportedLocales,
      home: PackScreen(checklistId: id))));
    for (var i=0;i<12;i++){ await t.pump(const Duration(milliseconds:50)); }
    final g = await t.startGesture(t.getCenter(find.text('物品1')));
    await g.moveBy(const Offset(0,-30)); await t.pump(); await g.moveBy(const Offset(0,-60)); await t.pump();
    final dragged = find.byWidgetPredicate((w) => w is ItemCardWidget && w.isDragged);
    final sc = t.state<ScrollableState>(find.byType(Scrollable).first);
    print('scrollOffset=${sc.position.pixels} floatingCardShown=${dragged.evaluate().isNotEmpty}');
    await g.up(); for (var i=0;i<12;i++){ await t.pump(const Duration(milliseconds:50)); }
  });
}
