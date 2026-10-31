// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '带齐了';

  @override
  String get tabChecklists => '清单';

  @override
  String get tabForgot => '遗忘记录';

  @override
  String get tabSettings => '设置';

  @override
  String get homeTitle => '带齐了';

  @override
  String get startPacking => '开始装包';

  @override
  String get myChecklists => '我的清单';

  @override
  String get newChecklist => '＋ 新建清单';

  @override
  String get presetMnemonicTitle => '伸手要钱';

  @override
  String get presetItemsSummary => '身份证 · 手机 · 钥匙 · 钱包';

  @override
  String itemCount(int count) {
    return '$count 件';
  }

  @override
  String highRiskBadge(int count) {
    return '$count 件高危';
  }

  @override
  String packSubtitleRemaining(int count) {
    return '还差 $count 件 · 把东西拖进包里';
  }

  @override
  String get packSubtitleAllPacked => '全部装好了';

  @override
  String get dropZoneHint => '松手放进包里';

  @override
  String highRiskBanner(String items) {
    return '🔴 $items 你以前忘过，先装它们';
  }

  @override
  String get doneTitle => '全部带齐，出门吧！';

  @override
  String doneSubtitle(int packed, int total) {
    return '$packed / $total 件已装包';
  }

  @override
  String streakZeroForgot(int count) {
    return '· 连续 $count 次零遗漏 🔥';
  }

  @override
  String get doorButton => '出门 🚪';

  @override
  String get forgotLink => '还是忘了东西？记一笔';

  @override
  String get forgotTitle => '这次忘了什么？';

  @override
  String get forgotButton => '记下来，下次提醒我';

  @override
  String forgotSuccess(String items) {
    return '已记下，下次 $items 会排在最前面';
  }

  @override
  String incompleteLeaveTitle(int count, String items) {
    return '还有 $count 件没装：$items。确定就这样出门吗？';
  }

  @override
  String get btnStay => '再看看';

  @override
  String get btnDepartAnyway => '就这样出门';

  @override
  String get btnPackLater => '稍后再装';

  @override
  String get actionSkipToday => '今天不带';

  @override
  String get actionRestore => '恢复';

  @override
  String get allSkipped => '今天什么都不带吗？';

  @override
  String get btnDepartDirectly => '直接出门';

  @override
  String get emptyChecklist => '先往清单里加点东西';

  @override
  String get emptyForgotRecords => '还没有忘过东西，继续保持 👍';

  @override
  String get onboardingHint => '试试把钥匙拖进包里';

  @override
  String get onboardingDone => '就是这样！出门前把东西都装进包里';

  @override
  String get onboardingStart => '开始使用';

  @override
  String get back => '‹ 返回';

  @override
  String get edit => '编辑';

  @override
  String get save => '保存';

  @override
  String get delete => '删除';

  @override
  String get duplicate => '复制';

  @override
  String get confirmDeleteChecklistTitle => '删除清单';

  @override
  String get confirmDeleteChecklistContent => '确定要删除此清单吗？清单内的物品将被移除，但遗忘统计仍会保留。';

  @override
  String get cancel => '取消';

  @override
  String get checklistName => '清单名称';

  @override
  String get checklistNameHint => '如：日常通勤（最多12字）';

  @override
  String get checklistIcon => '清单图标';

  @override
  String get itemsList => '物品列表';

  @override
  String get addItemHint => '输入物品名，回车添加';

  @override
  String get mnemonicToggle => '生成口诀条';

  @override
  String get mnemonicLabel => '口诀';

  @override
  String get mnemonicHint => '如：身手钥钱';

  @override
  String get mnemonicRuleTip => '口诀字数必须与物品数量一致才能显示';

  @override
  String get reminderToggle => '定时提醒';

  @override
  String get reminderTime => '提醒时间';

  @override
  String get reminderDays => '重复日';

  @override
  String get weekdays => '工作日';

  @override
  String itemAlreadyExists(String name) {
    return '清单里已经有 $name 了';
  }

  @override
  String get commonItemsTitle => '常用物品快捷添加';

  @override
  String get settingsSound => '声音';

  @override
  String get settingsHaptic => '震动';

  @override
  String get settingsReducedMotion => '减少动效';

  @override
  String get settingsAbout => '关于';

  @override
  String get version => '版本';
}
