import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('zh')];

  /// No description provided for @appTitle.
  ///
  /// In zh, this message translates to:
  /// **'带齐了'**
  String get appTitle;

  /// No description provided for @tabChecklists.
  ///
  /// In zh, this message translates to:
  /// **'清单'**
  String get tabChecklists;

  /// No description provided for @tabForgot.
  ///
  /// In zh, this message translates to:
  /// **'遗忘记录'**
  String get tabForgot;

  /// No description provided for @tabSettings.
  ///
  /// In zh, this message translates to:
  /// **'设置'**
  String get tabSettings;

  /// No description provided for @homeTitle.
  ///
  /// In zh, this message translates to:
  /// **'带齐了'**
  String get homeTitle;

  /// No description provided for @startPacking.
  ///
  /// In zh, this message translates to:
  /// **'开始装包'**
  String get startPacking;

  /// No description provided for @myChecklists.
  ///
  /// In zh, this message translates to:
  /// **'我的清单'**
  String get myChecklists;

  /// No description provided for @newChecklist.
  ///
  /// In zh, this message translates to:
  /// **'＋ 新建清单'**
  String get newChecklist;

  /// No description provided for @presetMnemonicTitle.
  ///
  /// In zh, this message translates to:
  /// **'伸手要钱'**
  String get presetMnemonicTitle;

  /// No description provided for @presetItemsSummary.
  ///
  /// In zh, this message translates to:
  /// **'身份证 · 手机 · 钥匙 · 钱包'**
  String get presetItemsSummary;

  /// No description provided for @itemCount.
  ///
  /// In zh, this message translates to:
  /// **'{count} 件'**
  String itemCount(int count);

  /// No description provided for @highRiskBadge.
  ///
  /// In zh, this message translates to:
  /// **'{count} 件高危'**
  String highRiskBadge(int count);

  /// No description provided for @packSubtitleRemaining.
  ///
  /// In zh, this message translates to:
  /// **'还差 {count} 件 · 把东西拖进包里'**
  String packSubtitleRemaining(int count);

  /// No description provided for @packSubtitleAllPacked.
  ///
  /// In zh, this message translates to:
  /// **'全部装好了'**
  String get packSubtitleAllPacked;

  /// No description provided for @dropZoneHint.
  ///
  /// In zh, this message translates to:
  /// **'松手放进包里'**
  String get dropZoneHint;

  /// No description provided for @highRiskBanner.
  ///
  /// In zh, this message translates to:
  /// **'🔴 {items} 你以前忘过，先装它们'**
  String highRiskBanner(String items);

  /// No description provided for @doneTitle.
  ///
  /// In zh, this message translates to:
  /// **'全部带齐，出门吧！'**
  String get doneTitle;

  /// No description provided for @doneSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'{packed} / {total} 件已装包'**
  String doneSubtitle(int packed, int total);

  /// No description provided for @streakZeroForgot.
  ///
  /// In zh, this message translates to:
  /// **'· 连续 {count} 次零遗漏 🔥'**
  String streakZeroForgot(int count);

  /// No description provided for @doorButton.
  ///
  /// In zh, this message translates to:
  /// **'出门 🚪'**
  String get doorButton;

  /// No description provided for @forgotLink.
  ///
  /// In zh, this message translates to:
  /// **'还是忘了东西？记一笔'**
  String get forgotLink;

  /// No description provided for @forgotTitle.
  ///
  /// In zh, this message translates to:
  /// **'这次忘了什么？'**
  String get forgotTitle;

  /// No description provided for @forgotButton.
  ///
  /// In zh, this message translates to:
  /// **'记下来，下次提醒我'**
  String get forgotButton;

  /// No description provided for @forgotSuccess.
  ///
  /// In zh, this message translates to:
  /// **'已记下，下次 {items} 会排在最前面'**
  String forgotSuccess(String items);

  /// No description provided for @incompleteLeaveTitle.
  ///
  /// In zh, this message translates to:
  /// **'还有 {count} 件没装：{items}。确定就这样出门吗？'**
  String incompleteLeaveTitle(int count, String items);

  /// No description provided for @btnStay.
  ///
  /// In zh, this message translates to:
  /// **'再看看'**
  String get btnStay;

  /// No description provided for @btnDepartAnyway.
  ///
  /// In zh, this message translates to:
  /// **'就这样出门'**
  String get btnDepartAnyway;

  /// No description provided for @btnPackLater.
  ///
  /// In zh, this message translates to:
  /// **'稍后再装'**
  String get btnPackLater;

  /// No description provided for @actionSkipToday.
  ///
  /// In zh, this message translates to:
  /// **'今天不带'**
  String get actionSkipToday;

  /// No description provided for @actionRestore.
  ///
  /// In zh, this message translates to:
  /// **'恢复'**
  String get actionRestore;

  /// No description provided for @allSkipped.
  ///
  /// In zh, this message translates to:
  /// **'今天什么都不带吗？'**
  String get allSkipped;

  /// No description provided for @btnDepartDirectly.
  ///
  /// In zh, this message translates to:
  /// **'直接出门'**
  String get btnDepartDirectly;

  /// No description provided for @emptyChecklist.
  ///
  /// In zh, this message translates to:
  /// **'先往清单里加点东西'**
  String get emptyChecklist;

  /// No description provided for @emptyForgotRecords.
  ///
  /// In zh, this message translates to:
  /// **'还没有忘过东西，继续保持 👍'**
  String get emptyForgotRecords;

  /// No description provided for @onboardingHint.
  ///
  /// In zh, this message translates to:
  /// **'试试把钥匙拖进包里'**
  String get onboardingHint;

  /// No description provided for @onboardingDone.
  ///
  /// In zh, this message translates to:
  /// **'就是这样！出门前把东西都装进包里'**
  String get onboardingDone;

  /// No description provided for @onboardingStart.
  ///
  /// In zh, this message translates to:
  /// **'开始使用'**
  String get onboardingStart;

  /// No description provided for @back.
  ///
  /// In zh, this message translates to:
  /// **'‹ 返回'**
  String get back;

  /// No description provided for @edit.
  ///
  /// In zh, this message translates to:
  /// **'编辑'**
  String get edit;

  /// No description provided for @save.
  ///
  /// In zh, this message translates to:
  /// **'保存'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In zh, this message translates to:
  /// **'删除'**
  String get delete;

  /// No description provided for @duplicate.
  ///
  /// In zh, this message translates to:
  /// **'复制'**
  String get duplicate;

  /// No description provided for @confirmDeleteChecklistTitle.
  ///
  /// In zh, this message translates to:
  /// **'删除清单'**
  String get confirmDeleteChecklistTitle;

  /// No description provided for @confirmDeleteChecklistContent.
  ///
  /// In zh, this message translates to:
  /// **'确定要删除此清单吗？清单内的物品将被移除，但遗忘统计仍会保留。'**
  String get confirmDeleteChecklistContent;

  /// No description provided for @cancel.
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get cancel;

  /// No description provided for @checklistName.
  ///
  /// In zh, this message translates to:
  /// **'清单名称'**
  String get checklistName;

  /// No description provided for @checklistNameHint.
  ///
  /// In zh, this message translates to:
  /// **'如：日常通勤（最多12字）'**
  String get checklistNameHint;

  /// No description provided for @checklistIcon.
  ///
  /// In zh, this message translates to:
  /// **'清单图标'**
  String get checklistIcon;

  /// No description provided for @itemsList.
  ///
  /// In zh, this message translates to:
  /// **'物品列表'**
  String get itemsList;

  /// No description provided for @addItemHint.
  ///
  /// In zh, this message translates to:
  /// **'输入物品名，回车添加'**
  String get addItemHint;

  /// No description provided for @mnemonicToggle.
  ///
  /// In zh, this message translates to:
  /// **'生成口诀条'**
  String get mnemonicToggle;

  /// No description provided for @mnemonicLabel.
  ///
  /// In zh, this message translates to:
  /// **'口诀'**
  String get mnemonicLabel;

  /// No description provided for @mnemonicHint.
  ///
  /// In zh, this message translates to:
  /// **'如：身手钥钱'**
  String get mnemonicHint;

  /// No description provided for @mnemonicRuleTip.
  ///
  /// In zh, this message translates to:
  /// **'口诀字数必须与物品数量一致才能显示'**
  String get mnemonicRuleTip;

  /// No description provided for @reminderToggle.
  ///
  /// In zh, this message translates to:
  /// **'定时提醒'**
  String get reminderToggle;

  /// No description provided for @reminderTime.
  ///
  /// In zh, this message translates to:
  /// **'提醒时间'**
  String get reminderTime;

  /// No description provided for @reminderDays.
  ///
  /// In zh, this message translates to:
  /// **'重复日'**
  String get reminderDays;

  /// No description provided for @weekdays.
  ///
  /// In zh, this message translates to:
  /// **'工作日'**
  String get weekdays;

  /// No description provided for @itemAlreadyExists.
  ///
  /// In zh, this message translates to:
  /// **'清单里已经有 {name} 了'**
  String itemAlreadyExists(String name);

  /// No description provided for @commonItemsTitle.
  ///
  /// In zh, this message translates to:
  /// **'常用物品快捷添加'**
  String get commonItemsTitle;

  /// No description provided for @settingsSound.
  ///
  /// In zh, this message translates to:
  /// **'声音'**
  String get settingsSound;

  /// No description provided for @settingsHaptic.
  ///
  /// In zh, this message translates to:
  /// **'震动'**
  String get settingsHaptic;

  /// No description provided for @settingsReducedMotion.
  ///
  /// In zh, this message translates to:
  /// **'减少动效'**
  String get settingsReducedMotion;

  /// No description provided for @settingsAbout.
  ///
  /// In zh, this message translates to:
  /// **'关于'**
  String get settingsAbout;

  /// No description provided for @version.
  ///
  /// In zh, this message translates to:
  /// **'版本'**
  String get version;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
